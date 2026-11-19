import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../ai/assistant.dart';
import '../ai/categorizer.dart';
import '../ai/llm.dart';
import '../data/store.dart';
import '../domain/models.dart';
import '../insights/budgets.dart';
import '../insights/recurring.dart';
import '../platform/services.dart';
import '../services/ingest.dart';
import '../sync/sync_engine.dart';

/// Overridden in main() (and in tests) with the opened store and services.
final storeProvider = Provider<LedgerStore>((ref) => throw UnimplementedError('storeProvider'));
final servicesProvider = Provider<PlatformServices>((ref) => throw UnimplementedError('servicesProvider'));

/// Null unless Supabase is configured with --dart-define.
final syncEngineProvider = Provider<SyncEngine?>((ref) => null);

final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

final txnsProvider = StreamProvider<List<Txn>>((ref) => ref.watch(storeProvider).watchTxns());
final budgetsProvider = StreamProvider<List<Budget>>((ref) => ref.watch(storeProvider).watchBudgets());

// ---------------------------------------------------------------------------
// The on-device model

class ModelStatus {
  const ModelStatus(this.state, {this.progress = 0, this.error});
  final ModelState state;
  final int progress;
  final String? error;
}

class ModelController extends Notifier<ModelStatus> {
  @override
  ModelStatus build() {
    final models = ref.watch(servicesProvider).models;
    if (!models.supported) return const ModelStatus(ModelState.unsupported);
    Future(() async {
      final installed = await models.isInstalled();
      if (state.state == ModelState.notInstalled && installed) state = const ModelStatus(ModelState.ready);
    });
    return const ModelStatus(ModelState.notInstalled);
  }

  Future<void> download({required String url, String? token}) async {
    final models = ref.read(servicesProvider).models;
    state = const ModelStatus(ModelState.downloading);
    try {
      await models.install(
        url: url,
        token: token,
        onProgress: (p) => state = ModelStatus(ModelState.downloading, progress: p),
      );
      state = const ModelStatus(ModelState.ready);
    } catch (e) {
      state = ModelStatus(ModelState.error, error: _friendly(e));
    }
  }

  Future<void> remove() async {
    await ref.read(servicesProvider).models.uninstall();
    state = const ModelStatus(ModelState.notInstalled);
  }

  static String _friendly(Object e) {
    final s = e.toString();
    if (s.contains('401') || s.contains('403')) {
      return 'Hugging Face refused the download. Accept the Gemma licence on the model page and paste a read token.';
    }
    return s.length > 160 ? '${s.substring(0, 160)}…' : s;
  }
}

final modelProvider = NotifierProvider<ModelController, ModelStatus>(ModelController.new);

/// The model when it is ready; otherwise a client that is never ready, so
/// every feature takes its rule-based path.
final llmProvider = Provider<LlmClient>((ref) {
  final ready = ref.watch(modelProvider.select((s) => s.state == ModelState.ready));
  return ready ? ref.watch(servicesProvider).models.llm : const NoLlm();
});

final categorizerProvider = Provider<Categorizer>((ref) {
  final store = ref.watch(storeProvider);
  return Categorizer(llm: ref.watch(llmProvider), memory: store.rememberedCategory);
});

final ingestorProvider = Provider<Ingestor>(
    (ref) => Ingestor(store: ref.watch(storeProvider), categorizer: ref.watch(categorizerProvider)));

final budgetWatcherProvider = Provider<BudgetWatcher>(
    (ref) => BudgetWatcher(store: ref.watch(storeProvider), notifier: ref.watch(servicesProvider).notifier));

final assistantProvider =
    Provider<SpendingAssistant>((ref) => SpendingAssistant(llm: ref.watch(llmProvider), clock: ref.watch(clockProvider)));

// ---------------------------------------------------------------------------
// Derived views

/// The month the Home and Insights tabs look at.
class SelectedMonth extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = ref.watch(clockProvider)();
    return DateTime(now.year, now.month);
  }

  void shift(int months) => state = DateTime(state.year, state.month + months);
}

final selectedMonthProvider = NotifierProvider<SelectedMonth, DateTime>(SelectedMonth.new);

class MonthSummary {
  const MonthSummary({
    required this.month,
    required this.spentPaise,
    required this.incomePaise,
    required this.previousSpentPaise,
    required this.daily,
    required this.previousDaily,
    required this.byCategory,
    required this.txns,
  });
  final DateTime month;
  final int spentPaise;
  final int incomePaise;
  final int previousSpentPaise;

  /// Cumulative spend at the end of each day of the month (paise).
  final List<int> daily;
  final List<int> previousDaily;
  final List<(String, int)> byCategory;
  final List<Txn> txns;
}

MonthSummary summarize(List<Txn> all, DateTime month, DateTime now) {
  List<int> cumulative(DateTime m) {
    final days = DateTime(m.year, m.month + 1, 0).day;
    final perDay = List<int>.filled(days, 0);
    for (final t in all) {
      if (!t.isDebit || t.occurredAt.year != m.year || t.occurredAt.month != m.month) continue;
      perDay[t.occurredAt.day - 1] += t.amountPaise;
    }
    var run = 0;
    final out = [for (final v in perDay) run += v];
    // The current month stops at today.
    if (m.year == now.year && m.month == now.month) return out.sublist(0, now.day);
    return out;
  }

  final inMonth = [
    for (final t in all)
      if (t.occurredAt.year == month.year && t.occurredAt.month == month.month) t
  ];
  final spent = inMonth.where((t) => t.isDebit).fold(0, (s, t) => s + t.amountPaise);
  final income = inMonth.where((t) => !t.isDebit).fold(0, (s, t) => s + t.amountPaise);
  final prev = DateTime(month.year, month.month - 1);
  final cats = spentByCategory(all, month).entries.map((e) => (e.key, e.value)).toList()
    ..sort((a, b) => b.$2.compareTo(a.$2));
  final previousDaily = cumulative(prev);
  return MonthSummary(
    month: month,
    spentPaise: spent,
    incomePaise: income,
    previousSpentPaise: previousDaily.isEmpty ? 0 : previousDaily.last,
    daily: cumulative(month),
    previousDaily: previousDaily,
    byCategory: cats,
    txns: inMonth,
  );
}

final monthSummaryProvider = Provider<MonthSummary?>((ref) {
  final txns = ref.watch(txnsProvider).value;
  if (txns == null) return null;
  return summarize(txns, ref.watch(selectedMonthProvider), ref.watch(clockProvider)());
});

final budgetStatusProvider = Provider<List<BudgetStatus>>((ref) {
  final txns = ref.watch(txnsProvider).value ?? const [];
  final budgets = ref.watch(budgetsProvider).value ?? const [];
  return budgetStatuses(budgets, txns, ref.watch(selectedMonthProvider));
});

final recurringProvider = Provider<List<RecurringPayment>>((ref) {
  final txns = ref.watch(txnsProvider).value ?? const [];
  return const RecurringDetector().detect(txns);
});

/// Six months of spending totals ending at the selected month.
final monthlyTotalsProvider = Provider<List<(DateTime, int)>>((ref) {
  final txns = ref.watch(txnsProvider).value ?? const [];
  final end = ref.watch(selectedMonthProvider);
  return [
    for (var i = 5; i >= 0; i--)
      () {
        final m = DateTime(end.year, end.month - i);
        final total = txns
            .where((t) => t.isDebit && t.occurredAt.year == m.year && t.occurredAt.month == m.month)
            .fold(0, (s, t) => s + t.amountPaise);
        return (m, total);
      }(),
  ];
});

// ---------------------------------------------------------------------------
// Assistant chat

class ChatEntry {
  const ChatEntry.user(this.text)
      : isUser = true,
        answer = null;
  const ChatEntry.bot(AssistantAnswer this.answer)
      : isUser = false,
        text = '';
  final bool isUser;
  final String text;
  final AssistantAnswer? answer;
}

class ChatController extends Notifier<List<ChatEntry>> {
  bool busy = false;

  @override
  List<ChatEntry> build() => const [];

  Future<void> ask(String question) async {
    final q = question.trim();
    if (q.isEmpty || busy) return;
    busy = true;
    state = [...state, ChatEntry.user(q)];
    try {
      final txns = await ref.read(storeProvider).txns();
      final a = await ref.read(assistantProvider).ask(q, txns);
      state = [...state, ChatEntry.bot(a)];
    } finally {
      busy = false;
    }
  }

  void clear() => state = const [];
}

final chatProvider = NotifierProvider<ChatController, List<ChatEntry>>(ChatController.new);

// ---------------------------------------------------------------------------
// Appearance

class ThemeController extends Notifier<ThemeMode> {
  static const key = 'ui.theme';

  @override
  ThemeMode build() {
    Future(() async {
      final saved = await ref.read(storeProvider).getValue(key);
      final mode = ThemeMode.values.where((m) => m.name == saved).firstOrNull;
      if (mode != null) state = mode;
    });
    return ThemeMode.system;
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await ref.read(storeProvider).setValue(key, mode.name);
  }
}

final themeModeProvider = NotifierProvider<ThemeController, ThemeMode>(ThemeController.new);

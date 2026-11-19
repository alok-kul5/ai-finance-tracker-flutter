/// Turning raw inputs (SMS, receipts, manual entry) into stored transactions.
library;

import 'package:uuid/uuid.dart';

import '../ai/categorizer.dart';
import '../data/store.dart';
import '../domain/models.dart';
import '../insights/budgets.dart';
import '../parsing/merchant.dart';
import '../parsing/sms_parser.dart';
import '../platform/services.dart';

class ImportReport {
  const ImportReport({required this.read, required this.added, required this.duplicates});
  final int read;
  final int added;
  final int duplicates;
}

class Ingestor {
  Ingestor({required this.store, required this.categorizer, this.parser = const SmsParser()});

  final LedgerStore store;
  final Categorizer categorizer;
  final SmsParser parser;
  static const _uuid = Uuid();
  static const lastScanKey = 'sms.lastScan';

  /// Parses, de-duplicates (within the batch and against the database by
  /// reference number), categorises and stores bank SMS.
  Future<ImportReport> importSms(List<RawSms> messages) async {
    final existing = await store.txns();
    final dedupe = SmsDeduper([
      for (final t in existing)
        if (t.reference != null) 'ref:${t.reference}',
    ]);
    var added = 0, dupes = 0;
    for (final m in messages.reversed) {
      final p = parser.parse(m.body, sender: m.sender, receivedAt: m.receivedAt);
      if (p == null) continue;
      if (!dedupe.add(p) || (p.reference != null && await store.hasReference(p.reference!))) {
        dupes++;
        continue;
      }
      final d = await categorizer.categorize(
          merchant: p.merchant, amountPaise: p.amountPaise, direction: p.direction, vpa: p.vpa, text: p.raw);
      await store.saveTxn(Txn(
        id: _uuid.v4(),
        amountPaise: p.amountPaise,
        direction: p.direction,
        occurredAt: p.occurredAt,
        merchant: p.merchant,
        category: d.category,
        categorySource: d.source,
        source: TxnSource.sms,
        reference: p.reference,
        account: p.account,
      ));
      added++;
    }
    return ImportReport(read: messages.length, added: added, duplicates: dupes);
  }

  Future<Txn> addManual({
    required int amountPaise,
    required TxnDirection direction,
    required String merchant,
    required DateTime occurredAt,
    String? category,
    TxnSource source = TxnSource.manual,
    String? note,
  }) async {
    final decided = category != null
        ? CategoryDecision(category, 'user', 1)
        : await categorizer.categorize(merchant: merchant, amountPaise: amountPaise, direction: direction);
    final t = Txn(
      id: _uuid.v4(),
      amountPaise: amountPaise,
      direction: direction,
      occurredAt: occurredAt,
      merchant: merchant,
      category: decided.category,
      categorySource: decided.source,
      source: source,
      note: note,
    );
    await store.saveTxn(t);
    if (category != null) await store.rememberCategory(merchantKey(merchant), category);
    return t;
  }

  /// The user re-files a transaction: remember it for this merchant.
  Future<void> recategorize(Txn t, String category) async {
    await store.saveTxn(t.copyWith(category: category, categorySource: 'user'));
    await store.rememberCategory(merchantKey(t.merchant), category);
  }
}

/// Checks budgets after data changes and sends any new 80% / 100% alerts.
class BudgetWatcher {
  BudgetWatcher({required this.store, required this.notifier});
  final LedgerStore store;
  final LocalNotifier notifier;
  static const _firedKey = 'budgets.fired';

  Future<List<BudgetAlert>> check(DateTime now) async {
    final statuses = budgetStatuses(await store.budgets(), await store.txns(), now);
    final fired = ((await store.getValue(_firedKey)) ?? '').split('\n').where((s) => s.isNotEmpty).toSet();
    final alerts = alertsToFire(statuses, fired, now);
    for (final a in alerts) {
      final s = a.status;
      await notifier.show(
        a.key.hashCode & 0x7fffffff,
        a.title,
        '${s.percent}% of your ${s.budget.category} budget used this month.',
      );
    }
    if (alerts.isNotEmpty) {
      await store.setValue(_firedKey, {...fired, ...firedKeys(alerts)}.join('\n'));
    }
    return alerts;
  }
}

import 'package:kharcha/ai/llm.dart';
import 'package:kharcha/data/store.dart';
import 'package:kharcha/domain/models.dart';
import 'package:kharcha/sync/sync_engine.dart';

/// Scripted LLM: answers by the first matching prompt substring, records
/// every prompt it saw, and can pretend not to be downloaded.
class FakeLlm implements LlmClient {
  FakeLlm({this.ready = true, Map<String, String>? replies, this.fallback = ''})
      : replies = replies ?? {};

  bool ready;
  final Map<String, String> replies;
  final String fallback;
  final prompts = <String>[];
  bool throws = false;

  @override
  Future<bool> get isReady async => ready;

  @override
  Future<String> complete(String prompt) async {
    prompts.add(prompt);
    if (throws) throw Exception('model crashed');
    for (final e in replies.entries) {
      if (prompt.contains(e.key)) return e.value;
    }
    return fallback;
  }
}

/// An in-memory server with the same rules as the Supabase table: LWW on
/// updated_at, and a server sequence number per accepted write.
class FakeRemote implements RemoteStore {
  final rows = <String, (SyncRecord, int)>{};
  var _seq = 0;
  var pushCalls = 0;
  bool offline = false;

  @override
  Future<void> push(List<SyncRecord> records) async {
    if (offline) throw Exception('offline');
    pushCalls++;
    for (final r in records) {
      final key = '${r.kind}/${r.id}';
      final existing = rows[key];
      if (existing != null && r.updatedAtMs < existing.$1.updatedAtMs) continue;
      rows[key] = (r, ++_seq);
    }
  }

  @override
  Future<RemotePage> pull(int cursor, {int limit = 500}) async {
    if (offline) throw Exception('offline');
    final newer = rows.values.where((e) => e.$2 > cursor).toList()..sort((a, b) => a.$2.compareTo(b.$2));
    final page = newer.take(limit).toList();
    return RemotePage([for (final e in page) e.$1], page.isEmpty ? cursor : page.last.$2);
  }
}

var _n = 0;
Txn txn(
  String merchant,
  int rupees, {
  required DateTime at,
  String category = 'Other',
  TxnDirection dir = TxnDirection.debit,
  String? id,
}) =>
    Txn(
      id: id ?? 't${_n++}',
      amountPaise: rupees * 100,
      direction: dir,
      occurredAt: at,
      merchant: merchant,
      category: category,
      source: TxnSource.manual,
    );

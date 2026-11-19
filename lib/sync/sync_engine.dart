/// Optional cloud sync: outbox push, cursor pull, last write wins.
///
/// The local database stays the source of truth. A sync run:
///   1. pushes the *current* version of every record in the outbox (several
///      edits to one record go up once), then clears those entries;
///   2. pulls everything the server accepted since the saved cursor and
///      applies each record only if it is newer than the local copy.
/// The server applies the same rule on write (see supabase/migrations), so
/// two devices editing one record converge on the later edit.
library;

import '../data/store.dart';

class RemotePage {
  const RemotePage(this.records, this.cursor);
  final List<SyncRecord> records;

  /// Opaque server position after these records.
  final int cursor;
}

abstract interface class RemoteStore {
  /// Upserts with last-write-wins on `updatedAt`.
  Future<void> push(List<SyncRecord> records);

  /// Records changed on the server after [cursor], oldest first.
  Future<RemotePage> pull(int cursor, {int limit = 500});
}

class SyncReport {
  const SyncReport({required this.pushed, required this.pulled, required this.skipped});
  final int pushed;
  final int pulled;

  /// Pulled records ignored because the local copy was newer.
  final int skipped;

  @override
  String toString() => 'SyncReport(pushed $pushed, pulled $pulled, skipped $skipped)';
}

class SyncEngine {
  SyncEngine({required this.store, required this.remote});

  final LedgerStore store;
  final RemoteStore remote;

  static const cursorKey = 'sync.cursor';

  bool _running = false;

  Future<SyncReport> sync() async {
    if (_running) return const SyncReport(pushed: 0, pulled: 0, skipped: 0);
    _running = true;
    try {
      final pushed = await _push();
      final (pulled, skipped) = await _pull();
      return SyncReport(pushed: pushed, pulled: pulled, skipped: skipped);
    } finally {
      _running = false;
    }
  }

  Future<int> _push() async {
    final pending = await store.pendingOutbox();
    if (pending.isEmpty) return 0;
    final seen = <String>{};
    final records = <SyncRecord>[];
    for (final e in pending) {
      if (!seen.add('${e.kind}/${e.id}')) continue;
      final r = await store.localRecord(e.kind, e.id);
      if (r != null) records.add(r);
    }
    if (records.isNotEmpty) await remote.push(records);
    // Only the entries read above: edits made during the push stay queued.
    await store.clearOutbox(pending.map((e) => e.seq));
    return records.length;
  }

  Future<(int, int)> _pull() async {
    var cursor = int.tryParse(await store.getValue(cursorKey) ?? '') ?? 0;
    var pulled = 0, skipped = 0;
    while (true) {
      final page = await remote.pull(cursor);
      for (final r in page.records) {
        final local = await store.localRecord(r.kind, r.id);
        if (local == null || r.updatedAtMs > local.updatedAtMs) {
          await store.applyRemote(r);
          pulled++;
        } else {
          skipped++;
        }
      }
      if (page.cursor == cursor || page.records.isEmpty) break;
      cursor = page.cursor;
      await store.setValue(cursorKey, '$cursor');
    }
    return (pulled, skipped);
  }
}

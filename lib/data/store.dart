/// The local ledger: the app's single source of truth. Two implementations
/// share this contract: [DriftLedgerStore] (SQLite, the real app) and
/// [MemoryLedgerStore] (tests and the web demo).
///
/// Every local write bumps `updatedAt` and adds an outbox entry; the sync
/// engine later pushes the current version of each entry's record. Writes
/// coming *from* the server go through [applyRemote], which never touches
/// the outbox.
library;

import '../domain/models.dart';

/// Kinds of synced record.
abstract final class RecordKind {
  static const txn = 'txn';
  static const budget = 'budget';
  static const merchant = 'merchant'; // remembered merchant → category
}

/// One record as the sync layer sees it: an opaque JSON payload plus the
/// fields last-write-wins needs.
class SyncRecord {
  const SyncRecord({
    required this.kind,
    required this.id,
    required this.updatedAt,
    required this.data,
    this.deleted = false,
  });

  final String kind;
  final String id;
  final DateTime updatedAt;
  final bool deleted;
  final Map<String, Object?> data;

  int get updatedAtMs => updatedAt.millisecondsSinceEpoch;

  @override
  String toString() => 'SyncRecord($kind/$id @${updatedAt.toIso8601String()}${deleted ? ' deleted' : ''})';
}

class OutboxEntry {
  const OutboxEntry(this.seq, this.kind, this.id);
  final int seq;
  final String kind;
  final String id;
}

class MerchantMemory {
  MerchantMemory(this.merchantKey, this.category, {DateTime? updatedAt})
      : updatedAt = updatedAt ?? DateTime.now();
  final String merchantKey;
  final String category;
  final DateTime updatedAt;
}

abstract class LedgerStore {
  // Transactions
  Stream<List<Txn>> watchTxns();
  Future<List<Txn>> txns();
  Future<Txn?> txnById(String id);
  Future<bool> hasReference(String reference);
  Future<void> saveTxn(Txn txn);
  Future<void> deleteTxn(String id);

  // Budgets
  Stream<List<Budget>> watchBudgets();
  Future<List<Budget>> budgets();
  Future<void> saveBudget(Budget budget);
  Future<void> deleteBudget(String category);

  // Remembered merchant categories
  Future<String?> rememberedCategory(String merchantKey);
  Future<void> rememberCategory(String merchantKey, String category);

  // Small settings: sync cursor, fired alerts, last SMS scan.
  Future<String?> getValue(String key);
  Future<void> setValue(String key, String value);

  // Sync port
  Future<List<OutboxEntry>> pendingOutbox();
  Future<void> clearOutbox(Iterable<int> seqs);
  Future<SyncRecord?> localRecord(String kind, String id);
  Future<void> applyRemote(SyncRecord record);

  Future<void> close();
}

/// Converting domain objects to and from [SyncRecord]s.
abstract final class RecordCodec {
  static SyncRecord fromTxn(Txn t) => SyncRecord(
      kind: RecordKind.txn, id: t.id, updatedAt: t.updatedAt, deleted: t.deleted, data: t.toJson());

  static Txn toTxn(SyncRecord r) => Txn.fromJson(r.data, updatedAt: r.updatedAt, deleted: r.deleted);

  static SyncRecord fromBudget(Budget b) => SyncRecord(
      kind: RecordKind.budget, id: b.id, updatedAt: b.updatedAt, deleted: b.deleted, data: b.toJson());

  static Budget toBudget(SyncRecord r) =>
      Budget.fromJson(r.data, updatedAt: r.updatedAt, deleted: r.deleted);

  static SyncRecord fromMemory(MerchantMemory m) => SyncRecord(
      kind: RecordKind.merchant,
      id: m.merchantKey,
      updatedAt: m.updatedAt,
      data: {'merchant_key': m.merchantKey, 'category': m.category});

  static MerchantMemory toMemory(SyncRecord r) => MerchantMemory(
      r.data['merchant_key']! as String, r.data['category']! as String,
      updatedAt: r.updatedAt);
}

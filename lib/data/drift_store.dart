import 'package:drift/drift.dart';

import '../domain/models.dart';
import 'database.dart';
import 'store.dart';

/// The SQLite-backed [LedgerStore] the app runs on.
class DriftLedgerStore implements LedgerStore {
  DriftLedgerStore(this.db, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final KharchaDatabase db;
  final DateTime Function() _clock;

  static Txn _toTxn(TxnRow r) => Txn(
        id: r.id,
        amountPaise: r.amountPaise,
        direction: TxnDirection.values.byName(r.direction),
        occurredAt: r.occurredAt,
        merchant: r.merchant,
        category: r.category,
        categorySource: r.categorySource,
        source: TxnSource.values.byName(r.source),
        note: r.note,
        reference: r.reference,
        account: r.account,
        updatedAt: DateTime.fromMillisecondsSinceEpoch(r.updatedAt),
        deleted: r.deleted,
      );

  static TxnsCompanion _txnRow(Txn t) => TxnsCompanion.insert(
        id: t.id,
        amountPaise: t.amountPaise,
        direction: t.direction.name,
        occurredAt: t.occurredAt,
        merchant: t.merchant,
        category: t.category,
        categorySource: Value(t.categorySource),
        source: t.source.name,
        note: Value(t.note),
        reference: Value(t.reference),
        account: Value(t.account),
        updatedAt: t.updatedAt.millisecondsSinceEpoch,
        deleted: Value(t.deleted),
      );

  static Budget _toBudget(BudgetRow r) => Budget(
        category: r.category,
        limitPaise: r.limitPaise,
        updatedAt: DateTime.fromMillisecondsSinceEpoch(r.updatedAt),
        deleted: r.deleted,
      );

  SimpleSelectStatement<$TxnsTable, TxnRow> _liveTxns() => db.select(db.txns)
    ..where((t) => t.deleted.equals(false))
    ..orderBy([(t) => OrderingTerm.desc(t.occurredAt)]);

  Future<void> _enqueue(String kind, String id) =>
      db.into(db.outbox).insert(OutboxCompanion.insert(kind: kind, recordId: id));

  @override
  Stream<List<Txn>> watchTxns() => _liveTxns().watch().map((rows) => rows.map(_toTxn).toList());

  @override
  Future<List<Txn>> txns() async => (await _liveTxns().get()).map(_toTxn).toList();

  @override
  Future<Txn?> txnById(String id) async {
    final r = await (db.select(db.txns)..where((t) => t.id.equals(id))).getSingleOrNull();
    return r == null ? null : _toTxn(r);
  }

  @override
  Future<bool> hasReference(String reference) async {
    final r = await (db.select(db.txns)
          ..where((t) => t.reference.equals(reference))
          ..limit(1))
        .getSingleOrNull();
    return r != null;
  }

  @override
  Future<void> saveTxn(Txn txn) => db.transaction(() async {
        await db.into(db.txns).insertOnConflictUpdate(_txnRow(txn.copyWith(updatedAt: _clock())));
        await _enqueue(RecordKind.txn, txn.id);
      });

  @override
  Future<void> deleteTxn(String id) => db.transaction(() async {
        await (db.update(db.txns)..where((t) => t.id.equals(id))).write(TxnsCompanion(
          deleted: const Value(true),
          updatedAt: Value(_clock().millisecondsSinceEpoch),
        ));
        await _enqueue(RecordKind.txn, id);
      });

  SimpleSelectStatement<$BudgetsTable, BudgetRow> _liveBudgets() => db.select(db.budgets)
    ..where((b) => b.deleted.equals(false))
    ..orderBy([(b) => OrderingTerm.asc(b.category)]);

  @override
  Stream<List<Budget>> watchBudgets() =>
      _liveBudgets().watch().map((rows) => rows.map(_toBudget).toList());

  @override
  Future<List<Budget>> budgets() async => (await _liveBudgets().get()).map(_toBudget).toList();

  @override
  Future<void> saveBudget(Budget budget) => db.transaction(() async {
        await db.into(db.budgets).insertOnConflictUpdate(BudgetsCompanion.insert(
              category: budget.category,
              limitPaise: budget.limitPaise,
              updatedAt: _clock().millisecondsSinceEpoch,
              deleted: const Value(false),
            ));
        await _enqueue(RecordKind.budget, budget.category);
      });

  @override
  Future<void> deleteBudget(String category) => db.transaction(() async {
        await (db.update(db.budgets)..where((b) => b.category.equals(category))).write(BudgetsCompanion(
          deleted: const Value(true),
          updatedAt: Value(_clock().millisecondsSinceEpoch),
        ));
        await _enqueue(RecordKind.budget, category);
      });

  @override
  Future<String?> rememberedCategory(String merchantKey) async {
    final r = await (db.select(db.merchantMemories)..where((m) => m.merchantKey.equals(merchantKey)))
        .getSingleOrNull();
    return r?.category;
  }

  @override
  Future<void> rememberCategory(String merchantKey, String category) => db.transaction(() async {
        await db.into(db.merchantMemories).insertOnConflictUpdate(MerchantMemoriesCompanion.insert(
              merchantKey: merchantKey,
              category: category,
              updatedAt: _clock().millisecondsSinceEpoch,
            ));
        await _enqueue(RecordKind.merchant, merchantKey);
      });

  @override
  Future<String?> getValue(String key) async =>
      (await (db.select(db.kv)..where((k) => k.key.equals(key))).getSingleOrNull())?.value;

  @override
  Future<void> setValue(String key, String value) =>
      db.into(db.kv).insertOnConflictUpdate(KvCompanion.insert(key: key, value: value));

  @override
  Future<List<OutboxEntry>> pendingOutbox() async {
    final rows = await (db.select(db.outbox)..orderBy([(o) => OrderingTerm.asc(o.seq)])).get();
    return [for (final r in rows) OutboxEntry(r.seq, r.kind, r.recordId)];
  }

  @override
  Future<void> clearOutbox(Iterable<int> seqs) async {
    final list = seqs.toList();
    if (list.isEmpty) return;
    await (db.delete(db.outbox)..where((o) => o.seq.isIn(list))).go();
  }

  @override
  Future<SyncRecord?> localRecord(String kind, String id) async {
    switch (kind) {
      case RecordKind.txn:
        final t = await txnById(id);
        return t == null ? null : RecordCodec.fromTxn(t);
      case RecordKind.budget:
        final r = await (db.select(db.budgets)..where((b) => b.category.equals(id))).getSingleOrNull();
        return r == null ? null : RecordCodec.fromBudget(_toBudget(r));
      case RecordKind.merchant:
        final r = await (db.select(db.merchantMemories)..where((m) => m.merchantKey.equals(id)))
            .getSingleOrNull();
        return r == null
            ? null
            : RecordCodec.fromMemory(MerchantMemory(r.merchantKey, r.category,
                updatedAt: DateTime.fromMillisecondsSinceEpoch(r.updatedAt)));
    }
    return null;
  }

  @override
  Future<void> applyRemote(SyncRecord r) async {
    switch (r.kind) {
      case RecordKind.txn:
        await db.into(db.txns).insertOnConflictUpdate(_txnRow(RecordCodec.toTxn(r)));
      case RecordKind.budget:
        final b = RecordCodec.toBudget(r);
        await db.into(db.budgets).insertOnConflictUpdate(BudgetsCompanion.insert(
              category: b.category,
              limitPaise: b.limitPaise,
              updatedAt: r.updatedAtMs,
              deleted: Value(r.deleted),
            ));
      case RecordKind.merchant:
        final m = RecordCodec.toMemory(r);
        await db.into(db.merchantMemories).insertOnConflictUpdate(MerchantMemoriesCompanion.insert(
              merchantKey: m.merchantKey,
              category: m.category,
              updatedAt: r.updatedAtMs,
            ));
    }
  }

  @override
  Future<void> close() => db.close();
}

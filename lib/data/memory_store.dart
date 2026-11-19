import 'dart:async';

import '../domain/models.dart';
import 'store.dart';

/// An in-memory [LedgerStore] with the same semantics as the SQLite one.
/// Used by tests and by the browser demo build.
class MemoryLedgerStore implements LedgerStore {
  MemoryLedgerStore({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
  final _txns = <String, Txn>{};
  final _budgets = <String, Budget>{};
  final _memory = <String, MerchantMemory>{};
  final _kv = <String, String>{};
  final _outbox = <OutboxEntry>[];
  var _seq = 0;

  final _txnCtl = StreamController<List<Txn>>.broadcast();
  final _budgetCtl = StreamController<List<Budget>>.broadcast();

  List<Txn> _liveTxns() => [
        for (final t in _txns.values)
          if (!t.deleted) t
      ]..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

  List<Budget> _liveBudgets() => [
        for (final b in _budgets.values)
          if (!b.deleted) b
      ]..sort((a, b) => a.category.compareTo(b.category));

  void _emit() {
    _txnCtl.add(_liveTxns());
    _budgetCtl.add(_liveBudgets());
  }

  void _enqueue(String kind, String id) => _outbox.add(OutboxEntry(++_seq, kind, id));

  /// Seeds data without creating outbox entries (demo data, tests).
  void seed({Iterable<Txn> txns = const [], Iterable<Budget> budgets = const []}) {
    for (final t in txns) {
      _txns[t.id] = t;
    }
    for (final b in budgets) {
      _budgets[b.id] = b;
    }
    _emit();
  }

  @override
  Stream<List<Txn>> watchTxns() async* {
    yield _liveTxns();
    yield* _txnCtl.stream;
  }

  @override
  Future<List<Txn>> txns() async => _liveTxns();

  @override
  Future<Txn?> txnById(String id) async => _txns[id];

  @override
  Future<bool> hasReference(String reference) async =>
      _txns.values.any((t) => t.reference == reference);

  @override
  Future<void> saveTxn(Txn txn) async {
    _txns[txn.id] = txn.copyWith(updatedAt: _clock());
    _enqueue(RecordKind.txn, txn.id);
    _emit();
  }

  @override
  Future<void> deleteTxn(String id) async {
    final t = _txns[id];
    if (t == null) return;
    _txns[id] = t.copyWith(deleted: true, updatedAt: _clock());
    _enqueue(RecordKind.txn, id);
    _emit();
  }

  @override
  Stream<List<Budget>> watchBudgets() async* {
    yield _liveBudgets();
    yield* _budgetCtl.stream;
  }

  @override
  Future<List<Budget>> budgets() async => _liveBudgets();

  @override
  Future<void> saveBudget(Budget budget) async {
    _budgets[budget.id] = Budget(category: budget.category, limitPaise: budget.limitPaise, updatedAt: _clock());
    _enqueue(RecordKind.budget, budget.id);
    _emit();
  }

  @override
  Future<void> deleteBudget(String category) async {
    final b = _budgets[category];
    if (b == null) return;
    _budgets[category] = Budget(category: category, limitPaise: b.limitPaise, updatedAt: _clock(), deleted: true);
    _enqueue(RecordKind.budget, category);
    _emit();
  }

  @override
  Future<String?> rememberedCategory(String merchantKey) async => _memory[merchantKey]?.category;

  @override
  Future<void> rememberCategory(String merchantKey, String category) async {
    _memory[merchantKey] = MerchantMemory(merchantKey, category, updatedAt: _clock());
    _enqueue(RecordKind.merchant, merchantKey);
  }

  @override
  Future<String?> getValue(String key) async => _kv[key];

  @override
  Future<void> setValue(String key, String value) async => _kv[key] = value;

  @override
  Future<List<OutboxEntry>> pendingOutbox() async => List.of(_outbox);

  @override
  Future<void> clearOutbox(Iterable<int> seqs) async {
    final s = seqs.toSet();
    _outbox.removeWhere((e) => s.contains(e.seq));
  }

  @override
  Future<SyncRecord?> localRecord(String kind, String id) async => switch (kind) {
        RecordKind.txn => _txns[id] == null ? null : RecordCodec.fromTxn(_txns[id]!),
        RecordKind.budget => _budgets[id] == null ? null : RecordCodec.fromBudget(_budgets[id]!),
        RecordKind.merchant => _memory[id] == null ? null : RecordCodec.fromMemory(_memory[id]!),
        _ => null,
      };

  @override
  Future<void> applyRemote(SyncRecord r) async {
    switch (r.kind) {
      case RecordKind.txn:
        _txns[r.id] = RecordCodec.toTxn(r);
      case RecordKind.budget:
        _budgets[r.id] = RecordCodec.toBudget(r);
      case RecordKind.merchant:
        _memory[r.id] = RecordCodec.toMemory(r);
    }
    _emit();
  }

  @override
  Future<void> close() async {
    await _txnCtl.close();
    await _budgetCtl.close();
  }
}

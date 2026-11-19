import 'package:flutter_test/flutter_test.dart';
import 'package:kharcha/data/memory_store.dart';
import 'package:kharcha/data/store.dart';
import 'package:kharcha/domain/models.dart';
import 'package:kharcha/sync/sync_engine.dart';

import '../support/fakes.dart';

/// A controllable clock per device, so last-write-wins is deterministic.
class Clock {
  Clock(this.t);
  DateTime t;
  DateTime call() => t;
  void tick([int minutes = 1]) => t = t.add(Duration(minutes: minutes));
}

void main() {
  late FakeRemote remote;
  late Clock clockA, clockB;
  late MemoryLedgerStore a, b;
  late SyncEngine syncA, syncB;

  setUp(() {
    remote = FakeRemote();
    clockA = Clock(DateTime(2024, 3, 1, 10));
    clockB = Clock(DateTime(2024, 3, 1, 10));
    a = MemoryLedgerStore(clock: clockA.call);
    b = MemoryLedgerStore(clock: clockB.call);
    syncA = SyncEngine(store: a, remote: remote);
    syncB = SyncEngine(store: b, remote: remote);
  });

  test('push then pull moves a transaction to another device', () async {
    await a.saveTxn(txn('Swiggy', 250, at: DateTime(2024, 3, 1), id: 'x1', category: 'Food & Dining'));
    final rA = await syncA.sync();
    expect(rA.pushed, 1);
    expect(await a.pendingOutbox(), isEmpty);

    final rB = await syncB.sync();
    expect(rB.pulled, 1);
    final got = (await b.txns()).single;
    expect(got.merchant, 'Swiggy');
    expect(got.amountPaise, 25000);
    // Pulled records do not bounce back through B's outbox.
    expect(await b.pendingOutbox(), isEmpty);
  });

  test('several edits to one record are pushed once, latest version', () async {
    final t = txn('Uber', 100, at: DateTime(2024, 3, 1), id: 'u1');
    await a.saveTxn(t);
    clockA.tick();
    await a.saveTxn(t.copyWith(category: 'Transport'));
    clockA.tick();
    await a.saveTxn(t.copyWith(category: 'Travel'));
    final r = await syncA.sync();
    expect(r.pushed, 1);
    expect(remote.rows['txn/u1']!.$1.data['category'], 'Travel');
  });

  test('last write wins across devices, in either sync order', () async {
    final t = txn('Amazon', 999, at: DateTime(2024, 3, 1), id: 'm1', category: 'Shopping');
    await a.saveTxn(t);
    await syncA.sync();
    await syncB.sync();

    // B edits first (10:05), A edits later (10:09); B syncs last.
    clockB.tick(5);
    await b.saveTxn(t.copyWith(category: 'Education'));
    clockA.tick(9);
    await a.saveTxn(t.copyWith(category: 'Bills & Utilities'));
    await syncA.sync();
    await syncB.sync(); // B's older push is refused by the server
    await syncA.sync();

    expect((await a.txnById('m1'))!.category, 'Bills & Utilities');
    expect((await b.txnById('m1'))!.category, 'Bills & Utilities');
    expect(remote.rows['txn/m1']!.$1.data['category'], 'Bills & Utilities');
  });

  test('a newer local edit is not overwritten by an older pulled one', () async {
    final t = txn('Zomato', 300, at: DateTime(2024, 3, 1), id: 'z1');
    await b.saveTxn(t.copyWith(category: 'Food & Dining')); // 10:00 on B, unsynced
    clockA.tick(-30);
    await a.saveTxn(t.copyWith(category: 'Other')); // 09:30 on A
    await syncA.sync();

    clockB.tick();
    final r = await syncB.sync();
    expect((await b.txnById('z1'))!.category, 'Food & Dining');
    expect(r.skipped, greaterThanOrEqualTo(0));
    expect(remote.rows['txn/z1']!.$1.data['category'], 'Food & Dining');
  });

  test('deletes sync as tombstones', () async {
    await a.saveTxn(txn('Ola', 120, at: DateTime(2024, 3, 1), id: 'o1'));
    await syncA.sync();
    await syncB.sync();
    expect(await b.txns(), hasLength(1));

    clockA.tick();
    await a.deleteTxn('o1');
    await syncA.sync();
    await syncB.sync();
    expect(await b.txns(), isEmpty);
    expect((await b.txnById('o1'))!.deleted, isTrue);
  });

  test('budgets and remembered merchants sync too', () async {
    await a.saveBudget(Budget(category: 'Groceries', limitPaise: 500000));
    await a.rememberCategory('kumar hardware', 'Shopping');
    await syncA.sync();
    await syncB.sync();
    expect((await b.budgets()).single.limitPaise, 500000);
    expect(await b.rememberedCategory('kumar hardware'), 'Shopping');
  });

  test('offline: the outbox is kept and retried', () async {
    await a.saveTxn(txn('Metro', 60, at: DateTime(2024, 3, 1), id: 'mt1'));
    remote.offline = true;
    await expectLater(syncA.sync(), throwsException);
    expect(await a.pendingOutbox(), hasLength(1));
    remote.offline = false;
    expect((await syncA.sync()).pushed, 1);
    expect(await a.pendingOutbox(), isEmpty);
  });

  test('the pull cursor advances, so the second sync pulls nothing', () async {
    for (var i = 0; i < 5; i++) {
      await a.saveTxn(txn('Shop $i', 10, at: DateTime(2024, 3, 1), id: 's$i'));
    }
    await syncA.sync();
    expect((await syncB.sync()).pulled, 5);
    expect((await syncB.sync()).pulled, 0);
    expect(await b.getValue(SyncEngine.cursorKey), isNotNull);
  });

  test('record codec round trip', () {
    final t = txn('Swiggy', 250, at: DateTime(2024, 3, 1, 13, 30), id: 'c1', category: 'Food & Dining');
    final back = RecordCodec.toTxn(RecordCodec.fromTxn(t));
    expect(back.id, t.id);
    expect(back.occurredAt, t.occurredAt);
    expect(back.category, t.category);
    expect(back.amountPaise, t.amountPaise);
  });
}

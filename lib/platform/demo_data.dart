import 'dart:math';

import '../domain/models.dart';

/// Four months of made-up but believable spending for the browser demo,
/// screenshots and widget tests. Deterministic for a given [now].
List<Txn> demoTxns(DateTime now) {
  final rnd = Random(42);
  final out = <Txn>[];
  var n = 0;
  void add(String merchant, int rupees, DateTime at, String category,
      {TxnDirection dir = TxnDirection.debit, TxnSource source = TxnSource.sms, String? ref, String catSource = 'rule'}) {
    // Draw the random parts first so the sequence never depends on the clock.
    final paise = rupees * 100 + (dir == TxnDirection.debit ? rnd.nextInt(2) * 50 : 0);
    final reference = ref ?? (400000000000 + rnd.nextInt(99999999)).toString();
    if (at.isAfter(now)) return;
    out.add(Txn(
      id: 'demo-${n++}',
      amountPaise: paise,
      direction: dir,
      occurredAt: at,
      merchant: merchant,
      category: category,
      source: source,
      reference: reference,
      account: 'XX4821',
      categorySource: catSource,
      updatedAt: at,
    ));
  }

  for (var back = 3; back >= 0; back--) {
    final m = DateTime(now.year, now.month - back);
    DateTime day(int d, [int h = 13, int min = 0]) {
      final last = DateTime(m.year, m.month + 1, 0).day;
      return DateTime(m.year, m.month, d.clamp(1, last), h, min);
    }

    add('Acme Technologies', 92000, day(1, 9), 'Income', dir: TxnDirection.credit);
    add('NoBroker Rent', 24000, day(3, 10), 'Rent');
    add('Netflix', 649, day(5, 7), 'Subscriptions');
    add('Spotify', 119, day(11, 7), 'Subscriptions');
    add('Airtel Postpaid', 599, day(14, 8), 'Bills & Utilities');
    add('BESCOM', 1400 + rnd.nextInt(400), day(9, 18), 'Bills & Utilities');
    add('Cult.fit', 1499, day(2, 6), 'Subscriptions');
    add('HDFC SIP', 5000, day(7, 9), 'Transfers');
    for (var i = 0; i < 9; i++) {
      final f = ['Swiggy', 'Zomato', 'Swiggy', 'Third Wave Coffee', 'Zomato', 'Chai Point'][rnd.nextInt(6)];
      add(f, 140 + rnd.nextInt(520), day(1 + rnd.nextInt(28), 12 + rnd.nextInt(10), rnd.nextInt(60)), 'Food & Dining');
    }
    for (var i = 0; i < 5; i++) {
      final g = ['Blinkit', 'BigBasket', 'Zepto', 'DMart'][rnd.nextInt(4)];
      add(g, 300 + rnd.nextInt(1600), day(2 + rnd.nextInt(26), 19, rnd.nextInt(60)), 'Groceries');
    }
    for (var i = 0; i < 7; i++) {
      final t = ['Uber', 'Rapido', 'Namma Metro', 'Ola'][rnd.nextInt(4)];
      add(t, 40 + rnd.nextInt(380), day(1 + rnd.nextInt(28), 9, rnd.nextInt(60)), 'Transport');
    }
    add(['Amazon', 'Myntra', 'Flipkart'][rnd.nextInt(3)], 900 + rnd.nextInt(3200), day(15 + rnd.nextInt(8), 21), 'Shopping');
    if (back.isOdd) add('PVR Cinemas', 780, day(20, 20), 'Entertainment');
    if (back == 2) add('IndiGo', 6450, day(18, 11), 'Travel');
    if (back == 1) add('Apollo Pharmacy', 640, day(12, 17), 'Health', source: TxnSource.receipt, catSource: 'llm');
    if (back == 0) add('Kumar Hardware', 860, day(4, 16), 'Shopping', source: TxnSource.receipt, catSource: 'llm');
    add('Rahul Verma', 1500 + rnd.nextInt(1000), day(16, 22), 'Transfers', dir: TxnDirection.credit);
  }
  out.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
  return out;
}

List<Budget> demoBudgets() => [
      Budget(category: 'Food & Dining', limitPaise: 400000),
      Budget(category: 'Groceries', limitPaise: 600000),
      Budget(category: 'Transport', limitPaise: 200000),
      Budget(category: 'Shopping', limitPaise: 300000),
      Budget(category: 'Subscriptions', limitPaise: 250000),
    ];

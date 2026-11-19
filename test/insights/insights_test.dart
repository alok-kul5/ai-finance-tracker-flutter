import 'package:flutter_test/flutter_test.dart';
import 'package:kharcha/domain/models.dart';
import 'package:kharcha/insights/budgets.dart';
import 'package:kharcha/insights/recurring.dart';

import '../support/fakes.dart';

void main() {
  group('budgets', () {
    final march = DateTime(2024, 3, 15);
    final budget = Budget(category: 'Food & Dining', limitPaise: 100000); // ₹1,000

    List<BudgetStatus> statusFor(int rupees) => budgetStatuses(
          [budget],
          [
            txn('Swiggy', rupees, at: DateTime(2024, 3, 3), category: 'Food & Dining'),
            txn('Swiggy', 5000, at: DateTime(2024, 2, 28), category: 'Food & Dining'), // other month
            txn('Uber', 5000, at: DateTime(2024, 3, 4), category: 'Transport'), // other category
            txn('Refund', 5000, at: DateTime(2024, 3, 4), category: 'Food & Dining', dir: TxnDirection.credit),
          ],
          march,
        );

    test('levels at 79, 80, 99, 100, 130 percent', () {
      expect(statusFor(799).single.level, BudgetLevel.ok);
      expect(statusFor(800).single.level, BudgetLevel.warning);
      expect(statusFor(999).single.level, BudgetLevel.warning);
      expect(statusFor(1000).single.level, BudgetLevel.over);
      expect(statusFor(1300).single.percent, 130);
      expect(statusFor(1300).single.remainingPaise, -30000);
    });

    test('alerts fire once per threshold per month', () {
      final warn = statusFor(850);
      final first = alertsToFire(warn, {}, march);
      expect(first.single.threshold, 80);
      final fired = firedKeys(first);
      expect(alertsToFire(warn, fired, march), isEmpty);

      final over = statusFor(1100);
      final second = alertsToFire(over, fired, march);
      expect(second.single.threshold, 100);
      expect(alertsToFire(over, {...fired, ...firedKeys(second)}, march), isEmpty);

      // A new month starts fresh.
      expect(alertsToFire(over, {...fired, ...firedKeys(second)}, DateTime(2024, 4, 2)), hasLength(1));
    });

    test('jumping straight past 100% sends only the 100% alert, and 80% never fires late', () {
      final over = statusFor(1500);
      final alerts = alertsToFire(over, {}, march);
      expect(alerts.single.threshold, 100);
      final keys = firedKeys(alerts);
      expect(keys, containsAll(['Food & Dining|2024-03|100', 'Food & Dining|2024-03|80']));
    });
  });

  group('recurring detection', () {
    const detector = RecurringDetector();

    test('monthly Netflix with slightly varying dates', () {
      final list = [
        for (final (m, d) in [(1, 5), (2, 4), (3, 6), (4, 5), (5, 5)])
          txn('NETFLIX.COM', 649, at: DateTime(2024, m, d), category: 'Subscriptions'),
      ];
      final found = detector.detect(list).single;
      expect(found.period, RecurringPeriod.monthly);
      expect(found.typicalPaise, 64900);
      expect(found.occurrences, 5);
      expect(found.nextExpected, DateTime(2024, 6, 5));
    });

    test('merchant spellings are grouped and amounts may wobble 10%', () {
      final list = [
        txn('BESCOM', 1800, at: DateTime(2024, 1, 10)),
        txn('bescom@okbizaxis', 1950, at: DateTime(2024, 2, 9)),
        txn('Bescom Electricity', 1720, at: DateTime(2024, 3, 11)),
      ];
      final found = detector.detect(list).single;
      expect(found.merchantKey, contains('bescom'));
      expect(found.monthlyPaise, closeTo(180000, 1));
    });

    test('weekly and yearly', () {
      final weekly = [for (var i = 0; i < 5; i++) txn('Milkbasket', 420, at: DateTime(2024, 3, 1).add(Duration(days: 7 * i)))];
      expect(detector.detect(weekly).single.period, RecurringPeriod.weekly);
      final yearly = [for (var y = 2021; y <= 2024; y++) txn('Amazon Prime', 1499, at: DateTime(y, 7, 15))];
      expect(detector.detect(yearly).single.period, RecurringPeriod.yearly);
    });

    test('not recurring: irregular gaps, very different amounts, too few, credits', () {
      expect(detector.detect([
        txn('Swiggy', 300, at: DateTime(2024, 1, 1)),
        txn('Swiggy', 310, at: DateTime(2024, 1, 3)),
        txn('Swiggy', 290, at: DateTime(2024, 1, 20)),
        txn('Swiggy', 300, at: DateTime(2024, 2, 27)),
      ]), isEmpty);
      expect(detector.detect([
        txn('Amazon', 499, at: DateTime(2024, 1, 5)),
        txn('Amazon', 4999, at: DateTime(2024, 2, 5)),
        txn('Amazon', 1299, at: DateTime(2024, 3, 5)),
      ]), isEmpty);
      expect(detector.detect([
        txn('Spotify', 119, at: DateTime(2024, 1, 5)),
        txn('Spotify', 119, at: DateTime(2024, 2, 5)),
      ]), isEmpty);
      expect(detector.detect([
        for (var m = 1; m <= 4; m++) txn('Acme', 85000, at: DateTime(2024, m, 1), dir: TxnDirection.credit),
      ]), isEmpty);
    });

    test('next date clamps to month end', () {
      final list = [for (var m = 1; m <= 3; m++) txn('Gym', 1500, at: DateTime(2024, m, m == 2 ? 29 : 31))];
      final found = detector.detect(list).single;
      expect(found.nextExpected, DateTime(2024, 4, 30));
    });
  });
}

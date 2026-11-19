/// Finds subscriptions, rent, SIPs and other regular payments: the same
/// normalised merchant, a similar amount, at a regular interval.
library;

import '../domain/models.dart';
import '../parsing/merchant.dart';

enum RecurringPeriod { weekly, monthly, quarterly, yearly }

extension RecurringPeriodX on RecurringPeriod {
  int get days => switch (this) {
        RecurringPeriod.weekly => 7,
        RecurringPeriod.monthly => 30,
        RecurringPeriod.quarterly => 91,
        RecurringPeriod.yearly => 365,
      };
  String get label => switch (this) {
        RecurringPeriod.weekly => 'Weekly',
        RecurringPeriod.monthly => 'Monthly',
        RecurringPeriod.quarterly => 'Quarterly',
        RecurringPeriod.yearly => 'Yearly',
      };
}

class RecurringPayment {
  const RecurringPayment({
    required this.merchant,
    required this.merchantKey,
    required this.period,
    required this.typicalPaise,
    required this.occurrences,
    required this.lastPaid,
    required this.nextExpected,
    required this.category,
  });

  final String merchant;
  final String merchantKey;
  final RecurringPeriod period;
  final int typicalPaise; // median amount
  final int occurrences;
  final DateTime lastPaid;
  final DateTime nextExpected;
  final String category;

  /// Rough monthly cost, for "your subscriptions cost ₹X a month".
  int get monthlyPaise => (typicalPaise * 30 / period.days).round();
}

class RecurringDetector {
  const RecurringDetector({
    this.minOccurrences = 3,
    this.amountTolerance = 0.15,
  });

  final int minOccurrences;

  /// Each amount must be within this fraction of the median.
  final double amountTolerance;

  static const _windows = <RecurringPeriod, (int, int)>{
    RecurringPeriod.weekly: (6, 8),
    RecurringPeriod.monthly: (26, 34),
    RecurringPeriod.quarterly: (84, 98),
    RecurringPeriod.yearly: (355, 375),
  };

  List<RecurringPayment> detect(Iterable<Txn> txns) {
    final groups = <String, List<Txn>>{};
    for (final t in txns) {
      if (t.deleted || !t.isDebit) continue;
      groups.putIfAbsent(merchantKey(t.merchant), () => []).add(t);
    }
    final out = <RecurringPayment>[];
    for (final e in groups.entries) {
      final found = _check(e.key, e.value);
      if (found != null) out.add(found);
    }
    out.sort((a, b) => a.nextExpected.compareTo(b.nextExpected));
    return out;
  }

  RecurringPayment? _check(String key, List<Txn> list) {
    if (list.length < minOccurrences) return null;
    list.sort((a, b) => a.occurredAt.compareTo(b.occurredAt));

    // Several payments on one day (a split bill) count once, by their sum.
    final byDay = <DateTime, int>{};
    for (final t in list) {
      final d = DateTime(t.occurredAt.year, t.occurredAt.month, t.occurredAt.day);
      byDay[d] = (byDay[d] ?? 0) + t.amountPaise;
    }
    final days = byDay.keys.toList()..sort();
    if (days.length < minOccurrences) return null;

    final amounts = [for (final d in days) byDay[d]!];
    final median = _median(amounts);
    if (median <= 0) return null;
    for (final a in amounts) {
      if ((a - median).abs() > median * amountTolerance) return null;
    }

    final gaps = [
      for (var i = 1; i < days.length; i++) days[i].difference(days[i - 1]).inDays,
    ];
    final medianGap = _median(gaps);
    RecurringPeriod? period;
    for (final w in _windows.entries) {
      if (medianGap >= w.value.$1 && medianGap <= w.value.$2) period = w.key;
    }
    if (period == null) return null;
    final (lo, hi) = _windows[period]!;
    // Every gap must fit the period (one missed month is a different story).
    if (gaps.any((g) => g < lo || g > hi)) return null;

    final last = days.last;
    final next = switch (period) {
      RecurringPeriod.monthly => _addMonths(last, 1),
      RecurringPeriod.quarterly => _addMonths(last, 3),
      RecurringPeriod.yearly => _addMonths(last, 12),
      RecurringPeriod.weekly => last.add(const Duration(days: 7)),
    };
    return RecurringPayment(
      merchant: list.last.merchant,
      merchantKey: key,
      period: period,
      typicalPaise: median,
      occurrences: days.length,
      lastPaid: last,
      nextExpected: next,
      category: list.last.category,
    );
  }

  static int _median(List<int> xs) {
    final s = [...xs]..sort();
    final n = s.length;
    return n.isOdd ? s[n ~/ 2] : ((s[n ~/ 2 - 1] + s[n ~/ 2]) / 2).round();
  }

  static DateTime _addMonths(DateTime d, int months) {
    final m = DateTime(d.year, d.month + months);
    final lastDay = DateTime(m.year, m.month + 1, 0).day;
    return DateTime(m.year, m.month, d.day > lastDay ? lastDay : d.day);
  }
}

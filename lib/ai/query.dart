/// The structured question the assistant answers. The LLM (or the rule
/// parser) only fills this in; the numbers come from [QueryEngine].
library;

import '../domain/models.dart';

enum Metric { total, count, average, largest, topMerchants, byCategory }

class DateRange {
  const DateRange(this.start, this.end, this.label);

  /// Inclusive start, exclusive end, local time.
  final DateTime start;
  final DateTime end;
  final String label;

  bool contains(DateTime t) => !t.isBefore(start) && t.isBefore(end);

  @override
  bool operator ==(Object other) =>
      other is DateRange && other.start == start && other.end == end;
  @override
  int get hashCode => Object.hash(start, end);
  @override
  String toString() => 'DateRange($label: $start → $end)';
}

class SpendQuery {
  const SpendQuery({
    required this.metric,
    required this.range,
    this.direction = TxnDirection.debit,
    this.category,
    this.merchant,
  });

  final Metric metric;
  final DateRange range;
  final TxnDirection direction;
  final String? category; // one of kCategories
  final String? merchant; // a merchant key

  SpendQuery copyWith({
    Metric? metric,
    DateRange? range,
    TxnDirection? direction,
    String? category,
    String? merchant,
  }) =>
      SpendQuery(
        metric: metric ?? this.metric,
        range: range ?? this.range,
        direction: direction ?? this.direction,
        category: category ?? this.category,
        merchant: merchant ?? this.merchant,
      );

  @override
  String toString() =>
      'SpendQuery(${metric.name}, ${direction.name}, cat=$category, merchant=$merchant, $range)';
}

const _monthNames = [
  'january', 'february', 'march', 'april', 'may', 'june', 'july',
  'august', 'september', 'october', 'november', 'december',
];
const _monthShort = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

int? monthFromName(String s) {
  final l = s.toLowerCase();
  if (l.length < 3) return null;
  for (var i = 0; i < 12; i++) {
    if (_monthNames[i].startsWith(l)) return i + 1;
  }
  return null;
}

/// Named periods the LLM may return, resolved here against the clock so
/// the model never does date arithmetic.
const kPeriods = <String>[
  'today', 'yesterday', 'this_week', 'last_week', 'this_month', 'last_month',
  'this_year', 'last_year', 'last_7_days', 'last_30_days', 'last_90_days', 'all_time',
];

DateRange resolvePeriod(String period, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final weekStart = today.subtract(Duration(days: today.weekday - 1)); // Monday
  switch (period) {
    case 'today':
      return DateRange(today, today.add(const Duration(days: 1)), 'today');
    case 'yesterday':
      return DateRange(today.subtract(const Duration(days: 1)), today, 'yesterday');
    case 'this_week':
      return DateRange(weekStart, today.add(const Duration(days: 1)), 'this week');
    case 'last_week':
      return DateRange(weekStart.subtract(const Duration(days: 7)), weekStart, 'last week');
    case 'last_month':
      return DateRange(DateTime(now.year, now.month - 1), DateTime(now.year, now.month),
          'in ${monthLabel(DateTime(now.year, now.month - 1))}');
    case 'this_year':
      return DateRange(DateTime(now.year), DateTime(now.year + 1), 'this year');
    case 'last_year':
      return DateRange(DateTime(now.year - 1), DateTime(now.year), 'last year');
    case 'last_7_days':
      return lastNDays(7, now);
    case 'last_30_days':
      return lastNDays(30, now);
    case 'last_90_days':
      return lastNDays(90, now);
    case 'all_time':
      return DateRange(DateTime(2000), today.add(const Duration(days: 1)), 'in total');
    case 'this_month':
    default:
      return DateRange(DateTime(now.year, now.month), DateTime(now.year, now.month + 1), 'this month');
  }
}

DateRange lastNDays(int n, DateTime now) {
  final end = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
  return DateRange(end.subtract(Duration(days: n)), end, 'in the last $n days');
}

/// A named month; a month later than now means last year's.
DateRange monthRange(int month, DateTime now, {int? year}) {
  var y = year ?? now.year;
  if (year == null && month > now.month) y -= 1;
  final start = DateTime(y, month);
  return DateRange(start, DateTime(y, month + 1), 'in ${monthLabel(start)}');
}

String monthLabel(DateTime d) => '${_monthShort[d.month - 1]} ${d.year}';

/// Every number the assistant says is computed here, in plain Dart, from the
/// local database. The model never sees amounts and never does arithmetic.
library;

import '../domain/models.dart';
import '../domain/money.dart';
import '../parsing/merchant.dart';
import 'query.dart';

class QueryResult {
  const QueryResult({
    required this.query,
    required this.matches,
    required this.totalPaise,
    required this.count,
    this.largest,
    this.ranked = const [],
  });

  final SpendQuery query;
  final List<Txn> matches;
  final int totalPaise;
  final int count;
  final Txn? largest;

  /// (label, paise) pairs, biggest first: merchants or categories.
  final List<(String, int)> ranked;

  /// Integer paise, rounded half up.
  int get averagePaise => count == 0 ? 0 : (totalPaise + count ~/ 2) ~/ count;
}

class QueryEngine {
  const QueryEngine();

  QueryResult run(SpendQuery q, Iterable<Txn> txns) {
    final matches = [
      for (final t in txns)
        if (!t.deleted &&
            t.direction == q.direction &&
            q.range.contains(t.occurredAt) &&
            (q.category == null || t.category == q.category) &&
            (q.merchant == null || _merchantMatches(t.merchant, q.merchant!)))
          t
    ]..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

    var total = 0;
    Txn? largest;
    for (final t in matches) {
      total += t.amountPaise;
      if (largest == null || t.amountPaise > largest.amountPaise) largest = t;
    }

    List<(String, int)> ranked = const [];
    if (q.metric == Metric.topMerchants || q.metric == Metric.byCategory) {
      final sums = <String, int>{};
      final names = <String, String>{};
      for (final t in matches) {
        final key = q.metric == Metric.byCategory ? t.category : merchantKey(t.merchant);
        sums[key] = (sums[key] ?? 0) + t.amountPaise;
        names.putIfAbsent(key, () => q.metric == Metric.byCategory ? t.category : t.merchant);
      }
      ranked = [for (final e in sums.entries) (names[e.key]!, e.value)]
        ..sort((a, b) => b.$2 != a.$2 ? b.$2.compareTo(a.$2) : a.$1.compareTo(b.$1));
    }

    return QueryResult(
      query: q,
      matches: matches,
      totalPaise: total,
      count: matches.length,
      largest: largest,
      ranked: ranked,
    );
  }

  static bool _merchantMatches(String merchant, String key) {
    final k = merchantKey(merchant);
    return k == key || k.contains(key) || key.contains(k) && k.length >= 3;
  }
}

/// Fills a fixed sentence template with numbers from [QueryResult].
class AnswerComposer {
  const AnswerComposer();

  String compose(QueryResult r) {
    final q = r.query;
    final spend = q.direction == TxnDirection.debit;
    final what = [
      if (q.category != null) q.category,
      if (q.merchant != null) 'at ${displayMerchant(q.merchant!)}',
    ].join(' ');
    final scope = what.isEmpty ? '' : ' on $what'.replaceFirst(' on at ', ' at ');
    final when = q.range.label;
    final money = formatPaise;

    if (r.count == 0) {
      return spend
          ? 'I found no spending$scope $when.'
          : 'I found no money coming in$scope $when.';
    }
    final n = '${r.count} transaction${r.count == 1 ? '' : 's'}';
    switch (q.metric) {
      case Metric.total:
        return spend
            ? 'You spent ${money(r.totalPaise)}$scope $when, across $n.'
            : 'You received ${money(r.totalPaise)}$scope $when, across $n.';
      case Metric.count:
        return 'You made $n$scope $when, worth ${money(r.totalPaise)} in all.';
      case Metric.average:
        return 'Your average ${spend ? 'spend' : 'credit'}$scope $when was ${money(r.averagePaise)} per transaction ($n, ${money(r.totalPaise)} total).';
      case Metric.largest:
        final t = r.largest!;
        return 'Your largest ${spend ? 'payment' : 'credit'}$scope $when was ${money(t.amountPaise)} ${spend ? 'to' : 'from'} ${t.merchant} on ${t.occurredAt.day} ${monthLabel(t.occurredAt)}.';
      case Metric.topMerchants:
      case Metric.byCategory:
        final top = r.ranked.take(3).toList();
        final parts = [for (final (name, v) in top) '$name ${money(v)}'];
        final label = q.metric == Metric.byCategory ? 'categories' : 'merchants';
        return 'Your top $label$scope $when: ${parts.join(', ')}. Total ${money(r.totalPaise)} across $n.';
    }
  }
}

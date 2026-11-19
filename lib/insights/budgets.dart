/// Monthly budget maths and the 80% / 100% alert rule.
library;

import '../domain/models.dart';

enum BudgetLevel { ok, warning, over }

class BudgetStatus {
  const BudgetStatus({required this.budget, required this.spentPaise});
  final Budget budget;
  final int spentPaise;

  double get ratio => budget.limitPaise <= 0 ? 0 : spentPaise / budget.limitPaise;
  int get remainingPaise => budget.limitPaise - spentPaise;

  /// Whole percent, rounded down, so 79.99% never shows as "80%".
  int get percent => budget.limitPaise <= 0 ? 0 : (spentPaise * 100) ~/ budget.limitPaise;

  BudgetLevel get level => percent >= 100
      ? BudgetLevel.over
      : percent >= 80
          ? BudgetLevel.warning
          : BudgetLevel.ok;
}

String monthKey(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}';

/// Spending per category for the month containing [month].
Map<String, int> spentByCategory(Iterable<Txn> txns, DateTime month) {
  final start = DateTime(month.year, month.month);
  final end = DateTime(month.year, month.month + 1);
  final out = <String, int>{};
  for (final t in txns) {
    if (t.deleted || !t.isDebit) continue;
    if (t.occurredAt.isBefore(start) || !t.occurredAt.isBefore(end)) continue;
    out[t.category] = (out[t.category] ?? 0) + t.amountPaise;
  }
  return out;
}

List<BudgetStatus> budgetStatuses(Iterable<Budget> budgets, Iterable<Txn> txns, DateTime month) {
  final spent = spentByCategory(txns, month);
  return [
    for (final b in budgets)
      if (!b.deleted) BudgetStatus(budget: b, spentPaise: spent[b.category] ?? 0)
  ]..sort((a, b) => b.ratio.compareTo(a.ratio));
}

class BudgetAlert {
  const BudgetAlert(this.status, this.threshold, this.key);
  final BudgetStatus status;
  final int threshold; // 80 or 100
  final String key; // "Groceries|2024-03|80": fired at most once a month

  String get title => threshold >= 100
      ? '${status.budget.category} budget used up'
      : '${status.budget.category} at ${status.percent}% of budget';
}

/// Alerts to fire now: each (category, month, threshold) once. When both
/// thresholds were crossed since the last check only the 100% one fires,
/// and the 80% key is recorded so it never fires late.
List<BudgetAlert> alertsToFire(
    Iterable<BudgetStatus> statuses, Set<String> alreadyFired, DateTime month) {
  final out = <BudgetAlert>[];
  for (final s in statuses) {
    final base = '${s.budget.category}|${monthKey(month)}';
    if (s.level == BudgetLevel.over && !alreadyFired.contains('$base|100')) {
      out.add(BudgetAlert(s, 100, '$base|100'));
    } else if (s.level == BudgetLevel.warning && !alreadyFired.contains('$base|80')) {
      out.add(BudgetAlert(s, 80, '$base|80'));
    }
  }
  return out;
}

/// Keys to store after firing [alerts] (a 100% alert also marks 80%).
Set<String> firedKeys(Iterable<BudgetAlert> alerts) => {
      for (final a in alerts) ...[
        a.key,
        if (a.threshold == 100) a.key.replaceFirst(RegExp(r'\|100$'), '|80'),
      ]
    };

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../insights/recurring.dart';
import '../state/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/charts.dart';
import '../widgets/ui.dart';
import 'home_tab.dart';
import 'sheets.dart';

class InsightsTab extends ConsumerWidget {
  const InsightsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final k = context.k;
    final month = ref.watch(selectedMonthProvider);
    final summary = ref.watch(monthSummaryProvider);
    final budgets = ref.watch(budgetStatusProvider);
    final recurring = ref.watch(recurringProvider);
    final months = ref.watch(monthlyTotalsProvider);
    final now = ref.watch(clockProvider)();
    final isCurrent = month.year == now.year && month.month == now.month;
    final monthlyRecurring = recurring.fold(0, (s, r) => s + r.monthlyPaise);

    return CustomScrollView(slivers: [
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 16, 12, 4),
          child: Row(children: [
            Expanded(child: Text('Insights', style: KText.largeTitle(context))),
            IconButton(
              tooltip: 'Previous month',
              onPressed: () => ref.read(selectedMonthProvider.notifier).shift(-1),
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Text(DateFormat('MMM yyyy').format(month), style: KText.headline(context)),
            IconButton(
              tooltip: 'Next month',
              onPressed: isCurrent ? null : () => ref.read(selectedMonthProvider.notifier).shift(1),
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ]),
        ),
      ),
      SliverToBoxAdapter(
        child: Surface(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          padding: const EdgeInsets.all(16),
          child: summary == null || summary.byCategory.isEmpty
              ? const EmptyState(icon: Icons.donut_large_rounded, title: 'No spending this month')
              : Column(children: [
                  CategoryDonut(slices: summary.byCategory, total: summary.spentPaise),
                  const SizedBox(height: 16),
                  for (final (i, (cat, v)) in summary.byCategory.take(6).indexed)
                    FadeSlideIn(
                      index: i,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(children: [
                          Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(color: CategoryVisuals.color(cat), borderRadius: BorderRadius.circular(3))),
                          const SizedBox(width: 10),
                          Expanded(child: Text(cat, style: KText.body(context))),
                          Text('${(v * 100 / summary.spentPaise).round()}%',
                              style: KText.caption(context).copyWith(color: k.tertiaryLabel)),
                          const SizedBox(width: 12),
                          MoneyText(v, style: KText.amount(context, size: 15), decimals: false),
                        ]),
                      ),
                    ),
                ]),
        ),
      ),
      const SliverToBoxAdapter(child: SectionHeader('Last six months')),
      SliverToBoxAdapter(
        child: Surface(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.fromLTRB(12, 18, 12, 8),
          child: MonthlyBars(months: months, selected: month),
        ),
      ),
      SliverToBoxAdapter(
        child: SectionHeader('Budgets',
            trailing: TextButton.icon(
              onPressed: () => showKSheet(context, const BudgetEditorSheet()),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add', style: TextStyle(fontWeight: FontWeight.w600)),
            )),
      ),
      SliverToBoxAdapter(
        child: Surface(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
          child: budgets.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Text('Set a monthly limit per category and get alerts at 80% and 100%.',
                      style: KText.caption(context), textAlign: TextAlign.center),
                )
              : Column(children: [
                  for (final s in budgets)
                    BudgetRow(
                      status: s,
                      onTap: () => showKSheet(context, BudgetEditorSheet(category: s.budget.category, limitPaise: s.budget.limitPaise)),
                    ),
                ]),
        ),
      ),
      SliverToBoxAdapter(
        child: SectionHeader('Recurring',
            trailing: recurring.isEmpty
                ? null
                : Text('≈ ₹${NumberFormat.decimalPattern('en_IN').format(monthlyRecurring ~/ 100)}/mo', style: KText.caption(context))),
      ),
      SliverToBoxAdapter(
        child: Surface(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: recurring.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text('Payments to the same merchant, for a similar amount, at a regular interval show up here.',
                      style: KText.caption(context), textAlign: TextAlign.center),
                )
              : Column(children: [
                  for (final (i, r) in recurring.indexed) _RecurringRow(r: r, now: now, divider: i < recurring.length - 1),
                ]),
        ),
      ),
      SliverToBoxAdapter(child: SizedBox(height: bottomClearance(context))),
    ]);
  }
}

class _RecurringRow extends StatelessWidget {
  const _RecurringRow({required this.r, required this.now, required this.divider});
  final RecurringPayment r;
  final DateTime now;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final today = DateTime(now.year, now.month, now.day);
    final days = r.nextExpected.difference(today).inDays;
    final when = days < 0
        ? 'was due ${DateFormat('d MMM').format(r.nextExpected)}'
        : days == 0
            ? 'due today'
            : days == 1
                ? 'due tomorrow'
                : 'next ${DateFormat('d MMM').format(r.nextExpected)}';
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
        child: Row(children: [
          IconTile(CategoryVisuals.icon(r.category), color: CategoryVisuals.color(r.category), size: 40, circle: true),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.merchant, style: KText.headline(context)),
              Text('${r.period.label} · ${r.occurrences} payments · $when', style: KText.caption(context)),
            ]),
          ),
          MoneyText(r.typicalPaise, style: KText.amount(context, size: 15), decimals: false),
        ]),
      ),
      if (divider) Padding(padding: const EdgeInsets.only(left: 66), child: Divider(height: 0.5, thickness: 0.5, color: k.separator)),
    ]);
  }
}

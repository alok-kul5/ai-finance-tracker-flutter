import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../insights/budgets.dart';
import '../insights/recurring.dart';
import '../state/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/charts.dart';
import '../widgets/txn_tile.dart';
import '../widgets/ui.dart';
import 'settings_screen.dart';
import 'sheets.dart';

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key, required this.onSeeAll});
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(monthSummaryProvider);
    final budgets = ref.watch(budgetStatusProvider);
    final recurring = ref.watch(recurringProvider);
    final now = ref.watch(clockProvider)();
    final recent = (ref.watch(txnsProvider).value ?? const []).take(6).toList();

    return CustomScrollView(slivers: [
      SliverToBoxAdapter(child: _Hero(summary: summary)),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(children: [
            Expanded(child: _StatCard.budget(context, budgets)),
            const SizedBox(width: 12),
            Expanded(child: _StatCard.upcoming(context, recurring, now)),
          ]),
        ),
      ),
      if (budgets.isNotEmpty) ...[
        const SliverToBoxAdapter(child: SectionHeader('Budgets')),
        SliverToBoxAdapter(
          child: Surface(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
            child: Column(children: [
              for (final (i, s) in budgets.take(4).indexed) FadeSlideIn(index: i, child: BudgetRow(status: s)),
            ]),
          ),
        ),
      ],
      SliverToBoxAdapter(
        child: SectionHeader('Recent',
            trailing: TextButton(onPressed: onSeeAll, child: const Text('See all', style: TextStyle(fontWeight: FontWeight.w600)))),
      ),
      if (recent.isEmpty)
        const SliverToBoxAdapter(
          child: EmptyState(
            icon: Icons.receipt_long_rounded,
            title: 'Nothing here yet',
            message: 'Tap + to import bank SMS, scan a receipt or add one by hand.',
          ),
        )
      else
        SliverList.builder(
          itemCount: recent.length,
          itemBuilder: (context, i) => FadeSlideIn(
            index: i,
            child: TxnTile(
              txn: recent[i],
              showDate: true,
              position: GroupPosition.of(i, recent.length),
              onTap: () => showKSheet(context, TxnDetailSheet(txn: recent[i])),
            ),
          ),
        ),
      SliverToBoxAdapter(child: SizedBox(height: bottomClearance(context))),
    ]);
  }
}

class _Hero extends ConsumerWidget {
  const _Hero({required this.summary});
  final MonthSummary? summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final top = MediaQuery.paddingOf(context).top;
    final s = summary;
    final month = ref.watch(selectedMonthProvider);
    final now = ref.watch(clockProvider)();
    final isCurrent = month.year == now.year && month.month == now.month;
    final white70 = Colors.white.withAlpha(180);
    String? delta;
    if (s != null && s.previousDaily.isNotEmpty) {
      // Compare with last month at the same day, not the whole month.
      final day = s.daily.length.clamp(1, s.previousDaily.length);
      final prevAtDay = s.previousDaily[day - 1];
      if (prevAtDay > 0) {
        final pct = ((s.spentPaise - prevAtDay) * 100 / prevAtDay).round();
        delta = pct == 0 ? 'Same as last month' : '${pct.abs()}% ${pct > 0 ? 'more' : 'less'} than last month';
      }
    }
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(Radii.hero)),
      child: HeroBackground(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, top + 12, 20, 18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const _Logo(),
              const SizedBox(width: 10),
              const Text('Kharcha',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.4)),
              const Spacer(),
              GlassIconButton(
                icon: Icons.settings_rounded,
                tooltip: 'Settings',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
              ),
            ]),
            const SizedBox(height: 22),
            Row(children: [
              GlassIconButton(icon: Icons.chevron_left_rounded, size: 30, tooltip: 'Previous month', onTap: () => ref.read(selectedMonthProvider.notifier).shift(-1)),
              const SizedBox(width: 8),
              Text(isCurrent ? 'Spent this month' : 'Spent in ${DateFormat('MMMM yyyy').format(month)}',
                  style: TextStyle(color: white70, fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(width: 8),
              if (!isCurrent)
                GlassIconButton(icon: Icons.chevron_right_rounded, size: 30, tooltip: 'Next month', onTap: () => ref.read(selectedMonthProvider.notifier).shift(1)),
            ]),
            const SizedBox(height: 8),
            AnimatedAmount(s?.spentPaise ?? 0,
                style: KText.amount(context, size: 44, color: Colors.white), decimalsColor: Colors.white.withAlpha(110)),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: [
              if (s != null && s.incomePaise > 0) GlassChip(icon: Icons.south_west_rounded, label: 'In ${_short(s.incomePaise)}'),
              if (delta != null) GlassChip(icon: Icons.insights_rounded, label: delta),
              GlassChip(icon: Icons.lock_rounded, label: 'On this phone'),
            ]),
            const SizedBox(height: 14),
            if (s != null)
              HeroTrendChart(daily: s.daily, previous: s.previousDaily, month: month)
            else
              const SizedBox(height: 150),
            const SizedBox(height: 4),
            Row(children: [
              _Legend(color: Colors.white, label: DateFormat.MMMM().format(month)),
              const SizedBox(width: 14),
              _Legend(color: Colors.white.withAlpha(110), label: DateFormat.MMMM().format(DateTime(month.year, month.month - 1)), dashed: true),
            ]),
          ]),
        ),
      ),
    );
  }

  static String _short(int paise) {
    final r = paise / 100;
    if (r >= 100000) return '₹${(r / 100000).toStringAsFixed(r >= 1000000 ? 0 : 1)}L';
    if (r >= 1000) return '₹${(r / 1000).toStringAsFixed(r >= 10000 ? 0 : 1)}k';
    return '₹${r.round()}';
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label, this.dashed = false});
  final Color color;
  final String label;
  final bool dashed;

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 14, height: dashed ? 1.6 : 2.6, color: color),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: Colors.white.withAlpha(170), fontSize: 12)),
      ]);
}

/// The app mark: a ₹ in a brand-gradient squircle.
class _Logo extends StatelessWidget {
  const _Logo();
  @override
  Widget build(BuildContext context) => Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          gradient: Brand.gradient,
          borderRadius: BorderRadius.circular(11),
          boxShadow: Brand.glow(80),
          border: Border.all(color: Colors.white.withAlpha(50)),
        ),
        alignment: Alignment.center,
        child: const Text('₹', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
      );
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.icon, required this.color, required this.title, required this.value, required this.caption});
  final IconData icon;
  final Color color;
  final String title;
  final String value;
  final String caption;

  factory _StatCard.budget(BuildContext context, List<BudgetStatus> budgets) {
    final over = budgets.where((b) => b.level == BudgetLevel.over).length;
    final warn = budgets.where((b) => b.level == BudgetLevel.warning).length;
    final k = context.k;
    if (budgets.isEmpty) {
      return _StatCard(icon: Icons.savings_rounded, color: Brand.mid, title: 'Budgets', value: 'None set', caption: 'Add one in Insights');
    }
    return _StatCard(
      icon: over > 0 ? Icons.error_rounded : warn > 0 ? Icons.warning_rounded : Icons.check_circle_rounded,
      color: over > 0 ? k.negative : warn > 0 ? k.caution : k.positive,
      title: 'Budgets',
      value: over > 0 ? '$over over' : warn > 0 ? '$warn near limit' : 'On track',
      caption: '${budgets.length} categor${budgets.length == 1 ? 'y' : 'ies'} this month',
    );
  }

  factory _StatCard.upcoming(BuildContext context, List<RecurringPayment> recurring, DateTime now) {
    final next = recurring.where((r) => !r.nextExpected.isBefore(DateTime(now.year, now.month, now.day))).firstOrNull;
    if (next == null) {
      return const _StatCard(
          icon: Icons.autorenew_rounded, color: Brand.violet, title: 'Recurring', value: 'None found', caption: 'Needs 3 or more payments');
    }
    final days = next.nextExpected.difference(DateTime(now.year, now.month, now.day)).inDays;
    return _StatCard(
      icon: Icons.event_repeat_rounded,
      color: Brand.violet,
      title: 'Next recurring',
      value: next.merchant,
      caption: '${_rupees(next.typicalPaise)} ${days == 0 ? 'today' : days == 1 ? 'tomorrow' : 'in $days days'}',
    );
  }

  static String _rupees(int p) => '₹${NumberFormat.decimalPattern('en_IN').format(p ~/ 100)}';

  @override
  Widget build(BuildContext context) => Surface(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            IconTile(icon, color: color, size: 30),
            const SizedBox(width: 8),
            Flexible(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: KText.caption(context))),
          ]),
          const SizedBox(height: 12),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: KText.headline(context).copyWith(fontSize: 17)),
          const SizedBox(height: 2),
          Text(caption, maxLines: 1, overflow: TextOverflow.ellipsis, style: KText.caption(context).copyWith(fontSize: 12)),
        ]),
      );
}

/// A budget line: icon, name, "₹spent of ₹limit", coloured track.
class BudgetRow extends StatelessWidget {
  const BudgetRow({super.key, required this.status, this.onTap});
  final BudgetStatus status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final c = status.budget.category;
    final color = switch (status.level) {
      BudgetLevel.over => k.negative,
      BudgetLevel.warning => k.caution,
      BudgetLevel.ok => CategoryVisuals.color(c),
    };
    final fmt = NumberFormat.decimalPattern('en_IN');
    final body = Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        IconTile(CategoryVisuals.icon(c), color: CategoryVisuals.color(c), size: 36),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(c, style: KText.headline(context).copyWith(fontSize: 15))),
              Text('${status.percent}%',
                  style: KText.amount(context, size: 14, color: status.level == BudgetLevel.ok ? k.secondaryLabel : color)),
            ]),
            const SizedBox(height: 6),
            ProgressTrack(value: status.ratio, color: color),
            const SizedBox(height: 5),
            Text(
              '₹${fmt.format(status.spentPaise ~/ 100)} of ₹${fmt.format(status.budget.limitPaise ~/ 100)}'
              '${status.remainingPaise >= 0 ? ' · ₹${fmt.format(status.remainingPaise ~/ 100)} left' : ' · ₹${fmt.format(-status.remainingPaise ~/ 100)} over'}',
              style: KText.caption(context).copyWith(fontSize: 12),
            ),
          ]),
        ),
      ]),
    );
    return onTap == null ? body : InkWell(onTap: onTap, borderRadius: BorderRadius.circular(Radii.control), child: body);
  }
}

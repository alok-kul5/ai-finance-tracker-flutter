import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../domain/models.dart';
import '../state/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/txn_tile.dart';
import '../widgets/ui.dart';
import 'sheets.dart';

class ActivityTab extends ConsumerStatefulWidget {
  const ActivityTab({super.key});

  @override
  ConsumerState<ActivityTab> createState() => _ActivityTabState();
}

class _ActivityTabState extends ConsumerState<ActivityTab> {
  final _search = TextEditingController();
  String _query = '';
  String? _category;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final all = ref.watch(txnsProvider).value ?? const <Txn>[];
    final now = ref.watch(clockProvider)();
    final q = _query.toLowerCase();
    final list = [
      for (final t in all)
        if ((_category == null || t.category == _category) &&
            (q.isEmpty || t.merchant.toLowerCase().contains(q) || t.category.toLowerCase().contains(q) || (t.note ?? '').toLowerCase().contains(q)))
          t
    ];
    final groups = <String, List<Txn>>{};
    for (final t in list) {
      groups.putIfAbsent(dayLabel(t.occurredAt, now), () => []).add(t);
    }
    final used = {for (final t in all) t.category};

    return CustomScrollView(slivers: [
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 16, 20, 12),
          child: Text('Activity', style: KText.largeTitle(context)),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _search,
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Search merchants, categories',
              prefixIcon: const Icon(Icons.search_rounded),
              fillColor: k.surface,
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear',
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => setState(() {
                        _search.clear();
                        _query = '';
                      }),
                    ),
            ),
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            children: [
              _Filter(label: 'All', selected: _category == null, onTap: () => setState(() => _category = null)),
              for (final c in kCategories)
                if (used.contains(c))
                  _Filter(
                    label: c,
                    color: CategoryVisuals.color(c),
                    selected: _category == c,
                    onTap: () => setState(() => _category = _category == c ? null : c),
                  ),
            ],
          ),
        ),
      ),
      if (list.isEmpty)
        SliverToBoxAdapter(
          child: EmptyState(
            icon: Icons.search_off_rounded,
            title: all.isEmpty ? 'No transactions yet' : 'No matches',
            message: all.isEmpty ? 'Tap + to add your first one.' : 'Try another search or category.',
          ),
        ),
      for (final e in groups.entries) ...[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
            child: Row(children: [
              Expanded(child: Text(e.key, style: KText.caption(context).copyWith(fontWeight: FontWeight.w600))),
              Text(
                _sum(e.value),
                style: KText.caption(context).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
              ),
            ]),
          ),
        ),
        SliverList.builder(
          itemCount: e.value.length,
          itemBuilder: (context, i) {
            final t = e.value[i];
            return TxnTile(
              key: ValueKey(t.id),
              txn: t,
              position: GroupPosition.of(i, e.value.length),
              onTap: () => showKSheet(context, TxnDetailSheet(txn: t)),
              onDelete: () async {
                await ref.read(storeProvider).deleteTxn(t.id);
                if (context.mounted) showSnack(context, 'Deleted ${t.merchant}');
              },
            );
          },
        ),
      ],
      SliverToBoxAdapter(child: SizedBox(height: bottomClearance(context))),
    ]);
  }

  static String _sum(List<Txn> ts) {
    final spent = ts.where((t) => t.isDebit).fold(0, (s, t) => s + t.amountPaise);
    if (spent == 0) return '';
    final r = spent ~/ 100;
    final s = r.toString();
    final grouped = s.length <= 3
        ? s
        : '${s.substring(0, s.length - 3).replaceAllMapped(RegExp(r'(\d)(?=(\d{2})+$)'), (m) => '${m[1]},')},${s.substring(s.length - 3)}';
    return '−₹$grouped';
  }
}

class _Filter extends StatelessWidget {
  const _Filter({required this.label, required this.selected, required this.onTap, this.color});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Pressable(
        onTap: onTap,
        scale: 0.95,
        child: AnimatedContainer(
          duration: Motion.medium,
          curve: Motion.signature,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: selected ? Brand.gradient : null,
            color: selected ? null : k.surface,
            borderRadius: BorderRadius.circular(99),
            boxShadow: selected ? Brand.glow(50) : null,
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (color != null && !selected) ...[
              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 6),
            ],
            Text(label,
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: selected ? Colors.white : k.ink)),
          ]),
        ),
      ),
    );
  }
}

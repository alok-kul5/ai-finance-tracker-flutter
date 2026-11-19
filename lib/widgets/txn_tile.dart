import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../domain/models.dart';
import '../theme/app_theme.dart';
import 'ui.dart';

/// One transaction in a grouped list: category icon, merchant, how it got
/// here (SMS / receipt / manual, and who picked the category), amount.
class TxnTile extends StatelessWidget {
  const TxnTile({super.key, required this.txn, this.onTap, this.onDelete, this.position = GroupPosition.single, this.showDate = false});

  final Txn txn;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final GroupPosition position;
  final bool showDate;

  static String sourceLabel(Txn t) {
    final via = switch (t.source) {
      TxnSource.sms => 'SMS',
      TxnSource.receipt => 'Receipt',
      TxnSource.manual => 'Manual',
    };
    final by = switch (t.categorySource) {
      'llm' => ' · sorted by Gemma',
      'memory' => ' · remembered',
      'user' => ' · you',
      _ => '',
    };
    return '$via$by';
  }

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final color = CategoryVisuals.color(txn.category);
    final when = DateFormat(showDate ? 'd MMM, h:mm a' : 'h:mm a').format(txn.occurredAt);
    final credit = !txn.isDebit;
    final row = Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
      child: Row(children: [
        IconTile(CategoryVisuals.icon(txn.category), color: color, size: 42, circle: true),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(txn.merchant, maxLines: 1, overflow: TextOverflow.ellipsis, style: KText.headline(context)),
            const SizedBox(height: 2),
            Text('${txn.category} · $when', maxLines: 1, overflow: TextOverflow.ellipsis, style: KText.caption(context)),
          ]),
        ),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          MoneyText(txn.amountPaise,
              prefix: credit ? '+' : '',
              style: KText.amount(context, size: 16, color: credit ? k.positive : k.ink)),
          const SizedBox(height: 3),
          Text(sourceLabel(txn), style: KText.caption(context).copyWith(fontSize: 11, color: k.tertiaryLabel)),
        ]),
      ]),
    );

    Widget tile = Material(
      color: k.surface,
      borderRadius: position.radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(children: [
          row,
          if (position.hasDivider) Padding(padding: const EdgeInsets.only(left: 68), child: Divider(height: 0.5, thickness: 0.5, color: k.separator)),
        ]),
      ),
    );
    if (onDelete != null) {
      tile = Dismissible(
        key: ValueKey('dismiss-${txn.id}'),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onDelete!(),
        background: Container(
          decoration: BoxDecoration(color: k.negative, borderRadius: position.radius),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
        ),
        child: tile,
      );
    }
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Pressable(child: tile));
  }
}

/// A date heading over a group of rows ("Today", "Yesterday", "Mon 11 Mar").
String dayLabel(DateTime d, DateTime now) {
  final day = DateTime(d.year, d.month, d.day);
  final today = DateTime(now.year, now.month, now.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  return DateFormat(d.year == now.year ? 'EEE d MMM' : 'd MMM yyyy').format(d);
}

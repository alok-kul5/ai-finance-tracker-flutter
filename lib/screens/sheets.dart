import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../domain/models.dart';
import '../domain/money.dart';
import '../parsing/receipt_parser.dart';
import '../state/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/txn_tile.dart';
import '../widgets/ui.dart';

void showSnack(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}

Future<T?> showKSheet<T>(BuildContext context, Widget child) => showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: child,
      ),
    );

/// The add menu behind the tab bar's + button.
class AddMenuSheet extends ConsumerWidget {
  const AddMenuSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final services = ref.watch(servicesProvider);
    Widget option(IconData icon, Color color, String title, String sub, VoidCallback? onTap) => Surface(
          color: context.k.page,
          onTap: onTap,
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            IconTile(icon, color: color, size: 44),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: KText.headline(context)),
                const SizedBox(height: 2),
                Text(sub, style: KText.caption(context)),
              ]),
            ),
            Icon(Icons.chevron_right_rounded, color: context.k.tertiaryLabel),
          ]),
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Add spending', style: KText.title(context)),
        const SizedBox(height: 16),
        option(Icons.document_scanner_rounded, Brand.violet, 'Scan a receipt',
            services.scanner.supported ? 'On-device text recognition, nothing uploaded' : 'Available in the Android app',
            services.scanner.supported ? () => Navigator.pop(context, 'scan') : null),
        option(Icons.sms_rounded, const Color(0xff28a745), 'Import bank SMS',
            services.sms.supported ? 'Reads UPI and bank alerts on this phone' : 'Available in the Android app',
            services.sms.supported ? () => Navigator.pop(context, 'sms') : null),
        option(Icons.edit_note_rounded, Brand.blue, 'Enter manually', 'Amount, merchant, date', () => Navigator.pop(context, 'manual')),
      ]),
    );
  }
}

/// Category chooser: a grid of the fixed categories.
class CategoryPicker extends StatelessWidget {
  const CategoryPicker({super.key, required this.selected, required this.onPicked});
  final String? selected;
  final ValueChanged<String> onPicked;

  @override
  Widget build(BuildContext context) => Wrap(spacing: 8, runSpacing: 8, children: [
        for (final c in kCategories)
          Pressable(
            onTap: () => onPicked(c),
            scale: 0.95,
            child: AnimatedContainer(
              duration: Motion.medium,
              curve: Motion.signature,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: c == selected ? CategoryVisuals.color(c).withAlpha(context.isDark ? 70 : 38) : context.k.page,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: c == selected ? CategoryVisuals.color(c) : Colors.transparent, width: 1.5),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(CategoryVisuals.icon(c), size: 16, color: CategoryVisuals.color(c)),
                const SizedBox(width: 6),
                Text(c, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: context.k.ink)),
              ]),
            ),
          ),
      ]);
}

/// Add or edit a transaction. With [receipt] the fields come pre-filled
/// from OCR and the user confirms.
class TxnEditorSheet extends ConsumerStatefulWidget {
  const TxnEditorSheet({super.key, this.existing, this.receipt, this.ocrText});
  final Txn? existing;
  final ParsedReceipt? receipt;
  final String? ocrText;

  @override
  ConsumerState<TxnEditorSheet> createState() => _TxnEditorSheetState();
}

class _TxnEditorSheetState extends ConsumerState<TxnEditorSheet> {
  late final _amount = TextEditingController(
      text: widget.existing != null
          ? formatPaise(widget.existing!.amountPaise, symbol: false).replaceAll(',', '')
          : widget.receipt?.totalPaise != null
              ? formatPaise(widget.receipt!.totalPaise!, symbol: false).replaceAll(',', '')
              : '');
  late final _merchant = TextEditingController(text: widget.existing?.merchant ?? widget.receipt?.merchant ?? '');
  late DateTime _date = widget.existing?.occurredAt ?? widget.receipt?.date ?? ref.read(clockProvider)();
  late String? _category = widget.existing?.category;
  late TxnDirection _dir = widget.existing?.direction ?? TxnDirection.debit;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _merchant.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    int paise;
    try {
      paise = parseRupeesToPaise(_amount.text);
    } on FormatException {
      setState(() => _error = 'Enter an amount like 249 or 249.50');
      return;
    }
    if (paise <= 0 || _merchant.text.trim().isEmpty) {
      setState(() => _error = paise <= 0 ? 'The amount must be more than zero' : 'Add who you paid');
      return;
    }
    setState(() => _saving = true);
    final ingest = ref.read(ingestorProvider);
    final e = widget.existing;
    if (e != null) {
      final store = ref.read(storeProvider);
      final updated = e.copyWith(amountPaise: paise, merchant: _merchant.text.trim(), occurredAt: _date);
      if (_category != null && _category != e.category) {
        await ingest.recategorize(updated, _category!);
      } else {
        await store.saveTxn(updated);
      }
    } else {
      await ingest.addManual(
        amountPaise: paise,
        direction: _dir,
        merchant: _merchant.text.trim(),
        occurredAt: _date,
        category: _category,
        source: widget.receipt != null ? TxnSource.receipt : TxnSource.manual,
      );
    }
    await ref.read(budgetWatcherProvider).check(ref.read(clockProvider)());
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final editing = widget.existing != null;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(editing ? 'Edit transaction' : widget.receipt != null ? 'Check the receipt' : 'New transaction', style: KText.title(context)),
        if (widget.receipt != null) ...[
          const SizedBox(height: 6),
          Text('Read on this phone with ML Kit. Fix anything it got wrong.', style: KText.caption(context)),
        ],
        const SizedBox(height: 18),
        if (!editing)
          SegmentedButton<TxnDirection>(
            segments: const [
              ButtonSegment(value: TxnDirection.debit, label: Text('Spent'), icon: Icon(Icons.north_east_rounded, size: 16)),
              ButtonSegment(value: TxnDirection.credit, label: Text('Received'), icon: Icon(Icons.south_west_rounded, size: 16)),
            ],
            selected: {_dir},
            onSelectionChanged: (s) => setState(() => _dir = s.first),
          ),
        const SizedBox(height: 14),
        TextField(
          controller: _amount,
          autofocus: !editing && widget.receipt == null,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: KText.amount(context, size: 28),
          decoration: const InputDecoration(prefixText: '₹ ', hintText: '0.00'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _merchant,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Merchant or person', prefixIcon: Icon(Icons.storefront_rounded)),
        ),
        const SizedBox(height: 10),
        Surface(
          color: context.isDark ? k.surfaceRaised : k.page,
          radius: BorderRadius.circular(14),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          onTap: () async {
            final d = await showDatePicker(
                context: context, initialDate: _date, firstDate: DateTime(2015), lastDate: DateTime.now().add(const Duration(days: 1)));
            if (d != null) setState(() => _date = DateTime(d.year, d.month, d.day, _date.hour, _date.minute));
          },
          child: Row(children: [
            Icon(Icons.calendar_today_rounded, size: 18, color: k.secondaryLabel),
            const SizedBox(width: 12),
            Text(DateFormat('EEE, d MMM yyyy').format(_date), style: KText.body(context)),
          ]),
        ),
        const SizedBox(height: 18),
        Text(_category == null && !editing ? 'Category (leave empty to auto-sort)' : 'Category', style: KText.caption(context)),
        const SizedBox(height: 10),
        CategoryPicker(selected: _category, onPicked: (c) => setState(() => _category = c == _category && !editing ? null : c)),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: TextStyle(color: k.negative, fontWeight: FontWeight.w500)),
        ],
        if (widget.ocrText != null) ...[
          const SizedBox(height: 14),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text('Recognised text', style: KText.caption(context)),
              children: [Text(widget.ocrText!, style: KText.caption(context).copyWith(fontFamily: 'monospace'))],
            ),
          ),
        ],
        const SizedBox(height: 22),
        GradientButton(label: editing ? 'Save changes' : 'Add', icon: Icons.check_rounded, busy: _saving, expand: true, onPressed: _save),
      ]),
    );
  }
}

/// Details of one transaction, with re-categorise and delete.
class TxnDetailSheet extends ConsumerWidget {
  const TxnDetailSheet({super.key, required this.txn});
  final Txn txn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final k = context.k;
    Widget row(String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(children: [
            Expanded(child: Text(label, style: KText.caption(context))),
            Flexible(child: Text(value, textAlign: TextAlign.right, style: KText.body(context))),
          ]),
        );
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          IconTile(CategoryVisuals.icon(txn.category), color: CategoryVisuals.color(txn.category), size: 52, circle: true),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(txn.merchant, style: KText.title(context)),
              Text(DateFormat('EEE d MMM yyyy, h:mm a').format(txn.occurredAt), style: KText.caption(context)),
            ]),
          ),
        ]),
        const SizedBox(height: 18),
        MoneyText(txn.amountPaise,
            prefix: txn.isDebit ? '' : '+', style: KText.amount(context, size: 36, color: txn.isDebit ? k.ink : k.positive)),
        const SizedBox(height: 14),
        row('Source', TxnTile.sourceLabel(txn)),
        if (txn.account != null) row('Account', txn.account!),
        if (txn.reference != null) row('Reference', txn.reference!),
        if (txn.note != null) row('Note', txn.note!),
        const SizedBox(height: 14),
        Text('Category: tap to re-file. Kharcha remembers it for this merchant.', style: KText.caption(context)),
        const SizedBox(height: 10),
        CategoryPicker(
          selected: txn.category,
          onPicked: (c) async {
            await ref.read(ingestorProvider).recategorize(txn, c);
            if (context.mounted) Navigator.pop(context);
          },
        ),
        const SizedBox(height: 22),
        Row(children: [
          Expanded(
            child: SoftButton(
              label: 'Edit',
              icon: Icons.edit_rounded,
              onPressed: () {
                Navigator.pop(context);
                showKSheet(context, TxnEditorSheet(existing: txn));
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Pressable(
              onTap: () async {
                await ref.read(storeProvider).deleteTxn(txn.id);
                if (context.mounted) Navigator.pop(context);
              },
              child: Container(
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: k.negative.withAlpha(28), borderRadius: BorderRadius.circular(22)),
                child: Text('Delete', style: TextStyle(color: k.negative, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ]),
      ]),
    );
  }
}

/// Set or remove a monthly budget for one category.
class BudgetEditorSheet extends ConsumerStatefulWidget {
  const BudgetEditorSheet({super.key, this.category, this.limitPaise});
  final String? category;
  final int? limitPaise;

  @override
  ConsumerState<BudgetEditorSheet> createState() => _BudgetEditorSheetState();
}

class _BudgetEditorSheetState extends ConsumerState<BudgetEditorSheet> {
  late String? _category = widget.category;
  late final _limit = TextEditingController(
      text: widget.limitPaise == null ? '' : formatPaise(widget.limitPaise!, symbol: false, decimals: false).replaceAll(',', ''));

  @override
  void dispose() {
    _limit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.read(storeProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(widget.category == null ? 'New budget' : '${widget.category} budget', style: KText.title(context)),
        const SizedBox(height: 6),
        Text('You get a notification at 80% and at 100% each month.', style: KText.caption(context)),
        const SizedBox(height: 16),
        if (widget.category == null) ...[
          CategoryPicker(selected: _category, onPicked: (c) => setState(() => _category = c)),
          const SizedBox(height: 16),
        ],
        TextField(
          controller: _limit,
          autofocus: widget.category != null,
          keyboardType: TextInputType.number,
          style: KText.amount(context, size: 26),
          decoration: const InputDecoration(prefixText: '₹ ', hintText: 'Monthly limit', suffixText: '/ month'),
        ),
        const SizedBox(height: 20),
        GradientButton(
          label: 'Save budget',
          icon: Icons.check_rounded,
          expand: true,
          onPressed: () async {
            final c = _category;
            int paise;
            try {
              paise = parseRupeesToPaise(_limit.text);
            } on FormatException {
              return;
            }
            if (c == null || paise <= 0) return;
            await store.saveBudget(Budget(category: c, limitPaise: paise));
            await ref.read(budgetWatcherProvider).check(ref.read(clockProvider)());
            if (context.mounted) Navigator.pop(context);
          },
        ),
        if (widget.category != null) ...[
          const SizedBox(height: 10),
          TextButton(
            onPressed: () async {
              await store.deleteBudget(widget.category!);
              if (context.mounted) Navigator.pop(context);
            },
            child: Text('Remove budget', style: TextStyle(color: context.k.negative)),
          ),
        ],
      ]),
    );
  }
}

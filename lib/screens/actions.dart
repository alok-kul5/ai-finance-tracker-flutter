import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../parsing/receipt_parser.dart';
import '../services/ingest.dart';
import '../state/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';
import 'sheets.dart';

/// Flows started from the + button and from Settings.
abstract final class AppActions {
  static Future<void> openAddMenu(BuildContext context, WidgetRef ref) async {
    final choice = await showKSheet<String>(context, const AddMenuSheet());
    if (!context.mounted || choice == null) return;
    switch (choice) {
      case 'scan':
        await scanReceipt(context, ref);
      case 'sms':
        await importSms(context, ref);
      case 'manual':
        await showKSheet(context, const TxnEditorSheet());
    }
  }

  static Future<void> scanReceipt(BuildContext context, WidgetRef ref) async {
    final camera = await showKSheet<bool>(
      context,
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Scan a receipt', style: KText.title(context)),
          const SizedBox(height: 16),
          GradientButton(label: 'Take a photo', icon: Icons.photo_camera_rounded, expand: true, onPressed: () => Navigator.pop(context, true)),
          const SizedBox(height: 10),
          Center(child: SoftButton(label: 'Choose from gallery', icon: Icons.photo_library_rounded, onPressed: () => Navigator.pop(context, false))),
        ]),
      ),
    );
    if (camera == null || !context.mounted) return;
    String? text;
    try {
      text = await ref.read(servicesProvider).scanner.scan(camera: camera);
    } catch (e) {
      if (context.mounted) showSnack(context, 'Could not read the photo: $e');
      return;
    }
    if (text == null || !context.mounted) return;
    final parsed = const ReceiptParser().parse(text, now: ref.read(clockProvider)());
    if (parsed.isEmpty) showSnack(context, 'No total found. Fill it in below.');
    await showKSheet(context, TxnEditorSheet(receipt: parsed, ocrText: text));
  }

  static Future<void> importSms(BuildContext context, WidgetRef ref) async {
    final services = ref.read(servicesProvider);
    final store = ref.read(storeProvider);
    if (!await services.sms.hasPermission()) {
      if (!context.mounted) return;
      final ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          icon: const Icon(Icons.sms_rounded, color: Brand.mid),
          title: const Text('Read bank SMS?'),
          content: const Text(
            'Kharcha reads your inbox to find UPI and bank transaction alerts '
            '(debited, credited, spent). Messages are parsed on this phone and never '
            'leave it. OTPs, offers and personal messages are skipped and not stored.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Not now')),
            FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Allow')),
          ],
        ),
      );
      if (ok != true) return;
      if (!await services.sms.requestPermission()) {
        if (context.mounted) showSnack(context, 'SMS permission was not granted.');
        return;
      }
    }
    final lastRaw = await store.getValue(Ingestor.lastScanKey);
    final since = lastRaw == null ? DateTime.now().subtract(const Duration(days: 120)) : DateTime.tryParse(lastRaw);
    final msgs = await services.sms.read(since: since);
    final report = await ref.read(ingestorProvider).importSms(msgs);
    await store.setValue(Ingestor.lastScanKey, DateTime.now().toIso8601String());
    await ref.read(budgetWatcherProvider).check(ref.read(clockProvider)());
    if (context.mounted) {
      showSnack(
          context,
          report.added == 0
              ? 'No new transactions in ${report.read} messages.'
              : 'Added ${report.added} transaction${report.added == 1 ? '' : 's'}'
                  '${report.duplicates > 0 ? ', skipped ${report.duplicates} duplicates' : ''}.');
    }
  }

  static Future<void> syncNow(BuildContext context, WidgetRef ref) async {
    final engine = ref.read(syncEngineProvider);
    if (engine == null) return;
    try {
      final r = await engine.sync();
      if (context.mounted) showSnack(context, 'Synced: ${r.pushed} up, ${r.pulled} down.');
    } catch (e) {
      if (context.mounted) showSnack(context, 'Sync failed, will retry: $e');
    }
  }
}

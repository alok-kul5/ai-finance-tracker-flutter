import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../platform/services.dart';
import '../state/providers.dart';
import '../sync/supabase_remote.dart';
import '../theme/app_theme.dart';
import '../widgets/card_art.dart';
import '../widgets/ui.dart';
import 'actions.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _token = TextEditingController();
  final _url = TextEditingController(text: kGemmaModelUrl);

  @override
  void dispose() {
    _token.dispose();
    _url.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final services = ref.watch(servicesProvider);
    final model = ref.watch(modelProvider);
    final theme = ref.watch(themeModeProvider);
    final txns = ref.watch(txnsProvider).value ?? const [];
    final sync = ref.watch(syncEngineProvider);

    Widget group(String title, List<Widget> children) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SectionHeader(title, padding: const EdgeInsets.fromLTRB(20, 24, 20, 8)),
          Surface(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
          ),
        ]);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + 32), children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Center(child: LedgerCardArt(width: 320, txnCount: txns.length)),
        ),
        group('Appearance', [
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.system, label: Text('System'), icon: Icon(Icons.brightness_auto_rounded, size: 16)),
              ButtonSegment(value: ThemeMode.light, label: Text('Light'), icon: Icon(Icons.light_mode_rounded, size: 16)),
              ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode_rounded, size: 16)),
            ],
            selected: {theme},
            onSelectionChanged: (s) => ref.read(themeModeProvider.notifier).set(s.first),
          ),
        ]),
        group('On-device AI', [
          Row(children: [
            const IconTile(Icons.memory_rounded, color: Brand.violet),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(services.models.modelName, style: KText.headline(context)),
                Text(switch (model.state) {
                  ModelState.ready => 'Installed. Runs offline on this phone',
                  ModelState.downloading => 'Downloading… ${model.progress}%',
                  ModelState.notInstalled => 'Not downloaded (about 550 MB, once)',
                  ModelState.unsupported => 'Needs the Android app',
                  ModelState.error => model.error ?? 'Download failed',
                }, style: KText.caption(context)),
              ]),
            ),
          ]),
          if (model.state == ModelState.downloading) ...[
            const SizedBox(height: 12),
            ProgressTrack(value: model.progress / 100, color: Brand.mid),
          ],
          const SizedBox(height: 12),
          Text(
            'Gemma sorts transactions the rules are unsure about and reads your questions into a query. '
            'It never calculates totals. Without it, everything still works with rules.',
            style: KText.caption(context),
          ),
          if (model.state == ModelState.notInstalled || model.state == ModelState.error) ...[
            const SizedBox(height: 14),
            Text('Gemma is gated on Hugging Face: sign in there (free), accept the licence on the model page, '
                'and create a read token.',
                style: KText.caption(context)),
            const SizedBox(height: 10),
            TextField(controller: _token, obscureText: true, decoration: const InputDecoration(hintText: 'Hugging Face read token (hf_…)')),
            const SizedBox(height: 8),
            TextField(controller: _url, style: KText.caption(context), decoration: const InputDecoration(hintText: 'Model URL')),
            const SizedBox(height: 14),
            GradientButton(
              label: 'Download model',
              icon: Icons.download_rounded,
              expand: true,
              onPressed: () => ref.read(modelProvider.notifier).download(url: _url.text.trim(), token: _token.text.trim()),
            ),
          ],
          if (model.state == ModelState.ready) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => ref.read(modelProvider.notifier).remove(),
                child: Text('Remove model', style: TextStyle(color: k.negative)),
              ),
            ),
          ],
        ]),
        group('Bank SMS', [
          Text(
            'Reads UPI and bank alerts on this phone, skips OTPs and offers, and de-duplicates by reference number.',
            style: KText.caption(context),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: SoftButton(
              label: services.sms.supported ? 'Import new messages' : 'Android only',
              icon: Icons.sms_rounded,
              onPressed: services.sms.supported ? () => AppActions.importSms(context, ref) : null,
            ),
          ),
        ]),
        group('Cloud sync', [
          Row(children: [
            IconTile(sync == null ? Icons.cloud_off_rounded : Icons.cloud_done_rounded,
                color: sync == null ? k.secondaryLabel : k.positive),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                sync == null
                    ? 'Off. Kharcha keeps everything in a local database. Build with your own free Supabase project to sync.'
                    : 'On: Supabase, last write wins. Your data stays readable offline.',
                style: KText.caption(context),
              ),
            ),
          ]),
          if (sync != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: SoftButton(label: 'Sync now', icon: Icons.sync_rounded, onPressed: () => AppActions.syncNow(context, ref)),
            ),
          ],
          if (sync == null && SupabaseConfig.enabled) ...[
            const SizedBox(height: 8),
            Text('Supabase is configured but could not connect.', style: TextStyle(color: k.caution)),
          ],
        ]),
        group('Privacy', [
          Text(
            'No accounts, no ads, no analytics. SMS parsing, receipt OCR and the language model all run on this phone. '
            'Nothing is uploaded unless you turn on your own sync.',
            style: KText.caption(context),
          ),
        ]),
        const SizedBox(height: 16),
        Center(child: Text('Kharcha 1.0.1', style: KText.caption(context).copyWith(color: k.tertiaryLabel))),
      ]),
    );
  }
}

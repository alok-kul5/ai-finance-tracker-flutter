import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../ai/assistant.dart';
import '../platform/services.dart';
import '../state/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';
import 'settings_screen.dart';

const _suggestions = [
  'How much did I spend on food this month?',
  'Top merchants last month',
  'Biggest expense this year',
  'How many Uber rides in the last 30 days?',
  'Average grocery spend this month',
  'Breakdown by category last month',
];

class AskTab extends ConsumerStatefulWidget {
  const AskTab({super.key});

  @override
  ConsumerState<AskTab> createState() => _AskTabState();
}

class _AskTabState extends ConsumerState<AskTab> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  bool _busy = false;

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _ask(String q) async {
    if (q.trim().isEmpty || _busy) return;
    _input.clear();
    setState(() => _busy = true);
    await ref.read(chatProvider.notifier).ask(q);
    if (!mounted) return;
    setState(() => _busy = false);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (_scroll.hasClients) {
      _scroll.animateTo(_scroll.position.maxScrollExtent, duration: Motion.medium, curve: Motion.signature);
    }
  }

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final chat = ref.watch(chatProvider);
    final model = ref.watch(modelProvider);
    final top = MediaQuery.paddingOf(context).top;
    return Column(children: [
      Padding(
        padding: EdgeInsets.fromLTRB(20, top + 16, 12, 8),
        child: Row(children: [
          Expanded(child: Text('Ask', style: KText.largeTitle(context))),
          if (chat.isNotEmpty)
            IconButton(tooltip: 'Clear chat', onPressed: ref.read(chatProvider.notifier).clear, icon: const Icon(Icons.refresh_rounded)),
        ]),
      ),
      _ModelBanner(status: model),
      Expanded(
        child: chat.isEmpty
            ? ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 0), children: [
                Text('Ask about your spending in plain words. The model only works out what you are asking; '
                    'every number is calculated from your data on this phone.',
                    style: KText.caption(context).copyWith(fontSize: 14, height: 1.4)),
                const SizedBox(height: 16),
                for (final (i, s) in _suggestions.indexed)
                  FadeSlideIn(
                    index: i,
                    child: Surface(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                      onTap: () => _ask(s),
                      child: Row(children: [
                        const Icon(Icons.auto_awesome_rounded, size: 18, color: Brand.violet),
                        const SizedBox(width: 10),
                        Expanded(child: Text(s, style: KText.body(context))),
                        Icon(Icons.north_east_rounded, size: 16, color: k.tertiaryLabel),
                      ]),
                    ),
                  ),
              ])
            : ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: chat.length + (_busy ? 1 : 0),
                itemBuilder: (context, i) {
                  if (i == chat.length) {
                    return const Align(alignment: Alignment.centerLeft, child: Padding(padding: EdgeInsets.all(12), child: Spinner()));
                  }
                  final e = chat[i];
                  return FadeSlideIn(child: e.isUser ? _UserBubble(e.text) : _AnswerBubble(e.answer!));
                },
              ),
      ),
      Padding(
        padding: EdgeInsets.fromLTRB(16, 6, 16, bottomClearance(context) - 8),
        child: Row(children: [
          Expanded(
            child: TextField(
              controller: _input,
              textInputAction: TextInputAction.send,
              onSubmitted: _ask,
              decoration: InputDecoration(hintText: 'e.g. Swiggy last month', fillColor: k.surface),
            ),
          ),
          const SizedBox(width: 8),
          Semantics(
            button: true,
            label: 'Send',
            child: Pressable(
              onTap: () => _ask(_input.text),
              scale: 0.9,
              haptic: true,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(shape: BoxShape.circle, gradient: Brand.gradient, boxShadow: Brand.glow()),
                child: const Icon(Icons.arrow_upward_rounded, color: Colors.white),
              ),
            ),
          ),
        ]),
      ),
    ]);
  }
}

class _ModelBanner extends StatelessWidget {
  const _ModelBanner({required this.status});
  final ModelStatus status;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final (icon, color, text) = switch (status.state) {
      ModelState.ready => (Icons.memory_rounded, k.positive, 'Gemma 3 1B is running on this phone'),
      ModelState.downloading => (Icons.downloading_rounded, Brand.mid, 'Downloading Gemma… ${status.progress}%'),
      ModelState.unsupported => (Icons.rule_rounded, k.secondaryLabel, 'Demo build: questions are read by rules'),
      ModelState.error => (Icons.error_outline_rounded, k.negative, 'Model download failed. Using rules'),
      ModelState.notInstalled => (Icons.rule_rounded, k.caution, 'Using rules. Download Gemma for free-form questions'),
    };
    return Surface(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      onTap: status.state == ModelState.notInstalled || status.state == ModelState.error
          ? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()))
          : null,
      child: Row(children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: KText.caption(context).copyWith(color: k.ink))),
        if (status.state == ModelState.notInstalled) Icon(Icons.chevron_right_rounded, color: k.tertiaryLabel),
      ]),
    );
  }
}

class _UserBubble extends StatelessWidget {
  const _UserBubble(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(top: 10, left: 60),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: Brand.gradient,
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18), topRight: Radius.circular(18), bottomLeft: Radius.circular(18), bottomRight: Radius.circular(6)),
            boxShadow: Brand.glow(40),
          ),
          child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.35)),
        ),
      );
}

class _AnswerBubble extends StatelessWidget {
  const _AnswerBubble(this.a);
  final AssistantAnswer a;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final viaModel = a.intent.source == 'llm';
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(top: 10, right: 40),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
        decoration: BoxDecoration(
          color: k.surface,
          borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18), topRight: Radius.circular(18), bottomRight: Radius.circular(18), bottomLeft: Radius.circular(6)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(a.text, style: KText.body(context).copyWith(fontSize: 15.5)),
          const SizedBox(height: 10),
          Wrap(spacing: 6, runSpacing: 6, children: [
            _Tag(icon: viaModel ? Icons.memory_rounded : Icons.rule_rounded, label: viaModel ? 'Read by Gemma' : 'Read by rules', color: viaModel ? Brand.violet : k.secondaryLabel),
            _Tag(icon: Icons.calculate_rounded, label: 'Computed from ${a.result.count} txns', color: k.positive),
          ]),
          const SizedBox(height: 6),
          Text(SpendingAssistant.describe(a.intent.query), style: KText.caption(context).copyWith(fontSize: 11.5, color: k.tertiaryLabel)),
        ]),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: color.withAlpha(context.isDark ? 50 : 24), borderRadius: BorderRadius.circular(99)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: color)),
        ]),
      );
}

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'screens/activity_tab.dart';
import 'screens/actions.dart';
import 'screens/ask_tab.dart';
import 'screens/home_tab.dart';
import 'screens/insights_tab.dart';
import 'state/providers.dart';
import 'theme/app_theme.dart';
import 'widgets/ui.dart';

class KharchaApp extends ConsumerWidget {
  const KharchaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Kharcha',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: ref.watch(themeModeProvider),
      scrollBehavior: const KScrollBehavior(),
      home: const HomeShell(),
    );
  }
}

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key, this.initialTab = 0});
  final int initialTab;

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  late int _tab = widget.initialTab;

  static const _items = [
    GlassTabItem(icon: Icons.space_dashboard_rounded, label: 'Home'),
    GlassTabItem(icon: Icons.receipt_long_rounded, label: 'Activity'),
    GlassTabItem(icon: Icons.donut_small_rounded, label: 'Insights'),
    GlassTabItem(icon: Icons.auto_awesome_rounded, label: 'Ask'),
  ];

  @override
  Widget build(BuildContext context) {
    // The hero is dark, so Home gets light status-bar icons.
    final light = _tab == 0 || context.isDark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: (light ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark).copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        body: Stack(children: [
          FadeThroughStack(index: _tab, children: [
            HomeTab(onSeeAll: () => setState(() => _tab = 1)),
            const ActivityTab(),
            const InsightsTab(),
            const AskTab(),
          ]),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Center(
              child: GlassTabBar(
                items: _items,
                selectedIndex: _tab,
                onSelected: (i) => setState(() => _tab = i),
                onAdd: () => AppActions.openAddMenu(context, ref),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

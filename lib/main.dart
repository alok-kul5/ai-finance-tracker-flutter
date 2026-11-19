import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'platform/services.dart';
import 'state/providers.dart';
import 'sync/supabase_remote.dart';
import 'sync/sync_engine.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final services = createPlatformServices();
  final store = await services.openStore();
  try {
    await services.notifier.init();
  } catch (e) {
    debugPrint('notifications unavailable: $e');
  }

  // Sync only when the build was given a Supabase project. Any failure here
  // leaves the app fully working on its local database.
  SyncEngine? sync;
  if (SupabaseConfig.enabled) {
    try {
      sync = SyncEngine(store: store, remote: await SupabaseRemote.connect());
    } catch (e) {
      debugPrint('sync disabled: $e');
    }
  }

  runApp(ProviderScope(
    overrides: [
      servicesProvider.overrideWithValue(services),
      storeProvider.overrideWithValue(store),
      syncEngineProvider.overrideWithValue(sync),
    ],
    child: _Lifecycle(sync: sync, child: const KharchaApp()),
  ));
}

/// Syncs on launch, on resume and every few minutes while open; asks for
/// notification permission once.
class _Lifecycle extends ConsumerStatefulWidget {
  const _Lifecycle({required this.child, this.sync});
  final Widget child;
  final SyncEngine? sync;

  @override
  ConsumerState<_Lifecycle> createState() => _LifecycleState();
}

class _LifecycleState extends ConsumerState<_Lifecycle> with WidgetsBindingObserver {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _syncQuietly();
    if (widget.sync != null) {
      _timer = Timer.periodic(const Duration(minutes: 5), (_) => _syncQuietly());
    }
    Future(() async {
      final store = ref.read(storeProvider);
      if (await store.getValue('notif.asked') == null) {
        await store.setValue('notif.asked', '1');
        await ref.read(servicesProvider).notifier.requestPermission();
      }
      await ref.read(budgetWatcherProvider).check(DateTime.now());
    });
  }

  Future<void> _syncQuietly() async {
    try {
      await widget.sync?.sync();
    } catch (e) {
      if (kDebugMode) debugPrint('sync failed: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _syncQuietly();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

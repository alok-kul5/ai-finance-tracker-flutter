import '../ai/llm.dart';
import '../data/memory_store.dart';
import 'demo_data.dart';
import 'services.dart';

/// The browser build is a demo: in-memory data seeded with a realistic
/// month, and none of the phone-only features (SMS, camera OCR, Gemma).
PlatformServices createServices() => PlatformServices(
      sms: const _NoSms(),
      scanner: const _NoScanner(),
      notifier: const _NoNotifier(),
      models: const _NoModels(),
      openStore: () async => MemoryLedgerStore()..seed(txns: demoTxns(DateTime.now()), budgets: demoBudgets()),
      isDemo: true,
    );

class _NoSms implements SmsInbox {
  const _NoSms();
  @override
  bool get supported => false;
  @override
  Future<bool> hasPermission() async => false;
  @override
  Future<bool> requestPermission() async => false;
  @override
  Future<List<RawSms>> read({DateTime? since, int limit = 2000}) async => const [];
}

class _NoScanner implements ReceiptScanner {
  const _NoScanner();
  @override
  bool get supported => false;
  @override
  Future<String?> scan({required bool camera}) async => null;
}

class _NoNotifier implements LocalNotifier {
  const _NoNotifier();
  @override
  Future<void> init() async {}
  @override
  Future<bool> requestPermission() async => false;
  @override
  Future<void> show(int id, String title, String body) async {}
}

class _NoModels implements ModelManager {
  const _NoModels();
  @override
  bool get supported => false;
  @override
  String get modelName => 'Gemma 3 1B (int4)';
  @override
  Future<bool> isInstalled() async => false;
  @override
  Future<void> install({required String url, String? token, void Function(int percent)? onProgress}) async {}
  @override
  Future<void> installFromFile(String path) async {}
  @override
  Future<void> uninstall() async {}
  @override
  LlmClient get llm => const NoLlm();
}

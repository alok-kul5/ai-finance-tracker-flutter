/// Device features behind small interfaces, so the app (and its tests, and
/// the browser demo) run without them. The real implementations live in
/// native_services.dart; web_services.dart has the browser stand-ins.
library;

import '../ai/llm.dart';
import '../data/store.dart';

import 'web_services.dart' if (dart.library.io) 'native_services.dart' as impl;

class RawSms {
  const RawSms({required this.body, required this.sender, required this.receivedAt});
  final String body;
  final String sender;
  final DateTime receivedAt;
}

abstract interface class SmsInbox {
  bool get supported;
  Future<bool> hasPermission();
  Future<bool> requestPermission();

  /// Inbox messages, newest first, received after [since].
  Future<List<RawSms>> read({DateTime? since, int limit = 2000});
}

abstract interface class ReceiptScanner {
  bool get supported;

  /// Takes or picks a photo and returns the OCR text, or null if cancelled.
  Future<String?> scan({required bool camera});
}

abstract interface class LocalNotifier {
  Future<void> init();
  Future<bool> requestPermission();
  Future<void> show(int id, String title, String body);
}

enum ModelState { notInstalled, downloading, ready, unsupported, error }

/// The on-device model's lifecycle: download once (about 550 MB), then load
/// it from storage on every launch.
abstract interface class ModelManager {
  bool get supported;
  String get modelName;
  Future<bool> isInstalled();

  /// Downloads and activates the model, reporting 0–100.
  Future<void> install({required String url, String? token, void Function(int percent)? onProgress});
  Future<void> uninstall();
  LlmClient get llm;
}

class PlatformServices {
  const PlatformServices({
    required this.sms,
    required this.scanner,
    required this.notifier,
    required this.models,
    required this.openStore,
  });

  final SmsInbox sms;
  final ReceiptScanner scanner;
  final LocalNotifier notifier;
  final ModelManager models;
  final Future<LedgerStore> Function() openStore;
}

PlatformServices createPlatformServices() => impl.createServices();

/// Gemma 3 1B instruction-tuned, int4, as a MediaPipe `.task` (gated on
/// Hugging Face: accept the licence once, then use a free read token).
const kGemmaModelUrl =
    'https://huggingface.co/litert-community/Gemma3-1B-IT/resolve/main/gemma3-1b-it-int4.task';

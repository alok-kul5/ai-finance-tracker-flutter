import 'dart:io';

import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_edge_ai/flutter_edge_ai.dart';
import 'package:flutter_edge_ai_mediapipe/flutter_edge_ai_mediapipe.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' hide Message;
import 'package:flutter/services.dart' show MethodChannel;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart' hide ModelManager;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../ai/llm.dart';
import '../data/database.dart';
import '../data/drift_store.dart';
import 'services.dart';

PlatformServices createServices() {
  final models = GemmaModelManager();
  return PlatformServices(
    sms: _AndroidSmsInbox(),
    scanner: _MlKitScanner(),
    notifier: _Notifier(),
    models: models,
    openStore: () async => DriftLedgerStore(KharchaDatabase(driftDatabase(name: 'kharcha'))),
  );
}

class _AndroidSmsInbox implements SmsInbox {
  @override
  bool get supported => Platform.isAndroid;

  @override
  Future<bool> hasPermission() async => supported && await Permission.sms.isGranted;

  @override
  Future<bool> requestPermission() async =>
      supported && (await Permission.sms.request()).isGranted;

  @override
  Future<List<RawSms>> read({DateTime? since, int limit = 2000}) async {
    if (!await hasPermission()) return const [];
    final rows = await _channel.invokeListMethod<Map<Object?, Object?>>(
            'inbox', {'since': since?.millisecondsSinceEpoch ?? 0, 'limit': limit}) ??
        const [];
    return [
      for (final r in rows)
        if (r['body'] is String)
          RawSms(
            body: r['body']! as String,
            sender: (r['address'] as String?) ?? '',
            receivedAt: DateTime.fromMillisecondsSinceEpoch((r['date']! as num).toInt()),
          ),
    ];
  }

  /// Implemented in android/app/src/main/kotlin/.../MainActivity.kt.
  static const _channel = MethodChannel('kharcha/sms');
}

class _MlKitScanner implements ReceiptScanner {
  final _picker = ImagePicker();

  @override
  bool get supported => Platform.isAndroid || Platform.isIOS;

  @override
  Future<String?> scan({required bool camera}) async {
    final photo = await _picker.pickImage(
      source: camera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 2000,
      imageQuality: 90,
    );
    if (photo == null) return null;
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result = await recognizer.processImage(InputImage.fromFilePath(photo.path));
      return result.text;
    } finally {
      await recognizer.close();
    }
  }
}

class _Notifier implements LocalNotifier {
  final _plugin = FlutterLocalNotificationsPlugin();

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'budgets',
      'Budget alerts',
      channelDescription: 'When a category reaches 80% or 100% of its monthly budget',
      importance: Importance.high,
      priority: Priority.high,
    ),
  );

  @override
  Future<void> init() async {
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
  }

  @override
  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    return await android?.requestNotificationsPermission() ?? true;
  }

  @override
  Future<void> show(int id, String title, String body) =>
      _plugin.show(id: id, title: title, body: body, notificationDetails: _details);
}

/// Gemma 3 1B (int4, MediaPipe `.task`), run fully on the phone through
/// flutter_edge_ai. Nothing leaves the device.
class GemmaModelManager implements ModelManager {
  static const fileName = 'gemma3-1b-it-int4.task';
  static const defaultUrl = kGemmaModelUrl;

  bool _initialised = false;
  late final GemmaLlm _llm = GemmaLlm(this);

  Future<void> _init() async {
    if (_initialised) return;
    await FlutterEdgeAi.initialize(inferenceEngines: const [MediaPipeEngine()]);
    _initialised = true;
  }

  @override
  bool get supported => Platform.isAndroid || Platform.isIOS;

  @override
  String get modelName => 'Gemma 3 1B (int4)';

  @override
  LlmClient get llm => _llm;

  @override
  Future<bool> isInstalled() async {
    if (!supported) return false;
    await _init();
    return FlutterEdgeAi.isModelInstalled(fileName);
  }

  @override
  Future<void> install({required String url, String? token, void Function(int percent)? onProgress}) async {
    await _init();
    var b = FlutterEdgeAi.installModel(modelType: ModelType.gemmaIt, fileType: ModelFileType.task)
        .fromNetwork(url, token: token == null || token.isEmpty ? null : token, filename: fileName);
    if (onProgress != null) b = b.withProgress(onProgress);
    await b.install();
    _llm.reset();
  }

  @override
  Future<void> uninstall() async {
    await _init();
    await _llm.close();
    await FlutterEdgeAi.uninstallModel(fileName);
  }

  /// After a restart the file is still there but nothing is "active":
  /// installing again is idempotent and only re-activates it.
  Future<void> activate() async {
    await _init();
    await FlutterEdgeAi.installModel(modelType: ModelType.gemmaIt, fileType: ModelFileType.task)
        .fromNetwork(defaultUrl, filename: fileName)
        .install();
  }
}

class GemmaLlm implements LlmClient {
  GemmaLlm(this._manager);

  final GemmaModelManager _manager;
  InferenceModel? _model;
  Future<void> _queue = Future.value();

  void reset() => _model = null;

  Future<void> close() async {
    await _model?.close();
    _model = null;
  }

  @override
  Future<bool> get isReady => _manager.isInstalled();

  Future<InferenceModel> _load() async {
    final existing = _model;
    if (existing != null && !existing.isClosed) return existing;
    await _manager.activate();
    // CPU is the safe default for a 1B .task model on mid-range phones.
    return _model = await FlutterEdgeAi.getActiveModel(maxTokens: 1024, preferredBackend: PreferredBackend.cpu);
  }

  @override
  Future<String> complete(String prompt) {
    // One generation at a time: the model is a single shared resource.
    final result = _queue.then((_) => _run(prompt));
    _queue = result.then((_) {}, onError: (_) {});
    return result;
  }

  Future<String> _run(String prompt) async {
    final model = await _load();
    final chat = await model.openChat(temperature: 0.1, topK: 1, randomSeed: 7);
    try {
      await chat.addQueryChunk(Message.text(text: prompt, isUser: true));
      final response = await chat.generateChatResponse();
      return response is TextResponse ? response.token : '';
    } finally {
      await chat.close();
    }
  }
}

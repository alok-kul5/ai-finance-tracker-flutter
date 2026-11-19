/// The one seam between the app and a language model. The app ships with an
/// on-device Gemma implementation (gemma_llm.dart); tests use a fake.
library;

abstract interface class LlmClient {
  /// Whether a model is downloaded and can answer right now.
  Future<bool> get isReady;

  /// A single prompt-in, text-out completion. Implementations keep it short
  /// and deterministic (low temperature): the app only ever asks for a
  /// category name or a small JSON object.
  Future<String> complete(String prompt);
}

/// Used when no model is installed: never ready, so every caller takes its
/// rule-based path.
class NoLlm implements LlmClient {
  const NoLlm();
  @override
  Future<bool> get isReady async => false;
  @override
  Future<String> complete(String prompt) async =>
      throw StateError('No on-device model installed');
}

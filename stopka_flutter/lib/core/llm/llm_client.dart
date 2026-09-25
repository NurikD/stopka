import 'dart:typed_data';

/// Abstraction over the LLM provider. Every feature that needs AI calls this
/// interface, never a concrete provider — swapping Gemini for a proxied
/// backend later means changing one DI wire-up, not call sites.
abstract class LlmClient {
  Future<String> complete({
    required String systemPrompt,
    required String userMessage,
  });

  Future<String> completeWithImage({
    required String systemPrompt,
    required String userMessage,
    required Uint8List imageBytes,
    required String mimeType,
  });

  /// Cheap call used by the settings screen to validate a key without
  /// spending a full generation request.
  Future<bool> validateApiKey(String apiKey);
}

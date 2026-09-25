import 'dart:typed_data';

/// The kinds of AI request the server proxy knows. Each has its own prompt on
/// the server and its own daily limit.
enum AiKind {
  checkWriting,
  appeal,
  weakSpotDrill,
  enrichCards,
  recognizeWords,
  readUnitPage,
}

/// A request described by what it is, not by prompt text: the server builds
/// the prompt itself. [strict] asks for the stricter "JSON only" reminder on a
/// retry. Local clients ignore this and use the prompt they are given.
class AiRequest {
  final AiKind kind;
  final Map<String, Object?> params;
  final bool strict;

  const AiRequest(this.kind, this.params, {this.strict = false});
}

/// Abstraction over the LLM provider. Every feature that needs AI calls this
/// interface, never a concrete provider — swapping Gemini for a proxied
/// backend means changing one DI wire-up, not call sites.
abstract class LlmClient {
  Future<String> complete({
    required String systemPrompt,
    required String userMessage,
    AiRequest? request,
  });

  Future<String> completeWithImage({
    required String systemPrompt,
    required String userMessage,
    required Uint8List imageBytes,
    required String mimeType,
    AiRequest? request,
  });

  /// Cheap call used by the settings screen to validate a key without
  /// spending a full generation request.
  Future<bool> validateApiKey(String apiKey);
}

/// The level as the server accepts it: A1-B2, or empty when the value is
/// something else (a free-text course level, "не знаю").
String aiLevel(String level) =>
    const {'A1', 'A2', 'B1', 'B2'}.contains(level.trim().toUpperCase())
    ? level.trim().toUpperCase()
    : '';

import 'dart:typed_data';

import '../server/device_token_store.dart';
import 'api_key_store.dart';
import 'llm_client.dart';
import 'llm_exception.dart';

/// Where AI requests go, decided once at build time.
enum AiMode {
  /// Through the server proxy: no key on the phone.
  server,

  /// Straight to Gemini with the user's own key (a developer switch).
  direct,

  /// Neither: the app runs on its own.
  none,
}

AiMode chooseAiMode({
  required bool directGemini,
  required bool serverConfigured,
}) {
  if (directGemini) return AiMode.direct;
  return serverConfigured ? AiMode.server : AiMode.none;
}

/// Whether AI features can be used right now, so screens can say so honestly
/// instead of failing. Server mode needs the device token; direct mode a key.
class AiAvailability {
  final AiMode mode;
  final DeviceTokenStore _tokens;
  final ApiKeyStore _keys;

  AiAvailability(this.mode, this._tokens, this._keys);

  Future<bool> isAvailable() async {
    switch (mode) {
      case AiMode.server:
        return await _tokens.load() != null;
      case AiMode.direct:
        return _keys.hasKey();
      case AiMode.none:
        return false;
    }
  }
}

/// The client used when there is no way to reach an AI at all.
class UnavailableLlmClient implements LlmClient {
  @override
  Future<String> complete({
    required String systemPrompt,
    required String userMessage,
    AiRequest? request,
  }) {
    throw const LlmException('ИИ недоступен: нет связи с сервером.');
  }

  @override
  Future<String> completeWithImage({
    required String systemPrompt,
    required String userMessage,
    required Uint8List imageBytes,
    required String mimeType,
    AiRequest? request,
  }) {
    throw const LlmException('ИИ недоступен: нет связи с сервером.');
  }

  @override
  Future<bool> validateApiKey(String apiKey) async => false;
}

/// One sentence for screens to show when [AiAvailability.isAvailable] is false.
String aiUnavailableHint(AiMode mode) {
  return mode == AiMode.direct
      ? 'Добавьте ключ Gemini в «Профиле».'
      : 'Нет связи с сервером. Проверьте интернет и перезапустите приложение.';
}

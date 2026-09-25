// ignore_for_file: prefer_initializing_formals -- named params stay public while fields are private.
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

/// Why a provider call failed, in terms the proxy can act on.
enum ProviderFailure { overloaded, rateLimited, rejected, other }

class LlmProviderException implements Exception {
  final ProviderFailure failure;
  final int? statusCode;

  const LlmProviderException(this.failure, {this.statusCode});

  @override
  String toString() => 'LlmProviderException($failure, $statusCode)';
}

/// The AI provider behind the proxy. The proxy only knows this interface, so a
/// second provider is one more implementation.
abstract class LlmProvider {
  Future<String> complete({required String systemPrompt, required String userMessage});

  Future<String> completeWithImage({
    required String systemPrompt,
    required String userMessage,
    required Uint8List imageBytes,
    required String mimeType,
  });
}

/// Gemini over its public REST API, on the server's own (paid) key.
class GeminiProvider implements LlmProvider {
  static const _baseUrl = 'https://generativelanguage.googleapis.com/v1beta';

  final String _apiKey;
  final String _model;
  final http.Client _http;
  final List<Duration> _retryDelays;
  final Duration _timeout;

  GeminiProvider({
    required String apiKey,
    required String model,
    http.Client? client,
    List<Duration> retryDelays = const [Duration(seconds: 2), Duration(seconds: 5)],
    Duration timeout = const Duration(seconds: 60),
  })  : _apiKey = apiKey,
        _model = model,
        _http = client ?? http.Client(),
        _retryDelays = retryDelays,
        _timeout = timeout;

  @override
  Future<String> complete({required String systemPrompt, required String userMessage}) {
    return _post({
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': userMessage},
          ],
        },
      ],
      'systemInstruction': {
        'parts': [
          {'text': systemPrompt},
        ],
      },
    });
  }

  @override
  Future<String> completeWithImage({
    required String systemPrompt,
    required String userMessage,
    required Uint8List imageBytes,
    required String mimeType,
  }) {
    return _post({
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': userMessage},
            {
              'inline_data': {'mime_type': mimeType, 'data': base64Encode(imageBytes)},
            },
          ],
        },
      ],
      'systemInstruction': {
        'parts': [
          {'text': systemPrompt},
        ],
      },
    });
  }

  Future<String> _post(Map<String, Object?> body) async {
    for (var attempt = 0;; attempt++) {
      final http.Response response;
      try {
        response = await _http
            .post(
              Uri.parse('$_baseUrl/models/$_model:generateContent'),
              // The key goes in a header, not the URL, so it cannot end up in logs.
              headers: {'content-type': 'application/json', 'x-goog-api-key': _apiKey},
              body: jsonEncode(body),
            )
            .timeout(_timeout);
      } on Exception {
        throw const LlmProviderException(ProviderFailure.other);
      }

      final status = response.statusCode;
      if (status == 200) return _extractText(response.body);

      final transient = status == 500 || status == 502 || status == 503 || status == 504;
      if (transient && attempt < _retryDelays.length) {
        await Future<void>.delayed(_retryDelays[attempt]);
        continue;
      }
      if (transient) throw LlmProviderException(ProviderFailure.overloaded, statusCode: status);
      if (status == 429) throw LlmProviderException(ProviderFailure.rateLimited, statusCode: status);
      if (status == 400 || status == 401 || status == 403) {
        throw LlmProviderException(ProviderFailure.rejected, statusCode: status);
      }
      throw LlmProviderException(ProviderFailure.other, statusCode: status);
    }
  }

  static String _extractText(String responseBody) {
    try {
      final data = jsonDecode(responseBody) as Map<String, dynamic>;
      final candidates = data['candidates'] as List?;
      final parts = candidates?.first['content']?['parts'] as List?;
      final text = parts?.map((p) => p['text'] ?? '').join('');
      if (text == null || text.isEmpty) throw const FormatException('empty');
      return text;
    } on Object {
      throw const LlmProviderException(ProviderFailure.other);
    }
  }
}

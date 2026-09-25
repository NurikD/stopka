// ignore_for_file: prefer_initializing_formals -- named params stay public while fields are private.
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'api_key_store.dart';
import 'llm_client.dart';
import 'llm_exception.dart';

class GeminiLlmClient implements LlmClient {
  static const _baseUrl = 'https://generativelanguage.googleapis.com/v1beta';

  final ApiKeyStore _keyStore;
  final Dio _dio;

  /// Pauses before each retry of a transient server error (500/502/503/504).
  /// Gemini answers 503 "high demand" now and then; it usually passes within
  /// seconds, so a couple of patient retries hide it from the learner.
  final List<Duration> _retryDelays;

  GeminiLlmClient(
    this._keyStore, {
    Dio? dio,
    List<Duration> retryDelays = const [
      Duration(seconds: 2),
      Duration(seconds: 5),
    ],
  }) : _dio = dio ?? Dio(),
       _retryDelays = retryDelays;

  static bool _isTransient(int? status) =>
      status == 500 || status == 502 || status == 503 || status == 504;

  Future<String> _requireApiKey() async {
    final key = await _keyStore.getApiKey();
    if (key == null || key.isEmpty) {
      throw const LlmException(
        'Не задан ключ Gemini API. Добавьте его в настройках.',
      );
    }
    return key;
  }

  @override
  Future<String> complete({
    required String systemPrompt,
    required String userMessage,
    AiRequest? request,
  }) async {
    final key = await _requireApiKey();
    final model = await _keyStore.getModel();

    final body = {
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
    };

    return _post(model: model, key: key, body: body);
  }

  @override
  Future<String> completeWithImage({
    required String systemPrompt,
    required String userMessage,
    required Uint8List imageBytes,
    required String mimeType,
    AiRequest? request,
  }) async {
    final key = await _requireApiKey();
    final model = await _keyStore.getModel();

    final body = {
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': userMessage},
            {
              'inline_data': {
                'mime_type': mimeType,
                'data': base64Encode(imageBytes),
              },
            },
          ],
        },
      ],
      'systemInstruction': {
        'parts': [
          {'text': systemPrompt},
        ],
      },
    };

    return _post(model: model, key: key, body: body);
  }

  Future<String> _post({
    required String model,
    required String key,
    required Map<String, Object?> body,
  }) async {
    for (var attempt = 0; ; attempt++) {
      try {
        return await _postOnce(model: model, key: key, body: body);
      } on DioException catch (e) {
        if (_isTransient(e.response?.statusCode) &&
            attempt < _retryDelays.length) {
          await Future<void>.delayed(_retryDelays[attempt]);
          continue;
        }
        throw _mapDioError(e);
      }
    }
  }

  Future<String> _postOnce({
    required String model,
    required String key,
    required Map<String, Object?> body,
  }) async {
    final response = await _dio.post(
      '$_baseUrl/models/$model:generateContent',
      queryParameters: {'key': key},
      data: body,
    );
    final candidates = response.data['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      throw const LlmException('ИИ вернул пустой ответ. Попробуйте ещё раз.');
    }
    final parts = candidates.first['content']?['parts'] as List?;
    final text = parts?.map((p) => p['text'] ?? '').join('');
    if (text == null || text.isEmpty) {
      throw const LlmException('ИИ вернул пустой ответ. Попробуйте ещё раз.');
    }
    return text;
  }

  @override
  Future<bool> validateApiKey(String apiKey) async {
    try {
      await _dio.get('$_baseUrl/models', queryParameters: {'key': apiKey});
      return true;
    } on DioException catch (e) {
      if (e.response?.statusCode == 400 || e.response?.statusCode == 403) {
        return false;
      }
      throw _mapDioError(e);
    }
  }

  LlmException _mapDioError(DioException e) {
    final status = e.response?.statusCode;
    if (status == 429) {
      return const LlmException(
        'Достигнут лимит запросов к Gemini. Подождите немного и попробуйте снова.',
        isRateLimited: true,
      );
    }
    if (status == 400 || status == 403) {
      return const LlmException(
        'Неверный ключ Gemini API. Проверьте его в настройках.',
      );
    }
    if (status == null) {
      return const LlmException(
        'Нет соединения с интернетом. Проверьте сеть и попробуйте снова.',
      );
    }
    if (status == 503) {
      return const LlmException(
        'Сервис ИИ сейчас перегружен (код 503). Это временно — повторите через минуту.',
      );
    }
    return LlmException('Ошибка запроса к ИИ (код $status). Попробуйте позже.');
  }
}

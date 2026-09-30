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

  /// Longest pause the client sits out when Gemini says "too many requests
  /// this minute, retry in N s"; a longer one is reported instead.
  final Duration _maxRateLimitWait;
  final Future<void> Function(Duration) _wait;

  GeminiLlmClient(
    this._keyStore, {
    Dio? dio,
    List<Duration> retryDelays = const [
      Duration(seconds: 2),
      Duration(seconds: 5),
    ],
    Duration maxRateLimitWait = const Duration(seconds: 60),
    Future<void> Function(Duration)? wait,
  }) : _dio = dio ?? Dio(),
       _retryDelays = retryDelays,
       _maxRateLimitWait = maxRateLimitWait,
       _wait = wait ?? Future<void>.delayed;

  static bool _isTransient(int? status) =>
      status == 500 || status == 502 || status == 503 || status == 504;

  /// What a 429 says: a daily quota (then another model may still have one)
  /// or a per-minute one, and how long Gemini asks to wait.
  static ({bool daily, Duration? retryAfter}) _quotaOf(DioException e) {
    final data = e.response?.data;
    final text = data is String ? data : jsonEncode(data);
    final delay = RegExp(r'"retryDelay"\s*:\s*"(\d+)(?:\.\d+)?s"').firstMatch(text);
    return (
      daily: text.contains('PerDay'),
      retryAfter: delay == null ? null : Duration(seconds: int.parse(delay[1]!) + 1),
    );
  }

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

  /// Sends with the chosen [model] and, once its daily quota is used up, with
  /// each fallback model in turn: every model has its own free quota.
  Future<String> _post({
    required String model,
    required String key,
    required Map<String, Object?> body,
  }) async {
    final models = {model, ...fallbackGeminiModels}.toList();
    for (var i = 0; i < models.length; i++) {
      try {
        return await _postWithRetries(model: models[i], key: key, body: body);
      } on _DailyQuotaExhausted {
        if (i == models.length - 1) {
          throw const LlmException(
            'Дневной лимит бесплатного ключа Gemini исчерпан. Он обновится в полночь '
            'по тихоокеанскому времени (США). Диктант и повторение работают и без ИИ.',
            isRateLimited: true,
          );
        }
      }
    }
    throw StateError('unreachable');
  }

  Future<String> _postWithRetries({
    required String model,
    required String key,
    required Map<String, Object?> body,
  }) async {
    var waitedForRateLimit = false;
    for (var attempt = 0; ; attempt++) {
      try {
        return await _postOnce(model: model, key: key, body: body);
      } on DioException catch (e) {
        final status = e.response?.statusCode;
        if (_isTransient(status) && attempt < _retryDelays.length) {
          await _wait(_retryDelays[attempt]);
          continue;
        }
        if (status == 429) {
          final quota = _quotaOf(e);
          if (quota.daily) throw const _DailyQuotaExhausted();
          final after = quota.retryAfter;
          if (!waitedForRateLimit && after != null && after <= _maxRateLimitWait) {
            waitedForRateLimit = true;
            await _wait(after);
            continue;
          }
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
        'Слишком много запросов к Gemini за минуту. Подождите минуту и попробуйте снова.',
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

/// A model's daily quota is used up; the next model may still have one.
class _DailyQuotaExhausted implements Exception {
  const _DailyQuotaExhausted();
}

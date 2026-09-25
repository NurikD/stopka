import 'dart:typed_data';

import 'package:serverpod_client/serverpod_client.dart'
    show ServerpodClientException, ServerpodClientUnauthorized;
import 'package:stopka_client/stopka_client.dart' as api;

import '../server/device_token_store.dart';
import 'llm_client.dart';
import 'llm_exception.dart';

/// The server's AI proxy behind the same [LlmClient] interface the app always
/// used. It ignores the prompt text it is handed: the server owns the prompts
/// and builds them from the [AiRequest]. A call without one (a feature that has
/// no server endpoint yet) says so honestly.
class ServerLlmClient implements LlmClient {
  final api.Client _client;
  final DeviceTokenStore _tokens;
  final DateTime Function() _now;

  ServerLlmClient(this._client, this._tokens, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  @override
  Future<String> complete({
    required String systemPrompt,
    required String userMessage,
    AiRequest? request,
  }) {
    return _call(request, () {
      final p = request!.params;
      final strict = request.strict;
      switch (request.kind) {
        case AiKind.checkWriting:
          return _client.ai.checkWriting(
            _s(p['level']),
            _s(p['task']),
            _s(p['text']),
            strict,
          );
        case AiKind.appeal:
          return _client.ai.appeal(
            _s(p['term']),
            _s(p['correctAnswer']),
            _s(p['userAnswer']),
            _s(p['direction']),
            strict,
          );
        case AiKind.weakSpotDrill:
          return _client.ai.weakSpotDrill(
            _s(p['level']),
            _s(p['category']),
            _s(p['categoryRu']),
            _list(p['interests']),
            _list(p['words']),
            [
              for (final m
                  in (p['mistakes'] as List? ?? const []).whereType<Map>())
                api.MistakeExample(
                  original: _s(m['original']),
                  corrected: _s(m['corrected']),
                ),
            ],
            strict,
          );
        case AiKind.enrichCards:
          return _client.ai.enrichCards(
            _s(p['level']),
            _s(p['grammarTopic']),
            _s(p['vocabTopic']),
            _list(p['terms']),
            strict,
          );
        case AiKind.recognizeWords:
        case AiKind.readUnitPage:
          throw const LlmException('Для этой функции нужно фото.');
      }
    });
  }

  @override
  Future<String> completeWithImage({
    required String systemPrompt,
    required String userMessage,
    required Uint8List imageBytes,
    required String mimeType,
    AiRequest? request,
  }) {
    return _call(request, () {
      final image = ByteData.sublistView(imageBytes);
      switch (request!.kind) {
        case AiKind.recognizeWords:
          return _client.ai.recognizeWords(image, mimeType, request.strict);
        case AiKind.readUnitPage:
          return _client.ai.readUnitPage(image, mimeType, request.strict);
        default:
          throw const LlmException('Эта функция не принимает фото.');
      }
    });
  }

  @override
  Future<bool> validateApiKey(String apiKey) async => true; // there is no user key in server mode

  Future<String> _call(
    AiRequest? request,
    Future<String> Function() body,
  ) async {
    if (request == null) {
      throw const LlmException(
        'Эта функция пока недоступна без личного ключа Gemini.',
      );
    }
    try {
      return await body();
    } on api.LimitExceeded catch (e) {
      throw LlmException(limitMessage(e.resetAt, _now()), isRateLimited: true);
    } on api.AiUnavailable catch (e) {
      throw LlmException(unavailableMessage(e.reason, e.retryAfterMinutes));
    } on api.InvalidAiRequest {
      throw const LlmException(
        'Сервер не принял запрос: проверьте текст или фото.',
      );
    } on ServerpodClientUnauthorized {
      // The server does not know this token any more; register again at the next start.
      await _tokens.clear();
      throw const LlmException(
        'Сервер не узнал это устройство. Перезапустите приложение.',
      );
    } on ServerpodClientException {
      throw const LlmException(
        'Не удалось связаться с сервером. Проверьте интернет.',
      );
    } on LlmException {
      rethrow;
    } on Exception {
      throw const LlmException(
        'Не удалось связаться с сервером. Проверьте интернет.',
      );
    }
  }

  static String _s(Object? v) => v is String ? v : '';

  static List<String> _list(Object? v) => [
    for (final e in (v as List? ?? const []))
      if (e is String) e,
  ];
}

/// "Дневной лимит исчерпан. Обновится через 3 ч 20 мин (в 03:00)."
String limitMessage(DateTime resetAtUtc, DateTime now) {
  final reset = resetAtUtc.toLocal();
  final left = reset.difference(now);
  final minutes = left.inMinutes < 1 ? 1 : left.inMinutes;
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  final in_ = hours > 0 ? '$hours ч $rest мин' : '$rest мин';
  String two(int n) => n.toString().padLeft(2, '0');
  return 'Дневной лимит этой функции исчерпан. Обновится через $in_ (в ${two(reset.hour)}:${two(reset.minute)}).';
}

String unavailableMessage(String reason, int? retryAfterMinutes) {
  switch (reason) {
    case 'disabled':
      return 'ИИ сейчас отключён на сервере. Попробуйте позже.';
    case 'budget':
      final wait = retryAfterMinutes == null
          ? 'завтра'
          : 'примерно через ${(retryAfterMinutes / 60).ceil()} ч';
      return 'На сегодня запросы к ИИ для всех закончились. Вернуться можно $wait.';
    case 'overloaded':
      return 'Сервис ИИ сейчас перегружен. Это временно — повторите через минуту.';
    case 'provider_limit':
      return 'Сервис ИИ просит подождать. Повторите через минуту.';
    default:
      return 'Сервер ИИ не смог ответить. Попробуйте позже.';
  }
}

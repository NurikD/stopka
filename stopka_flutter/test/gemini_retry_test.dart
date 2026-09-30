import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stopka/core/llm/api_key_store.dart';
import 'package:stopka/core/llm/gemini_llm_client.dart';
import 'package:stopka/core/llm/llm_exception.dart';

class _Key extends ApiKeyStore {
  @override
  Future<String?> getApiKey() async => 'key';

  @override
  Future<String> getModel() async => 'gemini-test';
}

/// Answers with the scripted status codes in order; 200 carries a reply.
class _Adapter implements HttpClientAdapter {
  final List<int> statuses;
  int calls = 0;

  _Adapter(this.statuses);

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    final status = statuses[calls < statuses.length ? calls : statuses.length - 1];
    calls++;
    final body = status == 200
        ? jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': 'ok'},
                  ],
                },
              },
            ],
          })
        : jsonEncode({'error': 'x'});
    return ResponseBody.fromString(body, status, headers: {
      Headers.contentTypeHeader: ['application/json'],
    });
  }

  @override
  void close({bool force = false}) {}
}

/// Answers with scripted (status, body) pairs, repeating the last one, and
/// records which model each request went to.
class _Scripted implements HttpClientAdapter {
  final List<(int, Object?)> script;
  final List<String> models = [];

  _Scripted(this.script);

  int get calls => models.length;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    final (status, body) = script[calls < script.length ? calls : script.length - 1];
    models.add(RegExp(r'models/([^:]+):').firstMatch(options.path)![1]!);
    final json = status == 200
        ? {
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': 'ok'},
                  ],
                },
              },
            ],
          }
        : body;
    return ResponseBody.fromString(jsonEncode(json), status, headers: {
      Headers.contentTypeHeader: ['application/json'],
    });
  }

  @override
  void close({bool force = false}) {}
}

GeminiLlmClient _client(_Adapter adapter) {
  final dio = Dio()
    ..httpClientAdapter = adapter
    ..options.validateStatus = (s) => s != null && s >= 200 && s < 300;
  return GeminiLlmClient(_Key(), dio: dio, retryDelays: const [Duration.zero, Duration.zero]);
}

void main() {
  test('a 503 that passes on the second try is invisible to the caller', () async {
    final adapter = _Adapter([503, 200]);
    expect(await _client(adapter).complete(systemPrompt: 's', userMessage: 'u'), 'ok');
    expect(adapter.calls, 2);
  });

  test('a persistent 503 is retried twice, then reported as temporary overload', () async {
    final adapter = _Adapter([503]);
    await expectLater(
      _client(adapter).complete(systemPrompt: 's', userMessage: 'u'),
      throwsA(isA<LlmException>().having((e) => e.messageRu, 'message', contains('перегружен'))),
    );
    expect(adapter.calls, 3);
  });

  test('a wrong key (403) is not retried', () async {
    final adapter = _Adapter([403]);
    await expectLater(_client(adapter).complete(systemPrompt: 's', userMessage: 'u'), throwsA(isA<LlmException>()));
    expect(adapter.calls, 1);
  });

  group('free-tier quotas', () {
    Map<String, Object?> quota(String quotaId, {String? retryDelay}) => {
          'error': {
            'code': 429,
            'status': 'RESOURCE_EXHAUSTED',
            'details': [
              {
                '@type': 'type.googleapis.com/google.rpc.QuotaFailure',
                'violations': [
                  {'quotaId': quotaId},
                ],
              },
              if (retryDelay != null) {'@type': 'type.googleapis.com/google.rpc.RetryInfo', 'retryDelay': retryDelay},
            ],
          },
        };

    GeminiLlmClient client(_Scripted adapter, List<Duration> waits) {
      final dio = Dio()
        ..httpClientAdapter = adapter
        ..options.validateStatus = (s) => s != null && s >= 200 && s < 300;
      return GeminiLlmClient(_Key(), dio: dio, retryDelays: const [], wait: (d) async => waits.add(d));
    }

    test('a used-up daily quota moves on to the next model', () async {
      final adapter = _Scripted([
        (429, quota('GenerateRequestsPerDayPerProjectPerModel-FreeTier')),
        (200, null),
      ]);
      expect(await client(adapter, []).complete(systemPrompt: 's', userMessage: 'u'), 'ok');
      expect(adapter.models, ['gemini-test', 'gemini-3.5-flash-lite']);
    });

    test('when every model is out for the day, the learner is told when it resets', () async {
      final adapter = _Scripted([(429, quota('GenerateRequestsPerDayPerProjectPerModel-FreeTier'))]);
      await expectLater(
        client(adapter, []).complete(systemPrompt: 's', userMessage: 'u'),
        throwsA(isA<LlmException>().having((e) => e.messageRu, 'message', contains('Дневной лимит'))),
      );
      expect(adapter.models, ['gemini-test', 'gemini-3.5-flash-lite', 'gemini-3.1-flash-lite']);
    });

    test('a per-minute limit waits as long as Gemini asks, then retries the same model', () async {
      final waits = <Duration>[];
      final adapter = _Scripted([
        (429, quota('GenerateRequestsPerMinutePerProjectPerModel-FreeTier', retryDelay: '37s')),
        (200, null),
      ]);
      expect(await client(adapter, waits).complete(systemPrompt: 's', userMessage: 'u'), 'ok');
      expect(waits, [const Duration(seconds: 38)]);
      expect(adapter.models, ['gemini-test', 'gemini-test']);
    });

    test('a per-minute limit is waited out only once', () async {
      final adapter = _Scripted([
        (429, quota('GenerateRequestsPerMinutePerProjectPerModel-FreeTier', retryDelay: '5s')),
      ]);
      await expectLater(
        client(adapter, []).complete(systemPrompt: 's', userMessage: 'u'),
        throwsA(isA<LlmException>().having((e) => e.messageRu, 'message', contains('за минуту'))),
      );
      expect(adapter.calls, 2);
    });
  });

  test('a rate limit (429) is not retried here', () async {
    final adapter = _Adapter([429]);
    await expectLater(
      _client(adapter).complete(systemPrompt: 's', userMessage: 'u'),
      throwsA(isA<LlmException>().having((e) => e.isRateLimited, 'rate limited', isTrue)),
    );
    expect(adapter.calls, 1);
  });
}

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

  test('a rate limit (429) is not retried here', () async {
    final adapter = _Adapter([429]);
    await expectLater(
      _client(adapter).complete(systemPrompt: 's', userMessage: 'u'),
      throwsA(isA<LlmException>().having((e) => e.isRateLimited, 'rate limited', isTrue)),
    );
    expect(adapter.calls, 1);
  });
}

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stopka/core/llm/llm_client.dart';
import 'package:stopka/core/llm/llm_exception.dart';
import 'package:stopka/core/llm/word_recognition_service.dart';

class _FakeLlmClient implements LlmClient {
  final List<String> responses;
  int calls = 0;

  _FakeLlmClient(this.responses);

  @override
  Future<String> completeWithImage({
    required String systemPrompt,
    required String userMessage,
    required Uint8List imageBytes,
    required String mimeType,
  }) async {
    final response = responses[calls];
    calls++;
    return response;
  }

  @override
  Future<String> complete({required String systemPrompt, required String userMessage}) {
    throw UnimplementedError();
  }

  @override
  Future<bool> validateApiKey(String apiKey) {
    throw UnimplementedError();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('parses a well-formed word list response', () async {
    final client = _FakeLlmClient([
      '{"words": [{"term": "achieve", "translation": "достигать"}, {"term": "goal", "translation": ""}]}',
    ]);
    final service = WordRecognitionService(client);

    final words = await service.recognize(imageBytes: Uint8List(0), mimeType: 'image/jpeg');

    expect(words, hasLength(2));
    expect(words[0].term, 'achieve');
    expect(words[0].translation, 'достигать');
    expect(words[1].translation, '');
  });

  test('drops entries with an empty term', () async {
    final client = _FakeLlmClient([
      '{"words": [{"term": "", "translation": "x"}, {"term": "goal", "translation": ""}]}',
    ]);
    final service = WordRecognitionService(client);

    final words = await service.recognize(imageBytes: Uint8List(0), mimeType: 'image/jpeg');

    expect(words, hasLength(1));
    expect(words.first.term, 'goal');
  });

  test('retries once on a malformed response, then succeeds', () async {
    final client = _FakeLlmClient([
      'not json',
      '{"words": [{"term": "goal", "translation": ""}]}',
    ]);
    final service = WordRecognitionService(client);

    final words = await service.recognize(imageBytes: Uint8List(0), mimeType: 'image/jpeg');

    expect(client.calls, 2);
    expect(words, hasLength(1));
  });

  test('throws a Russian error after two malformed responses', () async {
    final client = _FakeLlmClient(['not json', 'still not json']);
    final service = WordRecognitionService(client);

    expect(
      () => service.recognize(imageBytes: Uint8List(0), mimeType: 'image/jpeg'),
      throwsA(isA<LlmException>()),
    );
  });
}

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stopka/core/llm/card_enrichment_service.dart';
import 'package:stopka/core/llm/llm_client.dart';
import 'package:stopka/core/llm/llm_exception.dart';
import 'package:stopka/domain/repositories/llm_cache_repository.dart';

class _FakeLlmClient implements LlmClient {
  final List<String> responses;
  final List<String> prompts = [];
  int calls = 0;

  _FakeLlmClient(this.responses);

  @override
  Future<String> complete({
    required String systemPrompt,
    required String userMessage,
    AiRequest? request,
  }) async {
    prompts.add(systemPrompt);
    final response = responses[calls];
    calls++;
    return response;
  }

  @override
  Future<String> completeWithImage({
    required String systemPrompt,
    required String userMessage,
    required Uint8List imageBytes,
    required String mimeType,
    AiRequest? request,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<bool> validateApiKey(String apiKey) {
    throw UnimplementedError();
  }
}

class _InMemoryCache implements LlmCacheRepository {
  final Map<String, String> _store = {};

  @override
  Future<String?> get(String requestHash) async => _store[requestHash];

  @override
  Future<void> put(String requestHash, String responseJson) async {
    _store[requestHash] = responseJson;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('parses a well-formed enrichment response', () async {
    final client = _FakeLlmClient([
      '{"cards": [{"term": "achieve", "translation": "достигать", "transcription": "/əˈtʃiːv/", '
          '"partOfSpeech": "глагол", "examples": ["She achieved it."]}]}',
    ]);
    final service = CardEnrichmentService(client, _InMemoryCache());

    final cards = await service.enrich(terms: ['achieve'], level: 'B1');

    expect(cards, hasLength(1));
    expect(cards.first.translation, 'достигать');
    expect(cards.first.examples, ['She achieved it.']);
  });

  test('does not call the model twice for the same term and context', () async {
    final client = _FakeLlmClient([
      '{"cards": [{"term": "achieve", "translation": "достигать", "transcription": "", '
          '"partOfSpeech": "", "examples": []}]}',
    ]);
    final cache = _InMemoryCache();
    final service = CardEnrichmentService(client, cache);

    await service.enrich(
      terms: ['achieve'],
      level: 'B1',
      grammarTopic: 'Present perfect',
    );
    await service.enrich(
      terms: ['achieve'],
      level: 'B1',
      grammarTopic: 'Present perfect',
    );

    expect(client.calls, 1);
  });

  test('re-fetches when the unit context changes', () async {
    final client = _FakeLlmClient([
      '{"cards": [{"term": "achieve", "translation": "A", "transcription": "", "partOfSpeech": "", "examples": []}]}',
      '{"cards": [{"term": "achieve", "translation": "B", "transcription": "", "partOfSpeech": "", "examples": []}]}',
    ]);
    final service = CardEnrichmentService(client, _InMemoryCache());

    final first = await service.enrich(
      terms: ['achieve'],
      level: 'B1',
      grammarTopic: 'Unit 1',
    );
    final second = await service.enrich(
      terms: ['achieve'],
      level: 'B1',
      grammarTopic: 'Unit 2',
    );

    expect(first.first.translation, 'A');
    expect(second.first.translation, 'B');
    expect(client.calls, 2);
  });

  test(
    'throws a Russian error when both attempts return malformed JSON',
    () async {
      final client = _FakeLlmClient(['not json', 'still not json']);
      final service = CardEnrichmentService(client, _InMemoryCache());

      expect(
        () => service.enrich(terms: ['achieve'], level: 'B1'),
        throwsA(isA<LlmException>()),
      );
    },
  );

  test(
    'returns an empty list for an empty term list without calling the model',
    () async {
      final client = _FakeLlmClient([]);
      final service = CardEnrichmentService(client, _InMemoryCache());

      final cards = await service.enrich(terms: [], level: 'B1');

      expect(cards, isEmpty);
      expect(client.calls, 0);
    },
  );
}

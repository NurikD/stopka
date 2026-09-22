import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../domain/repositories/llm_cache_repository.dart';
import 'llm_client.dart';
import 'llm_exception.dart';
import 'llm_json.dart';

class EnrichedCard {
  final String term;
  final String translation;
  final String transcription;
  final String partOfSpeech;
  final List<String> examples;

  const EnrichedCard({
    required this.term,
    required this.translation,
    required this.transcription,
    required this.partOfSpeech,
    required this.examples,
  });

  Map<String, dynamic> toJson() => {
        'term': term,
        'translation': translation,
        'transcription': transcription,
        'partOfSpeech': partOfSpeech,
        'examples': examples,
      };

  factory EnrichedCard.fromJson(Map<String, dynamic> json) {
    return EnrichedCard(
      term: (json['term'] as String? ?? '').trim(),
      translation: (json['translation'] as String? ?? '').trim(),
      transcription: (json['transcription'] as String? ?? '').trim(),
      partOfSpeech: (json['partOfSpeech'] as String? ?? '').trim(),
      examples: ((json['examples'] as List?) ?? const []).map((e) => e.toString()).toList(),
    );
  }
}

/// Batches words into one request per 10-20 terms (per DESIGN.md's request
/// economy rules) and caches each result by an individual per-word hash, so
/// a word already enriched in this unit/level context is never re-sent.
class CardEnrichmentService {
  static const _batchSize = 20;

  final LlmClient _client;
  final LlmCacheRepository _cache;

  CardEnrichmentService(this._client, this._cache);

  Future<List<EnrichedCard>> enrich({
    required List<String> terms,
    required String level,
    String grammarTopic = '',
    String vocabTopic = '',
  }) async {
    if (terms.isEmpty) return [];

    final results = <String, EnrichedCard>{};
    final toFetch = <String>[];

    for (final term in terms) {
      final cached = await _cache.get(_termHash(term, level, grammarTopic, vocabTopic));
      if (cached != null) {
        results[term] = EnrichedCard.fromJson(jsonDecode(cached) as Map<String, dynamic>);
      } else {
        toFetch.add(term);
      }
    }

    for (var i = 0; i < toFetch.length; i += _batchSize) {
      final batch = toFetch.sublist(i, i + _batchSize > toFetch.length ? toFetch.length : i + _batchSize);
      final fetched = await _enrichBatch(
        terms: batch,
        level: level,
        grammarTopic: grammarTopic,
        vocabTopic: vocabTopic,
      );
      for (final card in fetched) {
        results[card.term] = card;
        await _cache.put(
          _termHash(card.term, level, grammarTopic, vocabTopic),
          jsonEncode(card.toJson()),
        );
      }
    }

    // Preserve the caller's original order; skip any term the model dropped.
    return terms.where(results.containsKey).map((t) => results[t]!).toList();
  }

  Future<List<EnrichedCard>> _enrichBatch({
    required List<String> terms,
    required String level,
    required String grammarTopic,
    required String vocabTopic,
  }) async {
    final template = await rootBundle.loadString('prompts/card_enrichment.md');
    final prompt = template
        .replaceAll('{{level}}', level)
        .replaceAll('{{grammarTopic}}', grammarTopic)
        .replaceAll('{{vocabTopic}}', vocabTopic)
        .replaceAll('{{words}}', terms.map((t) => '- $t').join('\n'));

    for (var attempt = 0; attempt < 2; attempt++) {
      final raw = await _client.complete(
        systemPrompt: prompt,
        userMessage: attempt == 0
            ? 'Составь карточки для слов из списка.'
            : 'Ответ должен быть строго в формате JSON без markdown-обёрток. Повтори.',
      );
      try {
        final json = LlmJson.decode(raw);
        final cards = json['cards'];
        if (cards is! List) {
          throw const LlmException('ИИ вернул ответ неожиданной формы.');
        }
        return cards.whereType<Map<String, dynamic>>().map(EnrichedCard.fromJson).toList();
      } on LlmException {
        if (attempt == 1) {
          throw const LlmException(
            'Не удалось обогатить карточки — ИИ вернул некорректный ответ. Попробуйте ещё раз.',
          );
        }
      }
    }
    throw const LlmException('Не удалось обогатить карточки.');
  }

  String _termHash(String term, String level, String grammarTopic, String vocabTopic) {
    final key = '${term.toLowerCase()}|$level|$grammarTopic|$vocabTopic';
    return sha256.convert(utf8.encode(key)).toString();
  }
}

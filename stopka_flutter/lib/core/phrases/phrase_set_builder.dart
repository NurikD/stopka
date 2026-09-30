// ignore_for_file: prefer_initializing_formals -- named params stay public while fields are private.
import '../../domain/models/word_card.dart';
import '../../domain/models/word_set.dart';
import '../../domain/repositories/word_card_repository.dart';
import '../../domain/repositories/word_set_repository.dart';
import '../llm/card_enrichment_service.dart';
import '../llm/llm_exception.dart';

/// Enriches words that have no translated example yet. Null when AI is not
/// available: the builder then uses only what the cards already have.
typedef EnrichFn = Future<List<EnrichedCard>> Function(List<String> terms);

class PhraseSetResult {
  /// The unit's phrase set, or null when there was nothing to build it from.
  final String? setId;
  final int added;

  /// Words still without a translated example (no AI, or it failed).
  final int withoutExamples;

  /// Russian message of an AI failure, when there was one.
  final String? error;

  const PhraseSetResult({required this.setId, required this.added, required this.withoutExamples, this.error});
}

/// Builds the unit's "Фразы" set: one phrase card per word, from the word's
/// first translated example. The prompt is the Russian sentence, the answer
/// the English one, and the word it was written for is the hint. Running it
/// again only adds phrases for words that got one since.
class PhraseSetBuilder {
  final WordSetRepository _sets;
  final WordCardRepository _cards;
  final EnrichFn? _enrich;

  PhraseSetBuilder({required WordSetRepository sets, required WordCardRepository cards, EnrichFn? enrich})
      : _sets = sets,
        _cards = cards,
        _enrich = enrich;

  Future<PhraseSetResult> build({required String unitId, required String title}) async {
    final sets = await _sets.watchWordSets(unitId: unitId).first;
    final phraseSet = sets.where((s) => s.source == WordSetSource.phrases).firstOrNull;
    final words = <WordCard>[
      for (final set in sets.where((s) => s.source != WordSetSource.phrases)) ...await _cards.watchCards(set.id).first,
    ];

    String? error;
    final missing = words.where((c) => c.translatedExamples.isEmpty).toList();
    final enrich = _enrich;
    if (missing.isNotEmpty && enrich != null) {
      try {
        final enriched = {for (final e in await enrich(missing.map((c) => c.term).toList())) e.term.toLowerCase(): e};
        for (var i = 0; i < words.length; i++) {
          final e = enriched[words[i].term.toLowerCase()];
          if (e == null || e.examplesRu.isEmpty || words[i].translatedExamples.isNotEmpty) continue;
          words[i] = words[i].copyWith(examples: e.examples, exampleTranslations: e.examplesRu);
          await _cards.updateCard(words[i]);
        }
      } on LlmException catch (e) {
        error = e.messageRu;
      }
    }

    final existing = phraseSet == null
        ? <String>{}
        : {for (final c in await _cards.watchCards(phraseSet.id).first) _key(c.term)};
    final toAdd = <(String, String, String)>[];
    for (final word in words) {
      final pairs = word.translatedExamples;
      if (pairs.isEmpty) continue;
      final (english, russian) = pairs.first;
      if (existing.add(_key(english))) toAdd.add((english, russian, word.term));
    }

    var setId = phraseSet?.id;
    if (toAdd.isNotEmpty) {
      setId ??= (await _sets.createWordSet(unitId: unitId, title: title, source: WordSetSource.phrases)).id;
      for (final (english, russian, word) in toAdd) {
        await _cards.createCard(setId: setId, term: english, translation: russian, note: word);
      }
    }

    return PhraseSetResult(
      setId: setId,
      added: toAdd.length,
      withoutExamples: words.where((c) => c.translatedExamples.isEmpty).length,
      error: error,
    );
  }

  static String _key(String s) => s.trim().toLowerCase();
}

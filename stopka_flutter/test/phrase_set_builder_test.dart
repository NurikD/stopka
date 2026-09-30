import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stopka/core/llm/card_enrichment_service.dart';
import 'package:stopka/core/llm/llm_exception.dart';
import 'package:stopka/core/phrases/phrase_set_builder.dart';
import 'package:stopka/data/db/app_database.dart';
import 'package:stopka/data/repositories/word_card_repository_impl.dart';
import 'package:stopka/data/repositories/word_set_repository_impl.dart';
import 'package:stopka/domain/models/word_set.dart';

void main() {
  late AppDatabase db;
  late DriftWordSetRepository sets;
  late DriftWordCardRepository cards;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    sets = DriftWordSetRepository(db, 'o');
    cards = DriftWordCardRepository(db, 'o');
  });
  tearDown(() => db.close());

  Future<String> unitWithWords(Map<String, (String, String)?> words) async {
    const unitId = 'unit1';
    final set = await sets.createWordSet(unitId: unitId, title: '4B', source: WordSetSource.manual);
    for (final entry in words.entries) {
      final card = await cards.createCard(setId: set.id, term: entry.key, translation: '-');
      final example = entry.value;
      if (example != null) {
        await cards.updateCard(card.copyWith(examples: [example.$1], exampleTranslations: [example.$2]));
      }
    }
    return unitId;
  }

  test('one phrase per word from its translated example, the word as the hint', () async {
    final unitId = await unitWithWords({
      'achieve': ('She achieved her goal.', 'Она достигла своей цели.'),
      'effort': null,
    });

    final result = await PhraseSetBuilder(sets: sets, cards: cards).build(unitId: unitId, title: 'Фразы · 4B');

    expect(result.added, 1);
    expect(result.withoutExamples, 1);
    final phraseSet = (await sets.watchWordSets(unitId: unitId).first).singleWhere((s) => s.source == WordSetSource.phrases);
    expect(phraseSet.title, 'Фразы · 4B');
    final phrase = (await cards.watchCards(phraseSet.id).first).single;
    expect(phrase.term, 'She achieved her goal.');
    expect(phrase.translation, 'Она достигла своей цели.');
    expect(phrase.note, 'achieve');
  });

  test('running again adds only what is new, into the same set', () async {
    final unitId = await unitWithWords({'achieve': ('She achieved her goal.', 'Она достигла своей цели.')});
    final builder = PhraseSetBuilder(sets: sets, cards: cards);
    final first = await builder.build(unitId: unitId, title: 'Фразы');
    final second = await builder.build(unitId: unitId, title: 'Фразы');

    expect(second.added, 0);
    expect(second.setId, first.setId);
    expect(await cards.watchCards(first.setId!).first, hasLength(1));
  });

  test('nothing to build from: no empty set is created', () async {
    final unitId = await unitWithWords({'effort': null});
    final result = await PhraseSetBuilder(sets: sets, cards: cards).build(unitId: unitId, title: 'Фразы');

    expect(result.setId, isNull);
    expect((await sets.watchWordSets(unitId: unitId).first).where((s) => s.source == WordSetSource.phrases), isEmpty);
  });

  test('words without a translated example are enriched first, and the card keeps it', () async {
    final unitId = await unitWithWords({
      'achieve': ('She achieved her goal.', 'Она достигла своей цели.'),
      'effort': null,
    });
    final asked = <List<String>>[];

    final result = await PhraseSetBuilder(
      sets: sets,
      cards: cards,
      enrich: (terms) async {
        asked.add(terms);
        return [
          const EnrichedCard(
            term: 'effort',
            translation: 'усилие',
            transcription: '',
            partOfSpeech: '',
            examples: ['It takes a lot of effort.'],
            examplesRu: ['Это требует больших усилий.'],
          ),
        ];
      },
    ).build(unitId: unitId, title: 'Фразы');

    expect(asked, [
      ['effort'],
    ]);
    expect(result.added, 2);
    expect(result.withoutExamples, 0);
    final words = (await sets.watchWordSets(unitId: unitId).first).firstWhere((s) => s.source != WordSetSource.phrases);
    final effort = (await cards.watchCards(words.id).first).firstWhere((c) => c.term == 'effort');
    expect(effort.exampleTranslations, ['Это требует больших усилий.']);
  });

  test('an AI failure is reported, and what already has examples is still built', () async {
    final unitId = await unitWithWords({
      'achieve': ('She achieved her goal.', 'Она достигла своей цели.'),
      'effort': null,
    });

    final result = await PhraseSetBuilder(
      sets: sets,
      cards: cards,
      enrich: (_) async => throw const LlmException('Сервер ИИ не смог ответить.'),
    ).build(unitId: unitId, title: 'Фразы');

    expect(result.added, 1);
    expect(result.withoutExamples, 1);
    expect(result.error, 'Сервер ИИ не смог ответить.');
  });

  test('enrichment translations that do not line up with the examples are dropped', () {
    final card = EnrichedCard.fromJson({
      'term': 'achieve',
      'examples': ['One.', 'Two.'],
      'examplesRu': ['Один.'],
    });
    expect(card.examples, hasLength(2));
    expect(card.examplesRu, isEmpty);
  });
}

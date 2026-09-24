import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stopka/core/providers/core_providers.dart';
import 'package:stopka/core/srs/srs_settings_store.dart';
import 'package:stopka/core/theme/app_theme.dart';
import 'package:stopka/domain/models/card_state.dart';
import 'package:stopka/domain/models/dictation_session.dart';
import 'package:stopka/domain/models/word_card.dart';
import 'package:stopka/domain/repositories/card_state_repository.dart';
import 'package:stopka/domain/repositories/word_card_repository.dart';
import 'package:stopka/features/srs/srs_review_screen.dart';

WordCard _card(String id, String term, String translation) {
  final now = DateTime(2026, 1, 1);
  return WordCard(
    id: id,
    setId: 'set1',
    term: term,
    translation: translation,
    transcription: '',
    partOfSpeech: '',
    examples: const [],
    note: '',
    ownerId: 'owner',
    createdAt: now,
    updatedAt: now,
  );
}

class _FakeSrsSettingsStore extends SrsSettingsStore {
  @override
  Future<int> getNewCardLimit() async => 20;
}

CardState _freshState(String id, String cardId) {
  return CardState(
    id: id,
    cardId: cardId,
    direction: DictationDirection.ruEn,
    due: DateTime.now().toUtc(),
    reps: 0,
    lapses: 0,
    state: SrsState.learning,
  );
}

class _FakeWordCardRepository implements WordCardRepository {
  final Map<String, WordCard> cards;
  _FakeWordCardRepository(List<WordCard> list) : cards = {for (final c in list) c.id: c};

  @override
  Future<WordCard?> getCard(String id) async => cards[id];

  @override
  Stream<List<WordCard>> watchCards(String setId) => throw UnimplementedError();

  @override
  Future<WordCard> createCard({
    required String setId,
    required String term,
    required String translation,
    String transcription = '',
    String partOfSpeech = '',
    List<String> examples = const [],
    String note = '',
    String? imageRef,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> updateCard(WordCard card) => throw UnimplementedError();

  @override
  Future<void> deleteCard(String id) => throw UnimplementedError();
}

class _FakeCardStateRepository implements CardStateRepository {
  final List<CardState> due;
  final List<CardState> fresh;
  final List<CardState> saved = [];
  final List<({String cardStateId, ReviewRating rating})> logged = [];

  _FakeCardStateRepository({this.due = const [], this.fresh = const []});

  @override
  Future<List<CardState>> getDueForReview({required DateTime now}) async => due;

  @override
  Future<List<CardState>> getNewCards({required int limit}) async => fresh.take(limit).toList();

  @override
  Future<void> saveState(CardState state) async => saved.add(state);

  @override
  Future<void> logReview({required String cardStateId, required ReviewRating rating, DateTime? at}) async {
    logged.add((cardStateId: cardStateId, rating: rating));
  }

  @override
  Future<CardState> ensureState(String cardId, DictationDirection direction) => throw UnimplementedError();

  @override
  Future<int> countReviewsSince(DateTime since) => throw UnimplementedError();

  @override
  Future<int> getStreakDays() => throw UnimplementedError();

  @override
  Stream<int> watchDueCount(DateTime now) => throw UnimplementedError();

  @override
  Stream<int> watchNewCount() => throw UnimplementedError();
}

Future<_FakeCardStateRepository> _pump(
  WidgetTester tester, {
  required List<WordCard> cards,
  required List<CardState> fresh,
}) async {
  final stateRepo = _FakeCardStateRepository(fresh: fresh);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        wordCardRepositoryProvider.overrideWithValue(_FakeWordCardRepository(cards)),
        cardStateRepositoryProvider.overrideWithValue(stateRepo),
        srsSettingsStoreProvider.overrideWithValue(_FakeSrsSettingsStore()),
      ],
      child: MaterialApp(theme: AppTheme.dark(), home: const SrsReviewScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return stateRepo;
}

Future<void> _answer(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.tap(find.text('Проверить'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a typed right answer is rated good by the checker, not by the learner', (tester) async {
    final stateRepo = await _pump(
      tester,
      cards: [_card('c1', 'achieve', 'достигать'), _card('c2', 'goal', 'цель')],
      fresh: [_freshState('s1', 'c1'), _freshState('s2', 'c2')],
    );

    expect(find.text('достигать'), findsOneWidget);
    expect(find.text('Хорошо'), findsNothing); // no self-grading buttons at all
    expect(find.text('Легко'), findsNothing);

    await _answer(tester, 'achieve');
    expect(find.text('Верно'), findsOneWidget);
    await tester.tap(find.text('Дальше'));
    await tester.pumpAndSettle();

    expect(find.text('цель'), findsOneWidget);
    expect(stateRepo.saved.single.reps, 1);
    expect(stateRepo.logged.single.cardStateId, 's1');
    expect(stateRepo.logged.single.rating, ReviewRating.good);
  });

  testWidgets('a wrong answer is "again" and counts as a lapse; the right word is shown', (tester) async {
    final stateRepo = await _pump(
      tester,
      cards: [_card('c1', 'achieve', 'достигать')],
      fresh: [_freshState('s1', 'c1')],
    );

    await _answer(tester, 'reach');
    expect(find.text('Неверно'), findsOneWidget);
    await tester.tap(find.text('Дальше'));
    await tester.pumpAndSettle();

    expect(stateRepo.saved.first.lapses, 1);
    expect(stateRepo.logged.single.rating, ReviewRating.again);
    expect(find.text('На сегодня всё'), findsOneWidget);
  });

  testWidgets('a typo is "hard"', (tester) async {
    final stateRepo = await _pump(
      tester,
      cards: [_card('c1', 'achieve', 'достигать')],
      fresh: [_freshState('s1', 'c1')],
    );

    await _answer(tester, 'acheive');
    expect(find.text('Почти, опечатка'), findsOneWidget);
    await tester.tap(find.text('Дальше'));
    await tester.pumpAndSettle();

    expect(stateRepo.logged.single.rating, ReviewRating.hard);
  });

  testWidgets('"Не знаю" is "again" without typing anything', (tester) async {
    final stateRepo = await _pump(
      tester,
      cards: [_card('c1', 'achieve', 'достигать')],
      fresh: [_freshState('s1', 'c1')],
    );

    await tester.tap(find.text('Не знаю'));
    await tester.pumpAndSettle();
    expect(find.text('achieve'), findsOneWidget);
    await tester.tap(find.text('Дальше'));
    await tester.pumpAndSettle();

    expect(stateRepo.logged.single.rating, ReviewRating.again);
  });

  testWidgets('an empty answer cannot be submitted', (tester) async {
    await _pump(
      tester,
      cards: [_card('c1', 'achieve', 'достигать')],
      fresh: [_freshState('s1', 'c1')],
    );

    await tester.tap(find.text('Проверить'));
    await tester.pumpAndSettle();
    expect(find.text('Дальше'), findsNothing);
  });

  testWidgets('in the English -> Russian direction a synonym can be overruled', (tester) async {
    final state = CardState(
      id: 's1',
      cardId: 'c1',
      direction: DictationDirection.enRu,
      due: DateTime.now().toUtc(),
      reps: 0,
      lapses: 0,
      state: SrsState.learning,
    );
    final stateRepo = await _pump(
      tester,
      cards: [_card('c1', 'achieve', 'достигать')],
      fresh: [state],
    );

    await _answer(tester, 'добиваться');
    expect(find.text('Неверно'), findsOneWidget);
    await tester.tap(find.text('Засчитать'));
    await tester.pumpAndSettle();
    expect(find.text('Засчитано'), findsOneWidget);
    await tester.tap(find.text('Дальше'));
    await tester.pumpAndSettle();

    expect(stateRepo.logged.single.rating, ReviewRating.good);
  });

  testWidgets('a due-for-review card (not just new ones) is shown', (tester) async {
    final cardRepo = _FakeWordCardRepository([_card('c1', 'achieve', 'достигать')]);
    final stateRepo = _FakeCardStateRepository(due: [_freshState('s1', 'c1')]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          wordCardRepositoryProvider.overrideWithValue(cardRepo),
          cardStateRepositoryProvider.overrideWithValue(stateRepo),
          srsSettingsStoreProvider.overrideWithValue(_FakeSrsSettingsStore()),
        ],
        child: MaterialApp(theme: AppTheme.dark(), home: const SrsReviewScreen()),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('достигать'), findsOneWidget);
  });

  testWidgets('shows completion state when the queue is empty', (tester) async {
    final cardRepo = _FakeWordCardRepository([]);
    final stateRepo = _FakeCardStateRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          wordCardRepositoryProvider.overrideWithValue(cardRepo),
          cardStateRepositoryProvider.overrideWithValue(stateRepo),
          srsSettingsStoreProvider.overrideWithValue(_FakeSrsSettingsStore()),
        ],
        child: MaterialApp(theme: AppTheme.dark(), home: const SrsReviewScreen()),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('На сегодня всё'), findsOneWidget);
  });
}

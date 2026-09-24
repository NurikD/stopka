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
  Future<int> getStreakDays() => throw UnimplementedError();

  @override
  Stream<int> watchDueCount(DateTime now) => throw UnimplementedError();

  @override
  Stream<int> watchNewCount() => throw UnimplementedError();
}

void main() {
  testWidgets('reveals the answer, rates it, and advances to the next card', (tester) async {
    final cardRepo = _FakeWordCardRepository([
      _card('c1', 'achieve', 'достигать'),
      _card('c2', 'goal', 'цель'),
    ]);
    final stateRepo = _FakeCardStateRepository(fresh: [
      _freshState('s1', 'c1'),
      _freshState('s2', 'c2'),
    ]);

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
    expect(find.text('достигать'), findsOneWidget); // RU -> EN prompt
    expect(find.text('achieve'), findsNothing); // answer not revealed yet

    await tester.tap(find.text('Показать ответ'));
    await tester.pump();
    expect(find.text('achieve'), findsOneWidget);

    await tester.tap(find.text('Хорошо'));
    await tester.pumpAndSettle();

    // Advanced to the second card, answer hidden again.
    expect(find.text('цель'), findsOneWidget);
    expect(find.text('goal'), findsNothing);
    expect(stateRepo.saved, hasLength(1));
    expect(stateRepo.saved.first.reps, 1);
    // Every grade also lands in the review history the streak is built from.
    expect(stateRepo.logged.single.cardStateId, 's1');
    expect(stateRepo.logged.single.rating, ReviewRating.good);
  });

  testWidgets('rating "Забыл" (again) increments lapses', (tester) async {
    final cardRepo = _FakeWordCardRepository([_card('c1', 'achieve', 'достигать')]);
    final stateRepo = _FakeCardStateRepository(fresh: [_freshState('s1', 'c1')]);

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
    await tester.tap(find.text('Показать ответ'));
    await tester.pump();
    await tester.tap(find.text('Забыл'));
    await tester.pumpAndSettle();

    expect(stateRepo.saved.first.lapses, 1);
    expect(find.text('На сегодня всё'), findsOneWidget);
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stopka/core/providers/core_providers.dart';
import 'package:stopka/core/theme/app_theme.dart';
import 'package:stopka/core/theme/tokens.dart';
import 'package:stopka/domain/models/dictation_answer.dart';
import 'package:stopka/domain/models/dictation_session.dart';
import 'package:stopka/domain/models/word_card.dart';
import 'package:stopka/domain/repositories/dictation_repository.dart';
import 'package:stopka/domain/repositories/word_card_repository.dart';
import 'package:stopka/features/dictation/dictation_session_screen.dart';

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

class _FakeWordCardRepository implements WordCardRepository {
  final List<WordCard> cards;
  _FakeWordCardRepository(this.cards);

  @override
  Stream<List<WordCard>> watchCards(String setId) => Stream.value(cards);

  @override
  Future<WordCard?> getCard(String id) async => cards.where((c) => c.id == id).firstOrNull;

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

class _FakeDictationRepository implements DictationRepository {
  int recordedAnswers = 0;
  bool finished = false;

  @override
  Future<DictationSession> startSession({
    required String setId,
    required DictationDirection direction,
    required int stackSize,
    required int requiredStreak,
  }) async {
    return DictationSession(
      id: 'session1',
      setId: setId,
      direction: direction,
      startedAt: DateTime.now(),
      roundsCount: 0,
      totalWords: 0,
      stackSize: stackSize,
      requiredStreak: requiredStreak,
    );
  }

  @override
  Future<DictationSession?> findUnfinishedSession(String setId) => throw UnimplementedError();

  @override
  Future<DictationAnswer> recordAnswer({
    required String sessionId,
    required String cardId,
    required int roundIndex,
    required String userInput,
    required DictationAnswerVerdict verdict,
    DictationCheckedBy checkedBy = DictationCheckedBy.local,
  }) async {
    recordedAnswers++;
    return DictationAnswer(
      id: 'answer$recordedAnswers',
      sessionId: sessionId,
      cardId: cardId,
      roundIndex: roundIndex,
      userInput: userInput,
      verdict: verdict,
      checkedBy: checkedBy,
    );
  }

  @override
  Future<void> finishSession(String sessionId, {required int roundsCount, required int totalWords}) async {
    finished = true;
  }

  @override
  Future<void> updateAnswerVerdict(String answerId, DictationAnswerVerdict verdict, DictationCheckedBy checkedBy) =>
      throw UnimplementedError();

  @override
  Future<List<DictationAnswer>> getAnswers(String sessionId) => throw UnimplementedError();

  @override
  Stream<List<DictationSession>> watchSessions(String setId) => throw UnimplementedError();
}

void main() {
  testWidgets('a two-word session: one correct, one wrong, reaches stack review', (tester) async {
    final cardRepo = _FakeWordCardRepository([
      _card('c1', 'achieve', 'достигать'),
      _card('c2', 'goal', 'цель'),
    ]);
    final dictationRepo = _FakeDictationRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          wordCardRepositoryProvider.overrideWithValue(cardRepo),
          dictationRepositoryProvider.overrideWithValue(dictationRepo),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const DictationSessionScreen(
            setId: 'set1',
            direction: DictationDirection.ruEn,
            stackSize: 12,
            requiredStreak: 1,
          ),
        ),
      ),
    );

    // Bootstrap: loads cards, starts the session, shows the first word.
    await tester.pumpAndSettle();
    expect(find.text('достигать'), findsOneWidget); // RU -> EN prompt is the translation

    // Answer correctly.
    await tester.enterText(find.byType(TextField), 'achieve');
    await tester.tap(find.text('Проверить'));
    await tester.pump(); // show result
    expect(find.text('Верно'), findsOneWidget);

    // Auto-advance after the reveal delay.
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.text('цель'), findsOneWidget);

    // Answer wrong.
    await tester.enterText(find.byType(TextField), 'wronganswer');
    await tester.tap(find.text('Проверить'));
    await tester.pump();
    expect(find.text('Неверно'), findsOneWidget);

    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Both words answered -> stack review screen.
    expect(find.text('1 из 2'), findsOneWidget);
    expect(find.text('1 слов вернутся в стопку'), findsOneWidget);
    expect(find.text('goal'), findsOneWidget); // the missed word shown for review
    expect(dictationRepo.recordedAnswers, 2);
  });

  testWidgets('pressing "Не знаю" records a skip without typing', (tester) async {
    final cardRepo = _FakeWordCardRepository([_card('c1', 'achieve', 'достигать')]);
    final dictationRepo = _FakeDictationRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          wordCardRepositoryProvider.overrideWithValue(cardRepo),
          dictationRepositoryProvider.overrideWithValue(dictationRepo),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const DictationSessionScreen(
            setId: 'set1',
            direction: DictationDirection.ruEn,
            stackSize: 12,
            requiredStreak: 1,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Не знаю'));
    await tester.pump();
    expect(find.text('Пропущено'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(dictationRepo.recordedAnswers, 1);
  });

  testWidgets('the result transition duration is zero under reduce-motion', (tester) async {
    final cardRepo = _FakeWordCardRepository([_card('c1', 'achieve', 'достигать')]);
    final dictationRepo = _FakeDictationRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          wordCardRepositoryProvider.overrideWithValue(cardRepo),
          dictationRepositoryProvider.overrideWithValue(dictationRepo),
        ],
        child: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            theme: AppTheme.dark(),
            home: const DictationSessionScreen(
              setId: 'set1',
              direction: DictationDirection.ruEn,
              stackSize: 12,
              requiredStreak: 1,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    final switcher = tester.widget<AnimatedSwitcher>(find.byType(AnimatedSwitcher));
    expect(switcher.duration, Duration.zero);
  });

  testWidgets('the result transition duration is the normal one without reduce-motion', (tester) async {
    final cardRepo = _FakeWordCardRepository([_card('c1', 'achieve', 'достигать')]);
    final dictationRepo = _FakeDictationRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          wordCardRepositoryProvider.overrideWithValue(cardRepo),
          dictationRepositoryProvider.overrideWithValue(dictationRepo),
        ],
        child: MediaQuery(
          data: const MediaQueryData(disableAnimations: false),
          child: MaterialApp(
            theme: AppTheme.dark(),
            home: const DictationSessionScreen(
              setId: 'set1',
              direction: DictationDirection.ruEn,
              stackSize: 12,
              requiredStreak: 1,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    final switcher = tester.widget<AnimatedSwitcher>(find.byType(AnimatedSwitcher));
    expect(switcher.duration, AppMotion.checkDuration);
  });
}

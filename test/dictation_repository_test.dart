import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stopka/data/db/app_database.dart';
import 'package:stopka/data/repositories/dictation_repository_impl.dart';
import 'package:stopka/domain/models/dictation_answer.dart';
import 'package:stopka/domain/models/dictation_session.dart';

void main() {
  late AppDatabase db;
  late DriftDictationRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DriftDictationRepository(db, 'owner1');
  });

  tearDown(() async {
    await db.close();
  });

  test('startSession persists stackSize and requiredStreak for later resume', () async {
    final session = await repo.startSession(
      setId: 'set1',
      direction: DictationDirection.enRu,
      stackSize: 15,
      requiredStreak: 2,
    );
    expect(session.stackSize, 15);
    expect(session.requiredStreak, 2);
    expect(session.direction, DictationDirection.enRu);
    expect(session.finishedAt, isNull);
  });

  test('findUnfinishedSession returns null when there is no session at all', () async {
    expect(await repo.findUnfinishedSession('set1'), isNull);
  });

  test('findUnfinishedSession finds a started-but-not-finished session', () async {
    final started = await repo.startSession(
      setId: 'set1',
      direction: DictationDirection.ruEn,
      stackSize: 12,
      requiredStreak: 1,
    );
    final found = await repo.findUnfinishedSession('set1');
    expect(found?.id, started.id);
  });

  test('findUnfinishedSession does not return a finished session', () async {
    final session = await repo.startSession(
      setId: 'set1',
      direction: DictationDirection.ruEn,
      stackSize: 12,
      requiredStreak: 1,
    );
    await repo.finishSession(session.id, roundsCount: 2, totalWords: 5);
    expect(await repo.findUnfinishedSession('set1'), isNull);
  });

  test('findUnfinishedSession only looks at the given set', () async {
    await repo.startSession(setId: 'other-set', direction: DictationDirection.ruEn, stackSize: 12, requiredStreak: 1);
    expect(await repo.findUnfinishedSession('set1'), isNull);
  });

  test('findUnfinishedSession returns the most recently started one', () async {
    final older = await repo.startSession(setId: 'set1', direction: DictationDirection.ruEn, stackSize: 12, requiredStreak: 1);
    // startedAt's default (currentDateAndTime) has 1-second resolution in
    // sqlite, so a shorter gap can't be told apart by ORDER BY startedAt.
    await Future.delayed(const Duration(seconds: 1, milliseconds: 100));
    final newer = await repo.startSession(setId: 'set1', direction: DictationDirection.ruEn, stackSize: 12, requiredStreak: 1);

    final found = await repo.findUnfinishedSession('set1');
    expect(found?.id, newer.id);
    expect(found?.id, isNot(older.id));
  });

  test('recordAnswer and getAnswers round-trip through the same session', () async {
    final session = await repo.startSession(setId: 'set1', direction: DictationDirection.ruEn, stackSize: 12, requiredStreak: 1);
    await repo.recordAnswer(
      sessionId: session.id,
      cardId: 'card1',
      roundIndex: 1,
      userInput: 'achieve',
      verdict: DictationAnswerVerdict.correct,
    );
    await repo.recordAnswer(
      sessionId: session.id,
      cardId: 'card2',
      roundIndex: 1,
      userInput: 'wrong',
      verdict: DictationAnswerVerdict.wrong,
    );

    final answers = await repo.getAnswers(session.id);
    expect(answers, hasLength(2));
    expect(answers.map((a) => a.verdict), containsAll([DictationAnswerVerdict.correct, DictationAnswerVerdict.wrong]));
  });
}

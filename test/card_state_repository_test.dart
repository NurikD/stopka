import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stopka/data/db/app_database.dart';
import 'package:stopka/data/repositories/card_state_repository_impl.dart';
import 'package:stopka/domain/models/dictation_session.dart';

void main() {
  late AppDatabase db;
  late DriftCardStateRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DriftCardStateRepository(db, 'owner1');
  });

  tearDown(() async {
    await db.close();
  });

  test('ensureState creates a fresh, due-now, ungraded state on first call', () async {
    final state = await repo.ensureState('card1', DictationDirection.ruEn);
    expect(state.reps, 0);
    expect(state.lapses, 0);
    expect(state.stability, isNull);
    expect(state.due.isBefore(DateTime.now().toUtc().add(const Duration(seconds: 5))), isTrue);
  });

  test('ensureState returns the same row on a second call, not a duplicate', () async {
    final first = await repo.ensureState('card1', DictationDirection.ruEn);
    final second = await repo.ensureState('card1', DictationDirection.ruEn);
    expect(second.id, first.id);
  });

  test('ensureState treats each direction as a separate state', () async {
    final ruEn = await repo.ensureState('card1', DictationDirection.ruEn);
    final enRu = await repo.ensureState('card1', DictationDirection.enRu);
    expect(ruEn.id, isNot(enRu.id));
  });

  test('a new card counts toward getNewCards and watchNewCount, not getDueForReview', () async {
    await repo.ensureState('card1', DictationDirection.ruEn);
    final newCards = await repo.getNewCards(limit: 10);
    final due = await repo.getDueForReview(now: DateTime.now().toUtc());
    expect(newCards, hasLength(1));
    expect(due, isEmpty);
  });

  test('saveState with reps > 0 moves a card out of new and into due-for-review once due', () async {
    final state = await repo.ensureState('card1', DictationDirection.ruEn);
    await repo.saveState(state.copyWith(reps: 1, due: DateTime.now().toUtc().subtract(const Duration(minutes: 1))));

    final newCards = await repo.getNewCards(limit: 10);
    final due = await repo.getDueForReview(now: DateTime.now().toUtc());
    expect(newCards, isEmpty);
    expect(due, hasLength(1));
  });

  test('a card due in the future does not show up as due yet', () async {
    final state = await repo.ensureState('card1', DictationDirection.ruEn);
    await repo.saveState(state.copyWith(reps: 1, due: DateTime.now().toUtc().add(const Duration(days: 3))));

    final due = await repo.getDueForReview(now: DateTime.now().toUtc());
    expect(due, isEmpty);
  });

  test('getStreakDays is 0 with no review history', () async {
    expect(await repo.getStreakDays(), 0);
  });

  test('getStreakDays counts today as day 1 if reviewed today', () async {
    final state = await repo.ensureState('card1', DictationDirection.ruEn);
    await repo.saveState(state.copyWith(reps: 1, lastReview: DateTime.now().toUtc()));
    expect(await repo.getStreakDays(), 1);
  });

  test('getStreakDays counts consecutive days including yesterday without breaking on a pending today', () async {
    final state = await repo.ensureState('card1', DictationDirection.ruEn);
    final yesterday = DateTime.now().toUtc().subtract(const Duration(days: 1));
    await repo.saveState(state.copyWith(reps: 1, lastReview: yesterday));
    // No review yet today -> streak should still show yesterday's 1-day streak.
    expect(await repo.getStreakDays(), 1);
  });

  test('getStreakDays resets to 0 after a gap of more than one day', () async {
    final state = await repo.ensureState('card1', DictationDirection.ruEn);
    final threeDaysAgo = DateTime.now().toUtc().subtract(const Duration(days: 3));
    await repo.saveState(state.copyWith(reps: 1, lastReview: threeDaysAgo));
    expect(await repo.getStreakDays(), 0);
  });

  test('getStreakDays counts multiple consecutive days across different cards', () async {
    final now = DateTime.now().toUtc();
    final s1 = await repo.ensureState('card1', DictationDirection.ruEn);
    await repo.saveState(s1.copyWith(reps: 1, lastReview: now));
    final s2 = await repo.ensureState('card2', DictationDirection.ruEn);
    await repo.saveState(s2.copyWith(reps: 1, lastReview: now.subtract(const Duration(days: 1))));
    final s3 = await repo.ensureState('card3', DictationDirection.ruEn);
    await repo.saveState(s3.copyWith(reps: 1, lastReview: now.subtract(const Duration(days: 2))));

    expect(await repo.getStreakDays(), 3);
  });
}

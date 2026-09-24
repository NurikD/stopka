import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stopka/data/db/app_database.dart';
import 'package:stopka/data/repositories/card_state_repository_impl.dart';
import 'package:stopka/domain/models/card_state.dart';
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

  group('streak from the review log', () {
    DateTime daysAgo(int n) => DateTime.now().subtract(Duration(days: n));

    test('keeps earlier days even though the card was reviewed again later', () async {
      // The card's own lastReview only remembers the latest review, so this
      // is exactly the case a streak built from CardStates alone got wrong.
      final state = await repo.ensureState('card1', DictationDirection.ruEn);
      await repo.logReview(cardStateId: state.id, rating: ReviewRating.good, at: daysAgo(2));
      await repo.logReview(cardStateId: state.id, rating: ReviewRating.good, at: daysAgo(1));
      await repo.logReview(cardStateId: state.id, rating: ReviewRating.good, at: daysAgo(0));
      await repo.saveState(state.copyWith(reps: 3, lastReview: DateTime.now().toUtc()));

      expect(await repo.getStreakDays(), 3);
    });

    test('a missed day breaks the streak', () async {
      final state = await repo.ensureState('card1', DictationDirection.ruEn);
      await repo.logReview(cardStateId: state.id, rating: ReviewRating.good, at: daysAgo(3));
      await repo.logReview(cardStateId: state.id, rating: ReviewRating.good, at: daysAgo(1));
      await repo.logReview(cardStateId: state.id, rating: ReviewRating.good, at: daysAgo(0));

      expect(await repo.getStreakDays(), 2);
    });

    test('several reviews on one day still count as one day', () async {
      final state = await repo.ensureState('card1', DictationDirection.ruEn);
      for (var i = 0; i < 5; i++) {
        await repo.logReview(cardStateId: state.id, rating: ReviewRating.good);
      }
      expect(await repo.getStreakDays(), 1);
    });

    test('a streak alive through yesterday is not wiped by a pending today', () async {
      final state = await repo.ensureState('card1', DictationDirection.ruEn);
      await repo.logReview(cardStateId: state.id, rating: ReviewRating.good, at: daysAgo(2));
      await repo.logReview(cardStateId: state.id, rating: ReviewRating.good, at: daysAgo(1));

      expect(await repo.getStreakDays(), 2);
    });
  });

  group('countReviewsSince', () {
    test('counts only reviews at or after the cut-off', () async {
      final state = await repo.ensureState('card1', DictationDirection.ruEn);
      final startOfToday = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
      await repo.logReview(cardStateId: state.id, rating: ReviewRating.good, at: startOfToday.subtract(const Duration(hours: 2)));
      await repo.logReview(cardStateId: state.id, rating: ReviewRating.good, at: startOfToday.add(const Duration(hours: 1)));
      await repo.logReview(cardStateId: state.id, rating: ReviewRating.again, at: startOfToday.add(const Duration(hours: 2)));

      expect(await repo.countReviewsSince(startOfToday), 2);
    });

    test('is zero with no history', () async {
      expect(await repo.countReviewsSince(DateTime(2000)), 0);
    });
  });
}

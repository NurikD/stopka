import '../models/card_state.dart';
import '../models/dictation_session.dart';

abstract class CardStateRepository {
  /// Returns the existing state for (cardId, direction), or creates a
  /// fresh one (due now, never reviewed) if this is the card's first time
  /// entering the deck — see PLAN.md "результаты диктанта задают
  /// стартовое состояние карточек".
  Future<CardState> ensureState(String cardId, DictationDirection direction);

  Future<void> saveState(CardState state);

  Future<List<CardState>> getDueForReview({required DateTime now});

  Future<List<CardState>> getNewCards({required int limit});

  Stream<int> watchDueCount(DateTime now);

  Stream<int> watchNewCount();

  /// Appends one graded review to the history. [at] defaults to now.
  Future<void> logReview({required String cardStateId, required ReviewRating rating, DateTime? at});

  /// Graded reviews logged at or after [since] — for "done today".
  Future<int> countReviewsSince(DateTime since);

  /// Consecutive days (ending today or yesterday, so the streak isn't
  /// wiped the instant a new day starts) with at least one review.
  Future<int> getStreakDays();
}

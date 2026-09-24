import 'package:fsrs/fsrs.dart' as fsrs;

enum SrsRating { again, hard, good, easy }

enum SrsCardState { learning, review, relearning }

/// The FSRS-relevant fields of a [CardState] row, decoupled from drift so
/// this module has no dependency on the data layer.
class SrsSnapshot {
  final SrsCardState state;
  final int? step;
  final double? stability;
  final double? difficulty;
  final DateTime due;
  final DateTime? lastReview;

  const SrsSnapshot({
    required this.state,
    this.step,
    this.stability,
    this.difficulty,
    required this.due,
    this.lastReview,
  });

  /// A card that has never been graded — due immediately, so it shows up
  /// in today's queue the moment it enters the deck.
  factory SrsSnapshot.fresh() => SrsSnapshot(state: SrsCardState.learning, due: DateTime.now().toUtc());
}

class SrsReviewResult {
  final SrsSnapshot snapshot;

  /// How far out the card was just scheduled — purely informational
  /// (e.g. for a "+3 дня" toast), not persisted.
  final Duration interval;

  const SrsReviewResult({required this.snapshot, required this.interval});
}

/// Thin wrapper around package:fsrs so the rest of the app depends on our
/// own [SrsSnapshot]/[SrsRating] types, not the package's — swapping the
/// scheduler implementation later only touches this file.
class SrsEngine {
  final fsrs.Scheduler _scheduler;

  SrsEngine({fsrs.Scheduler? scheduler}) : _scheduler = scheduler ?? fsrs.Scheduler();

  SrsReviewResult review(SrsSnapshot current, SrsRating rating) {
    final card = fsrs.Card(
      cardId: 0,
      state: _toFsrsState(current.state),
      step: current.step,
      stability: current.stability,
      difficulty: current.difficulty,
      due: current.due.toUtc(),
      lastReview: current.lastReview?.toUtc(),
    );

    final result = _scheduler.reviewCard(card, _toFsrsRating(rating));
    final updated = result.card;

    return SrsReviewResult(
      snapshot: SrsSnapshot(
        state: _fromFsrsState(updated.state),
        step: updated.step,
        stability: updated.stability,
        difficulty: updated.difficulty,
        due: updated.due,
        lastReview: updated.lastReview,
      ),
      interval: updated.due.difference(result.reviewLog.reviewDateTime),
    );
  }

  static fsrs.State _toFsrsState(SrsCardState s) => fsrs.State.values.byName(s.name);

  static SrsCardState _fromFsrsState(fsrs.State s) => SrsCardState.values.byName(s.name);

  static fsrs.Rating _toFsrsRating(SrsRating r) => fsrs.Rating.values.byName(r.name);
}

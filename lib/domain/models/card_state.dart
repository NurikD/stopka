import 'dictation_session.dart';

enum SrsState { learning, review, relearning }

enum ReviewRating { again, hard, good, easy }

class CardState {
  final String id;
  final String cardId;
  final DictationDirection direction;
  final DateTime due;
  final double? stability;
  final double? difficulty;
  final int? step;
  final int reps;
  final int lapses;
  final SrsState state;
  final DateTime? lastReview;

  const CardState({
    required this.id,
    required this.cardId,
    required this.direction,
    required this.due,
    this.stability,
    this.difficulty,
    this.step,
    required this.reps,
    required this.lapses,
    required this.state,
    this.lastReview,
  });

  CardState copyWith({
    DateTime? due,
    double? stability,
    double? difficulty,
    int? step,
    int? reps,
    int? lapses,
    SrsState? state,
    DateTime? lastReview,
  }) {
    return CardState(
      id: id,
      cardId: cardId,
      direction: direction,
      due: due ?? this.due,
      stability: stability ?? this.stability,
      difficulty: difficulty ?? this.difficulty,
      step: step ?? this.step,
      reps: reps ?? this.reps,
      lapses: lapses ?? this.lapses,
      state: state ?? this.state,
      lastReview: lastReview ?? this.lastReview,
    );
  }
}

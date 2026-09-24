import '../dictation/answer_checker.dart';
import 'srs_engine.dart';

/// The rating a typed answer earns. The learner does not grade themselves:
/// a right answer is "good", a typo is "hard", a wrong or skipped one is
/// "again". (Nothing earns "easy" — that would need a speed signal.)
SrsRating ratingForVerdict(DictationVerdict verdict) {
  return switch (verdict) {
    DictationVerdict.correct => SrsRating.good,
    DictationVerdict.typo => SrsRating.hard,
    DictationVerdict.wrong || DictationVerdict.skipped => SrsRating.again,
  };
}

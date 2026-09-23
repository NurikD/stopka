import 'package:flutter_test/flutter_test.dart';
import 'package:stopka/core/srs/srs_engine.dart';

void main() {
  group('SrsEngine.review', () {
    test('a fresh card reviewed with "again" stays in learning, due very soon', () {
      final engine = SrsEngine();
      final result = engine.review(SrsSnapshot.fresh(), SrsRating.again);

      expect(result.snapshot.state, SrsCardState.learning);
      expect(result.interval, lessThan(const Duration(hours: 1)));
      expect(result.snapshot.stability, isNotNull);
      expect(result.snapshot.difficulty, isNotNull);
      expect(result.snapshot.lastReview, isNotNull);
    });

    test('a fresh card reviewed with "easy" graduates straight to review state', () {
      final engine = SrsEngine();
      final result = engine.review(SrsSnapshot.fresh(), SrsRating.easy);

      expect(result.snapshot.state, SrsCardState.review);
      expect(result.interval, greaterThanOrEqualTo(const Duration(days: 1)));
    });

    test('repeated "good" ratings move a card through learning into review', () {
      final engine = SrsEngine();
      var snapshot = SrsSnapshot.fresh();

      // Two "good" steps clears the default two-step learning phase.
      var result = engine.review(snapshot, SrsRating.good);
      expect(result.snapshot.state, SrsCardState.learning);
      snapshot = result.snapshot;

      result = engine.review(snapshot, SrsRating.good);
      expect(result.snapshot.state, SrsCardState.review);
      expect(result.interval, greaterThanOrEqualTo(const Duration(days: 1)));
    });

    test('"again" on a review-state card sends it to relearning', () {
      final engine = SrsEngine();
      var snapshot = SrsSnapshot.fresh();
      snapshot = engine.review(snapshot, SrsRating.easy).snapshot; // -> review state
      expect(snapshot.state, SrsCardState.review);

      final relapsed = engine.review(snapshot, SrsRating.again);
      expect(relapsed.snapshot.state, SrsCardState.relearning);
    });

    test('due date always moves forward relative to the review time', () {
      final engine = SrsEngine();
      final before = DateTime.now().toUtc();
      final result = engine.review(SrsSnapshot.fresh(), SrsRating.good);
      expect(result.snapshot.due.isAfter(before), isTrue);
    });
  });
}

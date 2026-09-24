import 'package:flutter_test/flutter_test.dart';
import 'package:stopka/core/dictation/answer_checker.dart';
import 'package:stopka/core/srs/auto_rating.dart';
import 'package:stopka/core/srs/srs_engine.dart';

void main() {
  test('the verdict decides the rating, and nothing earns easy', () {
    expect(ratingForVerdict(DictationVerdict.correct), SrsRating.good);
    expect(ratingForVerdict(DictationVerdict.typo), SrsRating.hard);
    expect(ratingForVerdict(DictationVerdict.wrong), SrsRating.again);
    expect(ratingForVerdict(DictationVerdict.skipped), SrsRating.again);
    expect(DictationVerdict.values.map(ratingForVerdict), isNot(contains(SrsRating.easy)));
  });
}

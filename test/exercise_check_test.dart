import 'package:flutter_test/flutter_test.dart';
import 'package:stopka/core/pack/exercise_check.dart';
import 'package:stopka/core/pack/pack_content.dart';

Exercise _ex(String answer, [ExerciseKind kind = ExerciseKind.gap]) =>
    Exercise(kind: kind, prompt: 'x ___', answer: answer);

void main() {
  test('case, edge punctuation and extra spaces do not matter', () {
    expect(exerciseAnswerMatches(_ex('I have already eaten.', ExerciseKind.translate), '  i have  already eaten '), isTrue);
    expect(exerciseAnswerMatches(_ex('has'), 'Has'), isTrue);
  });

  test('there is no typo tolerance: have and has are different answers', () {
    expect(exerciseAnswerMatches(_ex('has'), 'have'), isFalse);
    expect(exerciseAnswerMatches(_ex('She has eaten.', ExerciseKind.translate), 'She have eaten'), isFalse);
  });

  test('typographic apostrophes match straight ones', () {
    expect(exerciseAnswerMatches(_ex("haven't"), 'haven’t'), isTrue);
  });

  test('alternatives separated by a slash are all accepted', () {
    expect(exerciseAnswerMatches(_ex('has / has got'), 'has got'), isTrue);
    expect(exerciseAnswerMatches(_ex('has / has got'), 'had'), isFalse);
  });

  test('an empty answer is never right', () {
    expect(exerciseAnswerMatches(_ex('has'), '  '), isFalse);
  });
}

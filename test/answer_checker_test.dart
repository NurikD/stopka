import 'package:flutter_test/flutter_test.dart';
import 'package:stopka/core/dictation/answer_checker.dart';

void main() {
  group('AnswerChecker.normalize', () {
    test('trims and lowercases', () {
      expect(AnswerChecker.normalize('  Achieve  '), 'achieve');
    });

    test('collapses internal whitespace', () {
      expect(AnswerChecker.normalize('long   term'), 'long term');
    });

    test('strips a leading "to " infinitive marker', () {
      expect(AnswerChecker.normalize('to achieve'), 'achieve');
    });

    test('strips a leading article "a "', () {
      expect(AnswerChecker.normalize('a cat'), 'cat');
    });

    test('strips a leading article "the "', () {
      expect(AnswerChecker.normalize('the cat'), 'cat');
    });

    test('does not strip "a" when it is not a leading article', () {
      expect(AnswerChecker.normalize('banana'), 'banana');
    });
  });

  group('AnswerChecker.variantsOf', () {
    test('splits on slash, comma, and semicolon', () {
      expect(AnswerChecker.variantsOf('достигать / добиваться'), ['достигать', 'добиваться']);
      expect(AnswerChecker.variantsOf('cat, dog'), ['cat', 'dog']);
      expect(AnswerChecker.variantsOf('cat; dog'), ['cat', 'dog']);
    });

    test('normalizes each variant', () {
      expect(AnswerChecker.variantsOf(' Achieve / To Reach '), ['achieve', 'reach']);
    });
  });

  group('AnswerChecker.check', () {
    test('exact match is correct', () {
      expect(
        AnswerChecker.check(userInput: 'achieve', correctAnswer: 'achieve'),
        DictationVerdict.correct,
      );
    });

    test('matches any stored variant', () {
      expect(
        AnswerChecker.check(userInput: 'reach', correctAnswer: 'achieve / reach'),
        DictationVerdict.correct,
      );
    });

    test('ignores case and surrounding whitespace', () {
      expect(
        AnswerChecker.check(userInput: '  ACHIEVE  ', correctAnswer: 'achieve'),
        DictationVerdict.correct,
      );
    });

    test('ignores a leading "to " on verbs', () {
      expect(
        AnswerChecker.check(userInput: 'achieve', correctAnswer: 'to achieve'),
        DictationVerdict.correct,
      );
    });

    test('a one-letter typo on a word of 5+ letters is "typo"', () {
      expect(
        AnswerChecker.check(userInput: 'achive', correctAnswer: 'achieve'),
        DictationVerdict.typo,
      );
    });

    test('a two-letter typo on a word of 5+ letters is still "typo"', () {
      expect(
        AnswerChecker.check(userInput: 'achieb', correctAnswer: 'achieve'),
        DictationVerdict.typo,
      );
    });

    test('a typo-range distance on a short word (<5 letters) is "wrong", not "typo"', () {
      // "cat" -> "cot" is distance 1 but too short to count as a forgivable typo.
      expect(
        AnswerChecker.check(userInput: 'cot', correctAnswer: 'cat'),
        DictationVerdict.wrong,
      );
    });

    test('a distance-3+ difference is "wrong"', () {
      expect(
        AnswerChecker.check(userInput: 'xyz', correctAnswer: 'achieve'),
        DictationVerdict.wrong,
      );
    });

    test('an unrelated word is "wrong"', () {
      expect(
        AnswerChecker.check(userInput: 'banana', correctAnswer: 'achieve'),
        DictationVerdict.wrong,
      );
    });
  });
}

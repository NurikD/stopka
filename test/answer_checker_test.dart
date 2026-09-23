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

    test('folds a typographic right single quote onto a straight apostrophe', () {
      expect(AnswerChecker.normalize('don’t'), AnswerChecker.normalize("don't"));
    });

    test('folds other apostrophe look-alikes too', () {
      for (final quote in ['‘', '`', '´', 'ʼ']) {
        expect(AnswerChecker.normalize('don${quote}t'), "don't");
      }
    });

    test('folds an en dash and em dash onto a plain hyphen', () {
      expect(AnswerChecker.normalize('well–known'), 'well-known');
      expect(AnswerChecker.normalize('well—known'), 'well-known');
    });

    test('folds ё onto е', () {
      expect(AnswerChecker.normalize('ещё'), 'еще');
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

    test('a typographic apostrophe from a mobile keyboard still matches', () {
      expect(
        AnswerChecker.check(userInput: 'don’t', correctAnswer: "don't"),
        DictationVerdict.correct,
      );
    });

    test('a non-breaking-style dash still matches a stored hyphen', () {
      expect(
        AnswerChecker.check(userInput: 'well–known', correctAnswer: 'well-known'),
        DictationVerdict.correct,
      );
    });

    test('ё vs е does not cause a false mismatch', () {
      expect(
        AnswerChecker.check(userInput: 'еще', correctAnswer: 'ещё'),
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

    test('a distance-1 typo on a 5-letter word is still "typo"', () {
      // mouse -> moose, one substitution.
      expect(
        AnswerChecker.check(userInput: 'moose', correctAnswer: 'mouse'),
        DictationVerdict.typo,
      );
    });

    test('a distance-2 typo on an 8+ letter word is "typo"', () {
      // elephant -> elefant: drop the p, swap h for f — distance 2.
      expect(
        AnswerChecker.check(userInput: 'elefant', correctAnswer: 'elephant'),
        DictationVerdict.typo,
      );
    });

    test('a distance-2 pair at 5-7 letters is "wrong" — quite/quiet are different words', () {
      expect(
        AnswerChecker.check(userInput: 'quiet', correctAnswer: 'quite'),
        DictationVerdict.wrong,
      );
    });

    test('recieve/receive is distance 2 (a transposition costs 2 under plain '
        'Levenshtein), so at 7 letters (max distance 1) it is "wrong" — '
        'consistent with quite/quiet above, not a special case', () {
      expect(
        AnswerChecker.check(userInput: 'recieve', correctAnswer: 'receive'),
        DictationVerdict.wrong,
      );
    });

    test('a typo-range distance on a short word (<5 letters) is "wrong", not "typo"', () {
      // "cat" -> "cot" is distance 1 but too short to count as a forgivable typo.
      expect(
        AnswerChecker.check(userInput: 'cot', correctAnswer: 'cat'),
        DictationVerdict.wrong,
      );
    });

    test('a 4-letter word (just under the 5-letter floor) allows no typo tolerance', () {
      // book -> look, distance 1, but 4 letters is still below the floor.
      expect(
        AnswerChecker.check(userInput: 'look', correctAnswer: 'book'),
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

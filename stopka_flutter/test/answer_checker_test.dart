import 'package:flutter_test/flutter_test.dart';
import 'package:stopka/core/dictation/sentence_answer.dart';
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

    test('splits a comma-separated list of single-word synonyms', () {
      expect(AnswerChecker.variantsOf('достигать, добиваться'), ['достигать', 'добиваться']);
    });

    test('keeps a phrase with an internal comma as one variant', () {
      expect(AnswerChecker.variantsOf('несмотря на то, что'), ['несмотря на то, что']);
    });

    test('a synonym list where one entry is two words still splits', () {
      expect(AnswerChecker.variantsOf('очень хороший, отличный'), ['очень хороший', 'отличный']);
    });

    test('slash and semicolon still split a phrase that itself contains a comma', () {
      expect(
        AnswerChecker.variantsOf('несмотря на то, что / хотя'),
        ['несмотря на то, что', 'хотя'],
      );
    });
  });

  group('AnswerChecker.closestVariant', () {
    test('returns the only variant as written', () {
      expect(AnswerChecker.closestVariant(userInput: 'achive', storedAnswer: 'Achieve'), 'Achieve');
    });

    test('picks the variant the user was aiming for, in original spelling', () {
      expect(
        AnswerChecker.closestVariant(userInput: 'reech', storedAnswer: 'achieve / To reach'),
        'To reach',
      );
    });

    test('an empty input falls back to the shortest edit, i.e. a valid variant', () {
      expect(
        AnswerChecker.rawVariantsOf('achieve / reach'),
        contains(AnswerChecker.closestVariant(userInput: '', storedAnswer: 'achieve / reach')),
      );
    });

    test('keeps a phrase with an internal comma whole', () {
      expect(
        AnswerChecker.closestVariant(userInput: 'despite', storedAnswer: 'несмотря на то, что'),
        'несмотря на то, что',
      );
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

    test('recieve/receive (swapped neighbours, 7 letters) is a typo: the word is known, the order slipped', () {
      expect(
        AnswerChecker.check(userInput: 'recieve', correctAnswer: 'receive'),
        DictationVerdict.typo,
      );
    });

    test('the same swap in a 5-letter word is a different word: angel/angle, trail/trial', () {
      expect(AnswerChecker.check(userInput: 'angle', correctAnswer: 'angel'), DictationVerdict.wrong);
      expect(AnswerChecker.check(userInput: 'trial', correctAnswer: 'trail'), DictationVerdict.wrong);
    });

    test('a swap at exactly 6 letters counts as a typo', () {
      // friend -> freind
      expect(AnswerChecker.check(userInput: 'freind', correctAnswer: 'friend'), DictationVerdict.typo);
    });

    test('two swaps in a 7-letter word is too far (2 edits, limit 1)', () {
      expect(AnswerChecker.check(userInput: 'recieev', correctAnswer: 'receive'), DictationVerdict.wrong);
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

  group('sentences', () {
    DictationVerdict check(String input, String answer) => AnswerChecker.check(userInput: input, correctAnswer: answer);

    test('case, punctuation and spacing do not matter', () {
      expect(check('she has never been to london', 'She has never been to London.'), DictationVerdict.correct);
      expect(check('Yes  I do', 'Yes, I do.'), DictationVerdict.correct);
    });

    test('a contraction and its full form are the same answer', () {
      expect(check("I'm tired, I don't want to go.", 'I am tired, I do not want to go.'), DictationVerdict.correct);
      expect(check('She will not come.', "She won't come."), DictationVerdict.correct);
      expect(check('I cannot swim.', "I can't swim."), DictationVerdict.correct);
    });

    test("'s after a pronoun is either is or has", () {
      expect(check("He's been there twice.", 'He has been there twice.'), DictationVerdict.correct);
      expect(check("It's cold today.", 'It is cold today.'), DictationVerdict.correct);
    });

    test("a possessive 's is not a verb", () {
      expect(check('Tom is car is red.', "Tom's car is red."), DictationVerdict.wrong);
    });

    test('a typo in one long word is "typo"', () {
      expect(check('I have recieved your letter.', 'I have received your letter.'), DictationVerdict.typo);
    });

    test('a short grammar word has no tolerance', () {
      expect(check('She have a dog.', 'She has a dog.'), DictationVerdict.wrong);
    });

    test('a missing, extra or swapped word is wrong', () {
      expect(check('I been to Paris.', 'I have been to Paris.'), DictationVerdict.wrong);
      expect(check('I have have been to Paris.', 'I have been to Paris.'), DictationVerdict.wrong);
      expect(check('Have I been to Paris.', 'I have been to Paris.'), DictationVerdict.wrong);
    });

    test('too many typos is not knowing the sentence', () {
      expect(check('Yesterday we visitd the museun.', 'Yesterday we visited the museum.'), DictationVerdict.wrong);
    });

    test('a sentence with a comma is one variant, alternatives still split on "/"', () {
      expect(AnswerChecker.rawVariantsOf('Yes, I do.'), ['Yes, I do.']);
      expect(check('I am fine.', "I'm fine. / I am OK."), DictationVerdict.correct);
      expect(check('I am OK', "I'm fine. / I am OK."), DictationVerdict.correct);
    });

    test('short phrases keep the old word rules', () {
      expect(check('look after', 'to look after'), DictationVerdict.correct);
    });

    test('the diff marks missing and wrong words, not letters', () {
      final d = SentenceAnswer.diff(user: 'I been to Pariss.', correct: 'I have been to Paris.');
      expect(d.user.where((w) => !w.$2).map((w) => w.$1), ['Pariss.']);
      expect(d.correct.where((w) => !w.$2).map((w) => w.$1), ['have', 'Paris.']);
    });
  });
}

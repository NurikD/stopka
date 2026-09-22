import 'package:flutter_test/flutter_test.dart';
import 'package:stopka/core/dictation/answer_checker.dart';
import 'package:stopka/core/dictation/dictation_engine.dart';

List<DictationWord> _words(int count) {
  return List.generate(
    count,
    (i) => DictationWord(cardId: 'card$i', prompt: 'word$i', correctAnswer: 'answer$i'),
  );
}

void main() {
  group('DictationEngine.nextStack', () {
    test('first stack takes up to stackSize new words', () {
      final engine = DictationEngine(words: _words(20), stackSize: 12);
      final stack = engine.nextStack();
      expect(stack, hasLength(12));
      expect(stack.map((w) => w.cardId), List.generate(12, (i) => 'card$i'));
    });

    test('first stack is smaller than stackSize when there are fewer words', () {
      final engine = DictationEngine(words: _words(5), stackSize: 12);
      expect(engine.nextStack(), hasLength(5));
    });

    test('a word answered correctly (default streak 1) does not appear in the next stack', () {
      final engine = DictationEngine(words: _words(3), stackSize: 3, requiredStreak: 1);
      engine.nextStack();
      engine.recordAnswer('card0', DictationVerdict.correct);
      engine.recordAnswer('card1', DictationVerdict.wrong);
      engine.recordAnswer('card2', DictationVerdict.correct);

      final next = engine.nextStack();
      expect(next.map((w) => w.cardId), ['card1']);
    });

    test('next stack tops up with new words to refill toward stackSize', () {
      final engine = DictationEngine(words: _words(25), stackSize: 12);
      engine.nextStack(); // card0..card11
      for (var i = 0; i < 11; i++) {
        engine.recordAnswer('card$i', DictationVerdict.correct);
      }
      engine.recordAnswer('card11', DictationVerdict.wrong);

      final next = engine.nextStack();
      // 1 leftover mistake + 11 new words fills back up to 12.
      expect(next, hasLength(12));
      expect(next.first.cardId, 'card11');
    });

    test('typo and skipped both keep the word in rotation', () {
      final engine = DictationEngine(words: _words(2), stackSize: 2);
      engine.nextStack();
      engine.recordAnswer('card0', DictationVerdict.typo);
      engine.recordAnswer('card1', DictationVerdict.skipped);

      final next = engine.nextStack();
      expect(next.map((w) => w.cardId).toSet(), {'card0', 'card1'});
    });

    test('a wrong answer after partial progress resets the streak, not the mastery', () {
      final engine = DictationEngine(words: _words(1), stackSize: 1, requiredStreak: 2);
      engine.nextStack();
      engine.recordAnswer('card0', DictationVerdict.correct);
      expect(engine.isFinished, isFalse);

      engine.nextStack();
      engine.recordAnswer('card0', DictationVerdict.wrong);
      expect(engine.isFinished, isFalse);

      engine.nextStack();
      engine.recordAnswer('card0', DictationVerdict.correct);
      expect(engine.isFinished, isFalse); // streak was reset, needs 2 in a row again

      engine.nextStack();
      engine.recordAnswer('card0', DictationVerdict.correct);
      expect(engine.isFinished, isTrue);
    });

    test('requiredStreak of 2 needs two consecutive correct answers', () {
      final engine = DictationEngine(words: _words(1), stackSize: 1, requiredStreak: 2);
      engine.nextStack();
      engine.recordAnswer('card0', DictationVerdict.correct);
      expect(engine.isFinished, isFalse);

      engine.nextStack();
      engine.recordAnswer('card0', DictationVerdict.correct);
      expect(engine.isFinished, isTrue);
    });
  });

  group('DictationEngine session lifecycle', () {
    test('is not finished until every word is mastered', () {
      final engine = DictationEngine(words: _words(3), stackSize: 3);
      expect(engine.isFinished, isFalse);
      engine.nextStack();
      engine.recordAnswer('card0', DictationVerdict.correct);
      engine.recordAnswer('card1', DictationVerdict.correct);
      expect(engine.isFinished, isFalse);
      engine.recordAnswer('card2', DictationVerdict.correct);
      expect(engine.isFinished, isTrue);
    });

    test('roundIndex increments once per nextStack call', () {
      final engine = DictationEngine(words: _words(2), stackSize: 1);
      expect(engine.roundIndex, 0);
      engine.nextStack();
      expect(engine.roundIndex, 1);
      engine.recordAnswer('card0', DictationVerdict.correct);
      engine.nextStack();
      expect(engine.roundIndex, 2);
    });

    test('mastery order accumulates in masteredWords', () {
      final engine = DictationEngine(words: _words(2), stackSize: 2);
      engine.nextStack();
      engine.recordAnswer('card0', DictationVerdict.correct);
      engine.recordAnswer('card1', DictationVerdict.correct);
      expect(engine.masteredWords.map((w) => w.cardId).toSet(), {'card0', 'card1'});
    });

    test('a whole session converges to zero errors (integration-style smoke test)', () {
      final engine = DictationEngine(words: _words(30), stackSize: 12, requiredStreak: 1);
      var guard = 0;
      while (!engine.isFinished) {
        guard++;
        if (guard > 1000) fail('engine did not converge');
        final stack = engine.nextStack();
        for (final word in stack) {
          // Every third word answered wrong once, to exercise carry-over.
          final verdict =
              int.parse(word.cardId.substring(4)) % 3 == 0 && word.streak == 0 && guard == 1
                  ? DictationVerdict.wrong
                  : DictationVerdict.correct;
          engine.recordAnswer(word.cardId, verdict);
        }
      }
      expect(engine.masteredWords, hasLength(30));
    });
  });
}

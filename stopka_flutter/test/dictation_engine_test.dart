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

  group('DictationEngine.unintroducedCount', () {
    test('drops as new words are pulled into stacks', () {
      final engine = DictationEngine(words: _words(30), stackSize: 12);
      expect(engine.unintroducedCount, 30);
      engine.nextStack();
      expect(engine.unintroducedCount, 18);
    });

    test('is zero once everything has been introduced', () {
      final engine = DictationEngine(words: _words(5), stackSize: 12);
      engine.nextStack();
      expect(engine.unintroducedCount, 0);
    });
  });

  group('DictationEngine.resume', () {
    test('empty history resumes to the exact same state as a fresh engine', () {
      final live = DictationEngine(words: _words(5), stackSize: 3);
      final resumed = DictationEngine.resume(words: _words(5), answers: [], stackSize: 3);

      expect(resumed.roundIndex, live.roundIndex);
      expect(resumed.isFinished, live.isFinished);
      expect(resumed.nextStack().map((w) => w.cardId), live.nextStack().map((w) => w.cardId));
    });

    test('resuming mid-session reproduces the same mastered set and next stack as the live run', () {
      // Live run: 6 words, stack size 3. Round 1: card0 wrong, card1/card2 correct.
      final liveWords = _words(6);
      final live = DictationEngine(words: liveWords, stackSize: 3, requiredStreak: 1);
      live.nextStack();
      live.recordAnswer('card0', DictationVerdict.wrong);
      live.recordAnswer('card1', DictationVerdict.correct);
      live.recordAnswer('card2', DictationVerdict.correct);
      // Round 2: card0 (carried over) correct, card3/card4 (new) correct.
      live.nextStack();
      live.recordAnswer('card0', DictationVerdict.correct);
      live.recordAnswer('card3', DictationVerdict.correct);
      live.recordAnswer('card4', DictationVerdict.correct);

      final history = [
        const DictationHistoryEntry(cardId: 'card0', roundIndex: 1, verdict: DictationVerdict.wrong),
        const DictationHistoryEntry(cardId: 'card1', roundIndex: 1, verdict: DictationVerdict.correct),
        const DictationHistoryEntry(cardId: 'card2', roundIndex: 1, verdict: DictationVerdict.correct),
        const DictationHistoryEntry(cardId: 'card0', roundIndex: 2, verdict: DictationVerdict.correct),
        const DictationHistoryEntry(cardId: 'card3', roundIndex: 2, verdict: DictationVerdict.correct),
        const DictationHistoryEntry(cardId: 'card4', roundIndex: 2, verdict: DictationVerdict.correct),
      ];
      final resumed = DictationEngine.resume(words: _words(6), answers: history, stackSize: 3, requiredStreak: 1);

      expect(resumed.roundIndex, live.roundIndex);
      expect(
        resumed.masteredWords.map((w) => w.cardId).toSet(),
        live.masteredWords.map((w) => w.cardId).toSet(),
      );
      expect(resumed.nextStack().map((w) => w.cardId), live.nextStack().map((w) => w.cardId));
    });

    test('a word left mid-answer (no history entry for the last round) falls into the next stack', () {
      // Round 1 stack is card0, card1; only card0 got answered before the app died.
      final history = [
        const DictationHistoryEntry(cardId: 'card0', roundIndex: 1, verdict: DictationVerdict.correct),
      ];
      final resumed = DictationEngine.resume(words: _words(2), answers: history, stackSize: 2, requiredStreak: 1);

      expect(resumed.masteredWords.map((w) => w.cardId), ['card0']);
      // card1 was never recorded, so it's still active and comes right back.
      expect(resumed.nextStack().map((w) => w.cardId), ['card1']);
    });

    test('resuming preserves a partially-built streak toward requiredStreak > 1', () {
      final history = [
        const DictationHistoryEntry(cardId: 'card0', roundIndex: 1, verdict: DictationVerdict.correct),
      ];
      final resumed = DictationEngine.resume(words: _words(1), answers: history, stackSize: 1, requiredStreak: 2);

      expect(resumed.isFinished, isFalse);
      resumed.nextStack();
      resumed.recordAnswer('card0', DictationVerdict.correct);
      expect(resumed.isFinished, isTrue); // second correct in a row completes the streak
    });
  });
}

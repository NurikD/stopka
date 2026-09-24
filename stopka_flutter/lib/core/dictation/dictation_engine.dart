import 'answer_checker.dart';

/// One persisted answer, as needed to replay a session — see
/// [DictationEngine.resume].
class DictationHistoryEntry {
  final String cardId;
  final int roundIndex;
  final DictationVerdict verdict;

  const DictationHistoryEntry({required this.cardId, required this.roundIndex, required this.verdict});
}

class DictationWord {
  final String cardId;
  final String prompt;
  final String correctAnswer;
  int streak = 0;

  DictationWord({required this.cardId, required this.prompt, required this.correctAnswer});
}

/// Forms dictation stacks like a driving-test question pile: keep cycling
/// until every word has been answered correctly [requiredStreak] times in
/// a row. See PLAN.md "Ключевой режим: диктант", steps 2-6.
class DictationEngine {
  final int stackSize;
  final int requiredStreak;

  final List<DictationWord> _unintroduced;
  final List<DictationWord> _active = [];
  final List<DictationWord> _mastered = [];

  int roundIndex = 0;

  DictationEngine({
    required List<DictationWord> words,
    this.stackSize = 12,
    this.requiredStreak = 1,
  }) : _unintroduced = List.of(words);

  /// Rebuilds a session's state from persisted answer history, for
  /// resuming after the app was killed mid-session. Replays each round's
  /// answers through the exact same [nextStack]/[recordAnswer] a live
  /// session uses, so the result is indistinguishable from an engine that
  /// never stopped. A word the user was mid-answer on when the app died
  /// simply has no history entry and falls back into the next stack, same
  /// as any other unanswered word.
  factory DictationEngine.resume({
    required List<DictationWord> words,
    required List<DictationHistoryEntry> answers,
    int stackSize = 12,
    int requiredStreak = 1,
  }) {
    final engine = DictationEngine(words: words, stackSize: stackSize, requiredStreak: requiredStreak);

    final byRound = <int, List<DictationHistoryEntry>>{};
    for (final answer in answers) {
      byRound.putIfAbsent(answer.roundIndex, () => []).add(answer);
    }

    final rounds = byRound.keys.toList()..sort();
    for (final round in rounds) {
      engine.nextStack();
      for (final answer in byRound[round]!) {
        engine.recordAnswer(answer.cardId, answer.verdict);
      }
    }

    return engine;
  }

  bool get isFinished => _unintroduced.isEmpty && _active.isEmpty;

  /// Words that haven't appeared in any stack yet. The dictation screen
  /// turns this into the visible pile ("сколько стопок осталось").
  int get unintroducedCount => _unintroduced.length;

  List<DictationWord> get masteredWords => List.unmodifiable(_mastered);

  /// Builds the next stack: words still in rotation, topped up with new
  /// words up to [stackSize] if there's room. Must not be called again
  /// until every word from the current stack has been recorded.
  List<DictationWord> nextStack() {
    final capacity = stackSize - _active.length;
    if (capacity > 0 && _unintroduced.isNotEmpty) {
      final take = capacity < _unintroduced.length ? capacity : _unintroduced.length;
      _active.addAll(_unintroduced.take(take));
      _unintroduced.removeRange(0, take);
    }
    roundIndex++;
    return List.unmodifiable(_active);
  }

  /// Records one word's verdict for the current stack. A word graduates
  /// out of rotation once its correct-answer streak reaches
  /// [requiredStreak]; anything else resets the streak but keeps the word
  /// in rotation for the next stack.
  void recordAnswer(String cardId, DictationVerdict verdict) {
    final word = _active.firstWhere((w) => w.cardId == cardId);
    if (verdict == DictationVerdict.correct) {
      word.streak++;
      if (word.streak >= requiredStreak) {
        _active.remove(word);
        _mastered.add(word);
      }
    } else {
      word.streak = 0;
    }
  }
}

import 'answer_checker.dart';

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

  bool get isFinished => _unintroduced.isEmpty && _active.isEmpty;

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

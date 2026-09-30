/// How a card is asked. [listen] plays the English word and expects it typed
/// back: the audio skill, with its own review schedule, since hearing a word
/// and producing it from Russian are different memories.
enum DictationDirection { ruEn, enRu, listen }

extension DictationDirectionCard on DictationDirection {
  /// The answer is typed in English (letter-by-letter diff, no AI appeal).
  bool get answersInEnglish => this != DictationDirection.enRu;

  /// The prompt is heard rather than read.
  bool get isAudio => this == DictationDirection.listen;

  /// What the learner is given: the Russian side, or the English word (shown
  /// for [enRu], spoken for [listen]).
  String promptOf({required String term, required String translation}) =>
      this == DictationDirection.ruEn ? translation : term;

  String answerOf({required String term, required String translation}) =>
      this == DictationDirection.enRu ? translation : term;
}

class DictationSession {
  final String id;
  final String setId;
  final DictationDirection direction;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final int roundsCount;
  final int totalWords;
  final int stackSize;
  final int requiredStreak;

  const DictationSession({
    required this.id,
    required this.setId,
    required this.direction,
    required this.startedAt,
    this.finishedAt,
    required this.roundsCount,
    required this.totalWords,
    required this.stackSize,
    required this.requiredStreak,
  });
}

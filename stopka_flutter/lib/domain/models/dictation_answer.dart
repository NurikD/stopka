enum DictationAnswerVerdict { correct, typo, wrong, skipped }

enum DictationCheckedBy { local, llm }

class DictationAnswer {
  final String id;
  final String sessionId;
  final String cardId;
  final int roundIndex;
  final String userInput;
  final DictationAnswerVerdict verdict;
  final DictationCheckedBy checkedBy;

  const DictationAnswer({
    required this.id,
    required this.sessionId,
    required this.cardId,
    required this.roundIndex,
    required this.userInput,
    required this.verdict,
    required this.checkedBy,
  });
}

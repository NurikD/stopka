enum DictationDirection { ruEn, enRu }

class DictationSession {
  final String id;
  final String setId;
  final DictationDirection direction;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final int roundsCount;
  final int totalWords;

  const DictationSession({
    required this.id,
    required this.setId,
    required this.direction,
    required this.startedAt,
    this.finishedAt,
    required this.roundsCount,
    required this.totalWords,
  });
}

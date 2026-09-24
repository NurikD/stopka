import '../../core/pack/pack_content.dart';

/// Read-only questions the session planner and its summary ask of the data.
abstract class SessionStatsRepository {
  /// Cards of [setId] that no dictation has ever touched (they have no SRS
  /// state yet), so they are the "new words" of a unit.
  Future<int> unlearnedCardCount(String setId);

  /// Distinct cards rated "again" at or after [since], most recent first.
  Future<List<String>> lapsedCardIdsSince(DateTime since);

  /// Mistakes recorded at or after [since], grouped by skill and category,
  /// most frequent first.
  Future<List<MistakeGroup>> mistakesSince(DateTime since);

  /// The latest recorded mistakes, newest first.
  Future<List<MistakeItem>> recentMistakes({int limit = 20});

  /// Parts of a pack the learner struggles with lately: grammar or writing
  /// with at least [weakMistakeCount] mistakes since [since], or any part
  /// answered under 60% right (at least 4 answers) since [since].
  Future<Set<PackPart>> weakParts(DateTime since);
}

const int weakMistakeCount = 2;

class MistakeItem {
  final String skill;
  final String category;
  final String original;
  final String corrected;
  final String explanation;
  final DateTime createdAt;

  const MistakeItem({
    required this.skill,
    required this.category,
    required this.original,
    required this.corrected,
    required this.explanation,
    required this.createdAt,
  });
}

class MistakeGroup {
  final String skill;
  final String category;
  final int count;

  const MistakeGroup({required this.skill, required this.category, required this.count});
}

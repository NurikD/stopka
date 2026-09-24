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
}

class MistakeGroup {
  final String skill;
  final String category;
  final int count;

  const MistakeGroup({required this.skill, required this.category, required this.count});
}

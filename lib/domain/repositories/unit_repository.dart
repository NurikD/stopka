import '../models/unit.dart';

abstract class UnitRepository {
  Stream<List<Unit>> watchUnits(String courseId);

  Future<Unit?> getUnit(String id);

  Future<Unit> createUnit({
    required String courseId,
    required String code,
    required String title,
    String grammarTopic = '',
    String vocabTopic = '',
    int orderIndex = 0,
  });

  Future<void> updateUnit(Unit unit);

  Future<void> deleteUnit(String id);
}

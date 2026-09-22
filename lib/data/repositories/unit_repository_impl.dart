import 'package:drift/drift.dart';

import '../../domain/models/unit.dart';
import '../../domain/repositories/unit_repository.dart';
import '../db/app_database.dart';

Unit _toDomain(UnitRow row) {
  return Unit(
    id: row.id,
    courseId: row.courseId,
    code: row.code,
    title: row.title,
    grammarTopic: row.grammarTopic,
    vocabTopic: row.vocabTopic,
    orderIndex: row.orderIndex,
    studiedAt: row.studiedAt,
    ownerId: row.ownerId,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
    deletedAt: row.deletedAt,
  );
}

class DriftUnitRepository implements UnitRepository {
  final AppDatabase _db;
  final String _ownerId;

  DriftUnitRepository(this._db, this._ownerId);

  @override
  Stream<List<Unit>> watchUnits(String courseId) {
    final query = _db.select(_db.units)
      ..where((t) => t.deletedAt.isNull() & t.courseId.equals(courseId))
      ..orderBy([(t) => OrderingTerm(expression: t.orderIndex)]);
    return query.watch().map((rows) => rows.map(_toDomain).toList());
  }

  @override
  Future<Unit?> getUnit(String id) async {
    final row = await (_db.select(_db.units)..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<Unit> createUnit({
    required String courseId,
    required String code,
    required String title,
    String grammarTopic = '',
    String vocabTopic = '',
    int orderIndex = 0,
  }) async {
    final row = await _db.into(_db.units).insertReturning(
          UnitsCompanion.insert(
            courseId: courseId,
            code: code,
            title: title,
            grammarTopic: Value(grammarTopic),
            vocabTopic: Value(vocabTopic),
            orderIndex: Value(orderIndex),
            ownerId: _ownerId,
          ),
        );
    return _toDomain(row);
  }

  @override
  Future<void> updateUnit(Unit unit) async {
    await (_db.update(_db.units)..where((t) => t.id.equals(unit.id))).write(
      UnitsCompanion(
        code: Value(unit.code),
        title: Value(unit.title),
        grammarTopic: Value(unit.grammarTopic),
        vocabTopic: Value(unit.vocabTopic),
        orderIndex: Value(unit.orderIndex),
        studiedAt: Value(unit.studiedAt),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> deleteUnit(String id) async {
    await (_db.update(_db.units)..where((t) => t.id.equals(id))).write(
      UnitsCompanion(deletedAt: Value(DateTime.now())),
    );
  }
}

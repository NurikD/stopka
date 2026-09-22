import 'package:drift/drift.dart';

import '../../domain/models/word_set.dart' as domain;
import '../../domain/repositories/word_set_repository.dart';
import '../db/app_database.dart';
import '../db/tables.dart' show WordSetSource;

domain.WordSet _toDomain(WordSetRow row) {
  return domain.WordSet(
    id: row.id,
    unitId: row.unitId,
    title: row.title,
    source: domain.WordSetSource.values.byName(row.source.name),
    formatVersion: row.formatVersion,
    ownerId: row.ownerId,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
    deletedAt: row.deletedAt,
  );
}

class DriftWordSetRepository implements WordSetRepository {
  final AppDatabase _db;
  final String _ownerId;

  DriftWordSetRepository(this._db, this._ownerId);

  @override
  Stream<List<domain.WordSet>> watchWordSets({String? unitId}) {
    final query = _db.select(_db.wordSets)
      ..where((t) {
        final base = t.deletedAt.isNull() & t.ownerId.equals(_ownerId);
        return unitId == null ? base : base & t.unitId.equals(unitId);
      })
      ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]);
    return query.watch().map((rows) => rows.map(_toDomain).toList());
  }

  @override
  Future<domain.WordSet?> getWordSet(String id) async {
    final row = await (_db.select(_db.wordSets)..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<domain.WordSet> createWordSet({
    String? unitId,
    required String title,
    required domain.WordSetSource source,
  }) async {
    final row = await _db.into(_db.wordSets).insertReturning(
          WordSetsCompanion.insert(
            unitId: Value(unitId),
            title: title,
            source: WordSetSource.values.byName(source.name),
            ownerId: _ownerId,
          ),
        );
    return _toDomain(row);
  }

  @override
  Future<void> updateWordSet(domain.WordSet wordSet) async {
    await (_db.update(_db.wordSets)..where((t) => t.id.equals(wordSet.id))).write(
      WordSetsCompanion(
        unitId: Value(wordSet.unitId),
        title: Value(wordSet.title),
        source: Value(WordSetSource.values.byName(wordSet.source.name)),
        formatVersion: Value(wordSet.formatVersion),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> deleteWordSet(String id) async {
    await (_db.update(_db.wordSets)..where((t) => t.id.equals(id))).write(
      WordSetsCompanion(deletedAt: Value(DateTime.now())),
    );
  }
}

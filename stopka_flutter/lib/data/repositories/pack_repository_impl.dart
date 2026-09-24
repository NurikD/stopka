import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/pack/pack_content.dart';
import '../../domain/models/unit_pack.dart';
import '../../domain/repositories/pack_repository.dart';
import '../db/app_database.dart';

UnitPack _toDomain(UnitPackRow row) {
  final payload = <PackPart, Map<String, dynamic>>{};
  final rawPayload = jsonDecode(row.payload) as Map<String, dynamic>;
  final statuses = <PackPart, PartStatus>{};
  final rawStatuses = jsonDecode(row.statuses) as Map<String, dynamic>;
  for (final part in PackPart.values) {
    final p = rawPayload[part.name];
    if (p is Map<String, dynamic>) payload[part] = p;
    final status = PartStatus.values.where((s) => s.name == rawStatuses[part.name]).firstOrNull;
    if (status != null) statuses[part] = status;
  }
  return UnitPack(
    id: row.id,
    packKey: row.packKey,
    level: row.level,
    grammarTopic: row.grammarTopic,
    vocabTopic: row.vocabTopic,
    interest: row.interest,
    schemaVersion: row.schemaVersion,
    payload: payload,
    statuses: statuses,
  );
}

class DriftPackRepository implements PackRepository {
  final AppDatabase _db;
  final String _ownerId;

  DriftPackRepository(this._db, this._ownerId);

  SimpleSelectStatement<$UnitPacksTable, UnitPackRow> _byId(String id) =>
      _db.select(_db.unitPacks)..where((t) => t.id.equals(id) & t.deletedAt.isNull());

  @override
  Future<UnitPack?> findByKey(PackKey key) async {
    final row = await (_db.select(_db.unitPacks)
          ..where((t) => t.packKey.equals(key.hash) & t.ownerId.equals(_ownerId) & t.deletedAt.isNull()))
        .getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<UnitPack> getOrCreate(PackKey key) async {
    final existing = await findByKey(key);
    if (existing != null) return existing;
    final row = await _db.into(_db.unitPacks).insertReturning(
          UnitPacksCompanion.insert(
            packKey: key.hash,
            level: key.level,
            grammarTopic: Value(key.grammarTopic),
            vocabTopic: Value(key.vocabTopic),
            interest: Value(key.interest),
            schemaVersion: key.schemaVersion,
            ownerId: _ownerId,
          ),
        );
    return _toDomain(row);
  }

  @override
  Future<UnitPack?> getPack(String id) async {
    final row = await _byId(id).getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Stream<UnitPack?> watchPack(String id) {
    return _byId(id).watchSingleOrNull().map((row) => row == null ? null : _toDomain(row));
  }

  @override
  Future<void> setPart(
    String packId,
    PackPart part, {
    Map<String, dynamic>? payload,
    required PartStatus status,
  }) {
    return _db.transaction(() async {
      final row = await _byId(packId).getSingle();
      final payloads = jsonDecode(row.payload) as Map<String, dynamic>;
      final statuses = jsonDecode(row.statuses) as Map<String, dynamic>;
      if (status == PartStatus.ready && payload != null) {
        payloads[part.name] = payload;
      } else {
        payloads.remove(part.name);
      }
      statuses[part.name] = status.name;
      await (_db.update(_db.unitPacks)..where((t) => t.id.equals(packId))).write(
        UnitPacksCompanion(
          payload: Value(jsonEncode(payloads)),
          statuses: Value(jsonEncode(statuses)),
          updatedAt: Value(DateTime.now()),
        ),
      );
    });
  }

  @override
  Future<void> saveProgress(String packId, PackPart part, {required int score, required int total}) async {
    await _db.into(_db.packProgresses).insert(
          PackProgressesCompanion.insert(
            packId: packId,
            part: part.name,
            completedAt: DateTime.now(),
            score: Value(score),
            total: Value(total),
            ownerId: _ownerId,
          ),
        );
  }

  SimpleSelectStatement<$PackProgressesTable, PackProgressRow> _progressQuery(String packId) =>
      _db.select(_db.packProgresses)
        ..where((t) => t.packId.equals(packId) & t.deletedAt.isNull())
        ..orderBy([(t) => OrderingTerm(expression: t.completedAt)]);

  Map<PackPart, PackProgress> _latest(List<PackProgressRow> rows) {
    final latest = <PackPart, PackProgress>{};
    for (final r in rows) {
      final part = PackPart.values.where((p) => p.name == r.part).firstOrNull;
      if (part == null) continue;
      latest[part] = PackProgress(part: part, completedAt: r.completedAt, score: r.score, total: r.total);
    }
    return latest;
  }

  @override
  Future<Map<PackPart, PackProgress>> getProgress(String packId) async => _latest(await _progressQuery(packId).get());

  @override
  Stream<Map<PackPart, PackProgress>> watchProgress(String packId) {
    return _progressQuery(packId).watch().map(_latest);
  }

  @override
  Future<void> logAttempt(
    String packId,
    PackPart part, {
    required int itemIndex,
    required String userAnswer,
    required bool isCorrect,
  }) async {
    await _db.into(_db.exerciseAttempts).insert(
          ExerciseAttemptsCompanion.insert(
            packId: packId,
            part: part.name,
            itemIndex: itemIndex,
            userAnswer: userAnswer,
            isCorrect: isCorrect,
            ownerId: _ownerId,
          ),
        );
  }

  @override
  Future<void> saveWritingAttempt(
    String packId, {
    required String userText,
    required String correctedText,
    required String nativeText,
    required String summary,
  }) async {
    await _db.into(_db.writingAttempts).insert(
          WritingAttemptsCompanion.insert(
            packId: packId,
            userText: userText,
            correctedText: Value(correctedText),
            nativeText: Value(nativeText),
            summary: Value(summary),
            ownerId: _ownerId,
          ),
        );
  }

  @override
  Future<void> addMistakes(String? packId, List<MistakeInput> mistakes) async {
    for (final m in mistakes) {
      await _db.into(_db.mistakes).insert(
            MistakesCompanion.insert(
              skill: m.skill,
              category: m.category,
              original: Value(m.original),
              corrected: Value(m.corrected),
              explanation: Value(m.explanation),
              packId: Value(packId),
              ownerId: _ownerId,
            ),
          );
    }
  }
}

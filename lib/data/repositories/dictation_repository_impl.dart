import 'package:drift/drift.dart';

import '../../domain/models/dictation_answer.dart' as domain;
import '../../domain/models/dictation_session.dart' as domain;
import '../../domain/repositories/dictation_repository.dart';
import '../db/app_database.dart';
import '../db/tables.dart' as db;

domain.DictationSession _sessionToDomain(DictationSessionRow row) {
  return domain.DictationSession(
    id: row.id,
    setId: row.setId,
    direction: domain.DictationDirection.values.byName(row.direction.name),
    startedAt: row.startedAt,
    finishedAt: row.finishedAt,
    roundsCount: row.roundsCount,
    totalWords: row.totalWords,
  );
}

domain.DictationAnswer _answerToDomain(DictationAnswerRow row) {
  return domain.DictationAnswer(
    id: row.id,
    sessionId: row.sessionId,
    cardId: row.cardId,
    roundIndex: row.roundIndex,
    userInput: row.userInput,
    verdict: domain.DictationAnswerVerdict.values.byName(row.verdict.name),
    checkedBy: domain.DictationCheckedBy.values.byName(row.checkedBy.name),
  );
}

class DriftDictationRepository implements DictationRepository {
  final AppDatabase _db;
  final String _ownerId;

  DriftDictationRepository(this._db, this._ownerId);

  @override
  Stream<List<domain.DictationSession>> watchSessions(String setId) {
    final query = _db.select(_db.dictationSessions)
      ..where((t) => t.deletedAt.isNull() & t.setId.equals(setId))
      ..orderBy([(t) => OrderingTerm(expression: t.startedAt, mode: OrderingMode.desc)]);
    return query.watch().map((rows) => rows.map(_sessionToDomain).toList());
  }

  @override
  Future<domain.DictationSession> startSession({
    required String setId,
    required domain.DictationDirection direction,
  }) async {
    final row = await _db.into(_db.dictationSessions).insertReturning(
          DictationSessionsCompanion.insert(
            setId: setId,
            direction: db.DictationDirection.values.byName(direction.name),
            ownerId: _ownerId,
          ),
        );
    return _sessionToDomain(row);
  }

  @override
  Future<void> finishSession(String sessionId, {required int roundsCount, required int totalWords}) async {
    await (_db.update(_db.dictationSessions)..where((t) => t.id.equals(sessionId))).write(
      DictationSessionsCompanion(
        finishedAt: Value(DateTime.now()),
        roundsCount: Value(roundsCount),
        totalWords: Value(totalWords),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<domain.DictationAnswer> recordAnswer({
    required String sessionId,
    required String cardId,
    required int roundIndex,
    required String userInput,
    required domain.DictationAnswerVerdict verdict,
    domain.DictationCheckedBy checkedBy = domain.DictationCheckedBy.local,
  }) async {
    final row = await _db.into(_db.dictationAnswers).insertReturning(
          DictationAnswersCompanion.insert(
            sessionId: sessionId,
            cardId: cardId,
            roundIndex: roundIndex,
            userInput: userInput,
            verdict: db.DictationVerdictColumn.values.byName(verdict.name),
            checkedBy: Value(db.DictationCheckedBy.values.byName(checkedBy.name)),
            ownerId: _ownerId,
          ),
        );
    return _answerToDomain(row);
  }

  @override
  Future<void> updateAnswerVerdict(
    String answerId,
    domain.DictationAnswerVerdict verdict,
    domain.DictationCheckedBy checkedBy,
  ) async {
    await (_db.update(_db.dictationAnswers)..where((t) => t.id.equals(answerId))).write(
      DictationAnswersCompanion(
        verdict: Value(db.DictationVerdictColumn.values.byName(verdict.name)),
        checkedBy: Value(db.DictationCheckedBy.values.byName(checkedBy.name)),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<List<domain.DictationAnswer>> getAnswers(String sessionId) async {
    final rows = await (_db.select(_db.dictationAnswers)..where((t) => t.sessionId.equals(sessionId))).get();
    return rows.map(_answerToDomain).toList();
  }
}

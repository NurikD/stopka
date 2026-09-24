import 'package:drift/drift.dart';

import '../../domain/models/card_state.dart' as domain;
import '../../domain/models/dictation_session.dart';
import '../../domain/repositories/card_state_repository.dart';
import '../db/app_database.dart';
import '../db/tables.dart' as db;

domain.CardState _toDomain(CardStateRow row) {
  return domain.CardState(
    id: row.id,
    cardId: row.cardId,
    direction: DictationDirection.values.byName(row.direction.name),
    due: row.due,
    stability: row.stability,
    difficulty: row.difficulty,
    step: row.step,
    reps: row.reps,
    lapses: row.lapses,
    state: domain.SrsState.values.byName(row.state.name),
    lastReview: row.lastReview,
  );
}

class DriftCardStateRepository implements CardStateRepository {
  final AppDatabase _db;
  final String _ownerId;

  DriftCardStateRepository(this._db, this._ownerId);

  @override
  Future<domain.CardState> ensureState(String cardId, DictationDirection direction) async {
    final dbDirection = db.DictationDirection.values.byName(direction.name);
    final existing = await (_db.select(_db.cardStates)
          ..where((t) => t.cardId.equals(cardId) & t.direction.equalsValue(dbDirection) & t.deletedAt.isNull()))
        .getSingleOrNull();
    if (existing != null) return _toDomain(existing);

    final row = await _db.into(_db.cardStates).insertReturning(
          CardStatesCompanion.insert(
            cardId: cardId,
            direction: dbDirection,
            due: DateTime.now().toUtc(),
            ownerId: _ownerId,
          ),
        );
    return _toDomain(row);
  }

  @override
  Future<void> saveState(domain.CardState state) async {
    await (_db.update(_db.cardStates)..where((t) => t.id.equals(state.id))).write(
      CardStatesCompanion(
        due: Value(state.due),
        stability: Value(state.stability),
        difficulty: Value(state.difficulty),
        step: Value(state.step),
        reps: Value(state.reps),
        lapses: Value(state.lapses),
        state: Value(db.SrsCardStateColumn.values.byName(state.state.name)),
        lastReview: Value(state.lastReview),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<List<domain.CardState>> getDueForReview({required DateTime now}) async {
    final rows = await (_db.select(_db.cardStates)
          ..where((t) =>
              t.deletedAt.isNull() & t.ownerId.equals(_ownerId) & t.reps.isBiggerThanValue(0) & t.due.isSmallerOrEqualValue(now))
          ..orderBy([(t) => OrderingTerm(expression: t.due)]))
        .get();
    return rows.map(_toDomain).toList();
  }

  @override
  Future<List<domain.CardState>> getNewCards({required int limit}) async {
    final rows = await (_db.select(_db.cardStates)
          ..where((t) => t.deletedAt.isNull() & t.ownerId.equals(_ownerId) & t.reps.equals(0))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt)])
          ..limit(limit))
        .get();
    return rows.map(_toDomain).toList();
  }

  @override
  Stream<int> watchDueCount(DateTime now) {
    final query = _db.selectOnly(_db.cardStates)
      ..addColumns([_db.cardStates.id.count()])
      ..where(_db.cardStates.deletedAt.isNull() &
          _db.cardStates.ownerId.equals(_ownerId) &
          _db.cardStates.reps.isBiggerThanValue(0) &
          _db.cardStates.due.isSmallerOrEqualValue(now));
    return query.watchSingle().map((row) => row.read(_db.cardStates.id.count()) ?? 0);
  }

  @override
  Stream<int> watchNewCount() {
    final query = _db.selectOnly(_db.cardStates)
      ..addColumns([_db.cardStates.id.count()])
      ..where(_db.cardStates.deletedAt.isNull() & _db.cardStates.ownerId.equals(_ownerId) & _db.cardStates.reps.equals(0));
    return query.watchSingle().map((row) => row.read(_db.cardStates.id.count()) ?? 0);
  }

  @override
  Future<void> logReview({required String cardStateId, required domain.ReviewRating rating, DateTime? at}) async {
    await _db.into(_db.reviewLogs).insert(
          ReviewLogsCompanion.insert(
            cardStateId: cardStateId,
            rating: db.SrsRatingColumn.values.byName(rating.name),
            reviewedAt: (at ?? DateTime.now()).toUtc(),
            ownerId: _ownerId,
          ),
        );
  }

  @override
  Future<int> getStreakDays() async {
    final logs = await (_db.select(_db.reviewLogs)
          ..where((t) => t.deletedAt.isNull() & t.ownerId.equals(_ownerId)))
        .get();
    // Reviews from before the log existed only survive as lastReview; keep
    // counting them so upgrading doesn't reset anyone's streak to zero.
    final states = await (_db.select(_db.cardStates)
          ..where((t) => t.deletedAt.isNull() & t.ownerId.equals(_ownerId) & t.lastReview.isNotNull()))
        .get();

    final reviewDays = {
      ...logs.map((l) => _dateOnly(l.reviewedAt.toLocal())),
      ...states.map((r) => _dateOnly(r.lastReview!.toLocal())),
    };
    if (reviewDays.isEmpty) return 0;

    var cursor = _dateOnly(DateTime.now());
    if (!reviewDays.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
      if (!reviewDays.contains(cursor)) return 0;
    }

    var streak = 0;
    while (reviewDays.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
}

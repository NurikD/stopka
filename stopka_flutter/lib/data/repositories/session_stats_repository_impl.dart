import 'package:drift/drift.dart';

import '../../core/pack/pack_content.dart';
import '../../domain/repositories/session_stats_repository.dart';
import '../db/app_database.dart';
import '../db/tables.dart' as db;

class DriftSessionStatsRepository implements SessionStatsRepository {
  final AppDatabase _db;
  final String _ownerId;

  DriftSessionStatsRepository(this._db, this._ownerId);

  @override
  Future<int> unlearnedCardCount(String setId) async {
    final cards = await (_db.select(_db.cards)..where((t) => t.setId.equals(setId) & t.deletedAt.isNull())).get();
    if (cards.isEmpty) return 0;
    final touched = await (_db.select(_db.cardStates)
          ..where((t) => t.cardId.isIn(cards.map((c) => c.id)) & t.deletedAt.isNull()))
        .get();
    final touchedIds = touched.map((s) => s.cardId).toSet();
    return cards.where((c) => !touchedIds.contains(c.id)).length;
  }

  @override
  Future<List<String>> lapsedCardIdsSince(DateTime since) async {
    final logs = await (_db.select(_db.reviewLogs)
          ..where((t) =>
              t.deletedAt.isNull() &
              t.ownerId.equals(_ownerId) &
              t.rating.equalsValue(db.SrsRatingColumn.again) &
              t.reviewedAt.isBiggerOrEqualValue(since.toUtc()))
          ..orderBy([(t) => OrderingTerm.desc(t.reviewedAt)]))
        .get();
    if (logs.isEmpty) return const [];
    final states = await (_db.select(_db.cardStates)..where((t) => t.id.isIn(logs.map((l) => l.cardStateId)))).get();
    final cardByState = {for (final s in states) s.id: s.cardId};
    final seen = <String>{};
    return [
      for (final log in logs)
        if (cardByState[log.cardStateId] case final cardId? when seen.add(cardId)) cardId,
    ];
  }

  @override
  Future<List<MistakeGroup>> mistakesSince(DateTime since) async {
    final rows = await (_db.select(_db.mistakes)
          ..where((t) => t.deletedAt.isNull() & t.ownerId.equals(_ownerId) & t.createdAt.isBiggerOrEqualValue(since)))
        .get();
    final counts = <(String, String), int>{};
    for (final r in rows) {
      counts.update((r.skill, r.category), (n) => n + 1, ifAbsent: () => 1);
    }
    final groups = [
      for (final e in counts.entries) MistakeGroup(skill: e.key.$1, category: e.key.$2, count: e.value),
    ]..sort((a, b) => b.count.compareTo(a.count));
    return groups;
  }

  @override
  Future<List<MistakeItem>> recentMistakes({int limit = 20}) async {
    final rows = await (_db.select(_db.mistakes)
          ..where((t) => t.deletedAt.isNull() & t.ownerId.equals(_ownerId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(limit))
        .get();
    return [
      for (final r in rows)
        MistakeItem(
          skill: r.skill,
          category: r.category,
          original: r.original,
          corrected: r.corrected,
          explanation: r.explanation,
          createdAt: r.createdAt,
        ),
    ];
  }

  @override
  Future<Set<PackPart>> weakParts(DateTime since) async {
    final weak = <PackPart>{};

    final mistakes = await mistakesSince(since);
    final bySkill = <String, int>{};
    for (final m in mistakes) {
      bySkill.update(m.skill, (n) => n + m.count, ifAbsent: () => m.count);
    }
    if ((bySkill['grammar'] ?? 0) >= weakMistakeCount) weak.add(PackPart.grammar);
    if ((bySkill['writing'] ?? 0) >= weakMistakeCount) weak.add(PackPart.writing);

    final attempts = await (_db.select(_db.exerciseAttempts)
          ..where((t) => t.deletedAt.isNull() & t.ownerId.equals(_ownerId) & t.createdAt.isBiggerOrEqualValue(since)))
        .get();
    final totals = <String, int>{};
    final rights = <String, int>{};
    for (final a in attempts) {
      totals.update(a.part, (n) => n + 1, ifAbsent: () => 1);
      if (a.isCorrect) rights.update(a.part, (n) => n + 1, ifAbsent: () => 1);
    }
    for (final part in PackPart.values) {
      final total = totals[part.name] ?? 0;
      if (total >= 4 && (rights[part.name] ?? 0) / total < 0.6) weak.add(part);
    }
    return weak;
  }
}

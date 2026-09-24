import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/pack/pack_content.dart';
import '../../core/providers/core_providers.dart';
import '../../core/session/current_unit.dart';
import '../../core/session/session_planner.dart';
import '../../core/srs/srs_queue.dart';
import '../../data/repositories/session_stats_repository_impl.dart';
import '../../domain/models/unit.dart';
import '../../domain/models/unit_pack.dart';
import '../../domain/repositories/session_stats_repository.dart';
import '../pack/pack_context.dart';

final sessionStatsRepositoryProvider = Provider<SessionStatsRepository>((ref) {
  final ownerId = ref.watch(currentOwnerIdProvider) ?? '';
  return DriftSessionStatsRepository(ref.watch(appDatabaseProvider), ownerId);
});

/// Everything the main screen and the session need to know about today: the
/// current unit, its pack, what the planner decided.
class TodayPlan {
  final Unit? unit;
  final String? setId;
  final PackContext? pack;
  final Set<PackPart> readyParts;
  final Map<PackPart, PackProgress> progress;
  final List<SessionStep> steps;

  const TodayPlan({
    required this.unit,
    required this.setId,
    required this.pack,
    required this.readyParts,
    required this.progress,
    required this.steps,
  });

  int get totalMinutes => steps.fold(0, (sum, s) => sum + s.minutes);

  bool doneToday(PackPart part, DateTime now) {
    final at = progress[part]?.completedAt;
    return at != null && !at.isBefore(DateTime(now.year, now.month, now.day));
  }
}

/// Null when the plan cannot be built (no data layer yet, first frame).
final todayPlanProvider = FutureProvider.autoDispose<TodayPlan?>((ref) async {
  try {
    final now = DateTime.now();
    final stateRepo = ref.watch(cardStateRepositoryProvider);
    final limit = await ref.watch(newCardLimitProvider.future);

    final due = (await stateRepo.getDueForReview(now: now.toUtc())).length;
    final fresh = (await stateRepo.getNewCards(limit: limit)).length;
    final reviewCards = reviewQueueSize(
      due: due,
      fresh: fresh,
      newCardLimit: limit,
    );

    final unit = await findNewestUnit(
      ref.watch(courseRepositoryProvider),
      ref.watch(unitRepositoryProvider),
    );
    if (unit == null) {
      final steps = planSession(
        PlannerInput(
          reviewCards: reviewCards,
          unlearnedWords: 0,
          readyParts: const {},
          lastDone: const {},
          now: now,
        ),
      );
      return TodayPlan(
        unit: null,
        setId: null,
        pack: null,
        readyParts: const {},
        progress: const {},
        steps: steps,
      );
    }

    final sets = await ref
        .watch(wordSetRepositoryProvider)
        .watchWordSets(unitId: unit.id)
        .first;
    final setId = sets.isEmpty ? null : sets.first.id;
    final unlearned = setId == null
        ? 0
        : await ref
              .watch(sessionStatsRepositoryProvider)
              .unlearnedCardCount(setId);

    final pack = await ref.watch(packContextProvider(unit.id).future);
    // Re-plan whenever a part finishes generating.
    final packData = await ref.watch(packProvider(pack.packId).future);
    final progress = await ref
        .watch(packRepositoryProvider)
        .getProgress(pack.packId);
    final ready = {
      for (final part in PackPart.values)
        if (packData?.statusOf(part) == PartStatus.ready) part,
    };

    final steps = planSession(
      PlannerInput(
        reviewCards: reviewCards,
        unlearnedWords: unlearned,
        readyParts: ready,
        lastDone: {
          for (final e in progress.entries) e.key: e.value.completedAt,
        },
        now: now,
      ),
    );
    return TodayPlan(
      unit: unit,
      setId: setId,
      pack: pack,
      readyParts: ready,
      progress: progress,
      steps: steps,
    );
  } catch (_) {
    return null;
  }
});

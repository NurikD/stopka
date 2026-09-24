import '../pack/pack_content.dart';

enum SessionStepKind { review, dictation, reading, listening, grammar, writing }

class SessionStep {
  final SessionStepKind kind;
  final int minutes;

  const SessionStep(this.kind, this.minutes);

  PackPart? get packPart => switch (kind) {
        SessionStepKind.reading => PackPart.reading,
        SessionStepKind.listening => PackPart.listening,
        SessionStepKind.grammar => PackPart.grammar,
        SessionStepKind.writing => PackPart.writing,
        _ => null,
      };
}

class PlannerInput {
  /// Cards the review would serve right now (already capped by the daily
  /// new-card limit).
  final int reviewCards;

  /// Words of the current unit that have never been through a dictation.
  final int unlearnedWords;

  /// Pack parts of the current unit that are ready to open.
  final Set<PackPart> readyParts;

  /// When each part was last finished; absent means never.
  final Map<PackPart, DateTime> lastDone;

  final DateTime now;

  const PlannerInput({
    required this.reviewCards,
    required this.unlearnedWords,
    required this.readyParts,
    required this.lastDone,
    required this.now,
  });
}

/// The session length the planner aims for, and the most it will stretch to.
const int targetMinutes = 15;
const int maxMinutes = 17;

/// Reviews are capped so one block never eats the session.
const int maxReviewCards = 20;

/// Writing comes round again after this many days.
const Duration writingEvery = Duration(days: 2);

const List<PackPart> _rotation = [PackPart.reading, PackPart.listening, PackPart.grammar];

int _partMinutes(PackPart part) => switch (part) {
      PackPart.reading => 4,
      PackPart.listening => 4,
      PackPart.grammar => 3,
      PackPart.writing => 5,
    };

/// Builds today's session (see PLAN_v2.md "Занятие"): due words first, then
/// a dictation of new words, writing when it is due, and one of reading /
/// listening / grammar — whichever was left alone the longest. Stops adding
/// blocks once the session would run past [maxMinutes]; the first block is
/// always kept.
List<SessionStep> planSession(PlannerInput input) {
  final candidates = <SessionStep>[];

  if (input.reviewCards > 0) {
    final cards = input.reviewCards < maxReviewCards ? input.reviewCards : maxReviewCards;
    // About 15 seconds a card, between one and five minutes.
    final minutes = (cards / 4).ceil().clamp(1, 5);
    candidates.add(SessionStep(SessionStepKind.review, minutes));
  }

  if (input.unlearnedWords > 0) {
    candidates.add(const SessionStep(SessionStepKind.dictation, 4));
  }

  final writingLast = input.lastDone[PackPart.writing];
  final writingDue = writingLast == null || input.now.difference(writingLast) >= writingEvery;
  if (input.readyParts.contains(PackPart.writing) && writingDue) {
    candidates.add(SessionStep(SessionStepKind.writing, _partMinutes(PackPart.writing)));
  }

  final available = _rotation.where(input.readyParts.contains).toList();
  if (available.isNotEmpty) {
    // Never done counts as the oldest; ties keep the rotation order.
    available.sort((a, b) {
      final la = input.lastDone[a];
      final lb = input.lastDone[b];
      if (la == null && lb == null) return _rotation.indexOf(a).compareTo(_rotation.indexOf(b));
      if (la == null) return -1;
      if (lb == null) return 1;
      final byDate = la.compareTo(lb);
      return byDate != 0 ? byDate : _rotation.indexOf(a).compareTo(_rotation.indexOf(b));
    });
    final part = available.first;
    candidates.add(SessionStep(_kindOf(part), _partMinutes(part)));
  }

  final steps = <SessionStep>[];
  var total = 0;
  for (final step in candidates) {
    if (steps.isEmpty || total + step.minutes <= maxMinutes) {
      steps.add(step);
      total += step.minutes;
    }
  }
  return steps;
}

SessionStepKind _kindOf(PackPart part) => switch (part) {
      PackPart.reading => SessionStepKind.reading,
      PackPart.listening => SessionStepKind.listening,
      PackPart.grammar => SessionStepKind.grammar,
      PackPart.writing => SessionStepKind.writing,
    };

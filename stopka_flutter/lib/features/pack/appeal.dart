import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/pack/pack_content.dart';
import '../../core/providers/core_providers.dart';
import 'exercise_flow.dart';

/// "Мой ответ тоже верный?" for a translation exercise: the AI judges, or the
/// learner is told that this needs a key. Shared by every place that runs an
/// [ExerciseFlow].
Future<AppealOutcome> appealTranslation(WidgetRef ref, Exercise exercise, String given) async {
  if (!await ref.read(aiAvailabilityProvider).isAvailable()) {
    return const AppealOutcome(
      accepted: false,
      note: 'Проверка ответа через ИИ сейчас недоступна: нет связи с сервером.',
    );
  }
  final result = await ref.read(answerAppealServiceProvider).appeal(
        term: exercise.prompt,
        correctAnswer: exercise.answer,
        userAnswer: given,
        direction: 'RU -> EN (whole sentence)',
      );
  return AppealOutcome(accepted: result.accepted, note: result.explanationRu);
}

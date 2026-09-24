import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/llm/llm_exception.dart';
import '../../core/llm/weak_practice_service.dart';
import '../../core/llm/writing_check_service.dart' show mistakeCategoryNamesRu;
import '../../core/pack/pack_content.dart';
import '../../core/providers/core_providers.dart';
import '../../core/session/current_unit.dart';
import '../../core/theme/app_theme_extension.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/app_header_bar.dart';
import '../../core/widgets/ghost_button.dart';
import '../../domain/models/unit_pack.dart';
import '../pack/appeal.dart';
import '../pack/exercise_flow.dart';
import '../session/today_plan.dart';

/// Practice on one weak category: six exercises made from the learner's own
/// words, interests and real mistakes. A wrong answer here is recorded as a
/// mistake again, so the statistics stay honest.
class WeakPracticeScreen extends ConsumerStatefulWidget {
  final String category;
  final String skill;

  const WeakPracticeScreen({
    super.key,
    required this.category,
    required this.skill,
  });

  @override
  ConsumerState<WeakPracticeScreen> createState() => _WeakPracticeScreenState();
}

class _WeakPracticeScreenState extends ConsumerState<WeakPracticeScreen> {
  List<Exercise>? _exercises;
  String? _message;
  bool _loading = true;

  String get _categoryRu =>
      mistakeCategoryNamesRu[widget.category] ?? widget.category;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _message = null;
    });
    if (!await ref.read(apiKeyStoreProvider).hasKey()) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _message =
            'Тренировка составляется через Gemini — добавьте ключ в «Профиле». '
            'Ваши ошибки при этом сохранены, ничего не потеряно.';
      });
      return;
    }

    try {
      final profile = ref.read(currentProfileProvider).value;
      final unit = await findNewestUnit(
        ref.read(courseRepositoryProvider),
        ref.read(unitRepositoryProvider),
      );
      var words = <String>[];
      if (unit != null) {
        final sets = await ref
            .read(wordSetRepositoryProvider)
            .watchWordSets(unitId: unit.id)
            .first;
        if (sets.isNotEmpty) {
          final cards = await ref
              .read(wordCardRepositoryProvider)
              .watchCards(sets.first.id)
              .first;
          words = [for (final c in cards) c.term];
        }
      }
      final recent = await ref
          .read(sessionStatsRepositoryProvider)
          .recentMistakes(limit: 50);
      final examples = [
        for (final m in recent)
          if (m.category == widget.category && m.original.isNotEmpty)
            MistakeExample(m.original, m.corrected),
      ];

      final exercises = await ref
          .read(weakPracticeServiceProvider)
          .generate(
            level: profile?.level ?? '',
            category: widget.category,
            categoryRu: _categoryRu,
            interests: profile?.interests ?? const [],
            words: words,
            examples: examples,
          );
      if (!mounted) return;
      setState(() {
        _exercises = exercises;
        _loading = false;
      });
    } on LlmException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _message = e.messageRu;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final exercises = _exercises;

    return Scaffold(
      appBar: const AppHeaderBar(nested: true, title: 'тренировка'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.s8,
          AppSpacing.screen,
          AppSpacing.s30,
        ),
        children: [
          Text(
            _categoryRu,
            style: AppTypography.title.copyWith(color: colors.ink),
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            'Упражнения на ваших словах, интересах и ошибках.',
            style: AppTypography.caption.copyWith(color: colors.muted),
          ),
          const SizedBox(height: AppSpacing.s22),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (exercises != null)
            ExerciseFlow(
              items: exercises,
              onAppeal: (exercise, given) =>
                  appealTranslation(ref, exercise, given),
              onAnswer: (i, answer, correct) async {
                if (correct) return;
                await ref.read(packRepositoryProvider).addMistakes(null, [
                  MistakeInput(
                    skill: widget.skill,
                    category: widget.category,
                    original: answer,
                    corrected: exercises[i].answer,
                    explanation: exercises[i].why,
                  ),
                ]);
              },
              onFinished: (score, total) async {
                ref.invalidate(todayPlanProvider);
              },
            )
          else ...[
            Text(
              _message ?? 'Не получилось подготовить тренировку.',
              style: AppTypography.bodyText.copyWith(color: colors.muted),
            ),
            const SizedBox(height: AppSpacing.s14),
            GhostButton(label: 'Повторить', onPressed: _load),
          ],
        ],
      ),
    );
  }
}

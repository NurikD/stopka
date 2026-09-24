import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/pack/pack_content.dart';
import '../../core/providers/core_providers.dart';
import '../../core/theme/app_theme_extension.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/app_card.dart';
import '../../domain/models/unit_pack.dart';
import 'exercise_flow.dart';
import 'pack_context.dart';

class GrammarScreen extends StatelessWidget {
  final PackContext pack;

  const GrammarScreen({super.key, required this.pack});

  @override
  Widget build(BuildContext context) {
    return PackPartView(
      pack: pack,
      part: PackPart.grammar,
      title: 'грамматика',
      builder: (context, payload) =>
          _GrammarBody(pack: pack, content: GrammarContent.fromJson(payload)),
    );
  }
}

class _GrammarBody extends ConsumerWidget {
  final PackContext pack;
  final GrammarContent content;

  const _GrammarBody({required this.pack, required this.content});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final repo = ref.read(packRepositoryProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.s8,
        AppSpacing.screen,
        AppSpacing.s30,
      ),
      children: [
        Text(
          content.title,
          style: AppTypography.title.copyWith(color: colors.ink),
        ),
        const SizedBox(height: AppSpacing.s18),
        AppCard(
          child: Text(
            content.explanation,
            style: AppTypography.bodyText.copyWith(
              fontSize: 16,
              height: 1.55,
              color: colors.body,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s14),
        for (final example in content.examples)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s8),
            child: Text(
              example,
              style: AppTypography.monoWord.copyWith(
                fontSize: 15,
                color: colors.ink,
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.s22),
        Text(
          'Упражнения',
          style: AppTypography.heading.copyWith(color: colors.ink),
        ),
        const SizedBox(height: AppSpacing.s14),
        ExerciseFlow(
          items: content.exercises,
          onAnswer: (i, answer, correct) async {
            await repo.logAttempt(
              pack.packId,
              PackPart.grammar,
              itemIndex: i,
              userAnswer: answer,
              isCorrect: correct,
            );
            if (!correct) {
              final e = content.exercises[i];
              await repo.addMistakes(pack.packId, [
                MistakeInput(
                  skill: 'grammar',
                  category: content.title,
                  original: answer,
                  corrected: e.answer,
                  explanation: e.why,
                ),
              ]);
            }
          },
          onFinished: (score, total) => repo.saveProgress(
            pack.packId,
            PackPart.grammar,
            score: score,
            total: total,
          ),
        ),
        const SizedBox(height: AppSpacing.s30),
        BadMaterialButton(pack: pack, part: PackPart.grammar),
      ],
    );
  }
}

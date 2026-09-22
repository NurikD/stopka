import 'package:flutter/material.dart';

import '../theme/app_theme_extension.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';

enum ResultVerdict { correct, typo, wrong, skipped }

/// One line in a dictation round's review: the word, its transcription, a
/// play button, and — for anything but a clean [ResultVerdict.correct] —
/// the user's answer struck through next to the right one, so the two are
/// compared at a glance.
class ResultRow extends StatelessWidget {
  final String term;
  final String transcription;
  final String correctAnswer;
  final String? userAnswer;
  final ResultVerdict verdict;
  final VoidCallback? onPlayAudio;

  const ResultRow({
    super.key,
    required this.term,
    required this.transcription,
    required this.correctAnswer,
    required this.verdict,
    this.userAnswer,
    this.onPlayAudio,
  });

  Color _verdictColor(AppColorTokens colors) {
    switch (verdict) {
      case ResultVerdict.correct:
        return colors.statusCorrect;
      case ResultVerdict.typo:
        return colors.statusTypo;
      case ResultVerdict.wrong:
        return colors.statusWrong;
      case ResultVerdict.skipped:
        return colors.statusSkipped;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  term,
                  style: AppTypography.subtitle.copyWith(
                    fontFamily: 'Literata',
                    color: colors.textPrimary,
                  ),
                ),
              ),
              Text(transcription, style: AppTypography.transcription.copyWith(color: colors.textMuted)),
              if (onPlayAudio != null)
                IconButton(
                  onPressed: onPlayAudio,
                  icon: const Icon(Icons.volume_up_outlined),
                  color: colors.textMuted,
                  iconSize: 20,
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                ),
            ],
          ),
          if (verdict != ResultVerdict.correct && userAnswer != null && userAnswer!.isNotEmpty)
            Text(
              'вы: $userAnswer',
              style: AppTypography.body.copyWith(
                color: _verdictColor(colors),
                decoration: TextDecoration.lineThrough,
              ),
            ),
          if (verdict != ResultVerdict.correct)
            Text(
              'верно: $correctAnswer',
              style: AppTypography.body.copyWith(color: colors.textPrimary),
            ),
          Divider(height: AppSpacing.lg, color: colors.hairline),
        ],
      ),
    );
  }
}

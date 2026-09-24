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
        return colors.success;
      case ResultVerdict.typo:
        return colors.markLine;
      case ResultVerdict.wrong:
        return colors.danger;
      case ResultVerdict.skipped:
        return colors.muted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  term,
                  style: AppTypography.heading.copyWith(
                    fontFamily: 'Literata',
                    color: colors.ink,
                  ),
                ),
              ),
              Text(transcription, style: AppTypography.transcription.copyWith(color: colors.muted)),
              if (onPlayAudio != null)
                IconButton(
                  onPressed: onPlayAudio,
                  icon: const Icon(Icons.volume_up_outlined),
                  color: colors.muted,
                  iconSize: 20,
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                ),
            ],
          ),
          if (verdict != ResultVerdict.correct && userAnswer != null && userAnswer!.isNotEmpty)
            Text(
              'вы: $userAnswer',
              style: AppTypography.bodyText.copyWith(
                color: _verdictColor(colors),
                decoration: TextDecoration.lineThrough,
              ),
            ),
          if (verdict != ResultVerdict.correct)
            Text(
              'верно: $correctAnswer',
              style: AppTypography.bodyText.copyWith(color: colors.ink),
            ),
          Divider(height: AppSpacing.s14, color: colors.line),
        ],
      ),
    );
  }
}

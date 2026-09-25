import 'package:flutter/material.dart';

import '../theme/app_theme_extension.dart';
import '../theme/typography.dart';

/// Compares the user's answer with the right one on two mono lines. Both
/// lines share one font, size and tracking, so letters line up vertically
/// and a wrong or missing letter is visible by eye.
///
/// "вы": positions that differ are `danger`. "верно": positions where the
/// user's letter differs are `accent` with a 2px underline.
class DiffRow extends StatelessWidget {
  final String user;
  final String correct;

  const DiffRow({super.key, required this.user, required this.correct});

  static const _labelWidth = 44.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final base = AppTypography.monoWord;

    List<InlineSpan> userSpans() {
      if (user.isEmpty) {
        return [TextSpan(text: '—', style: base.copyWith(color: colors.muted))];
      }
      return [
        for (var i = 0; i < user.length; i++)
          TextSpan(
            text: user[i],
            style: base.copyWith(color: i < correct.length && user[i] == correct[i] ? colors.ink : colors.danger),
          ),
      ];
    }

    List<InlineSpan> correctSpans() {
      return [
        for (var i = 0; i < correct.length; i++)
          TextSpan(
            text: correct[i],
            style: i < user.length && user[i] == correct[i]
                ? base.copyWith(color: colors.ink)
                : base.copyWith(
                    color: colors.accent,
                    decoration: TextDecoration.underline,
                    decorationColor: colors.accent,
                    decorationThickness: 2,
                  ),
          ),
      ];
    }

    Widget line(String label, List<InlineSpan> spans) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          SizedBox(
            width: _labelWidth,
            child: Text(label, softWrap: false, style: AppTypography.monoMeta.copyWith(color: colors.muted)),
          ),
          Text.rich(TextSpan(children: spans), softWrap: false),
        ],
      );
    }

    // One FittedBox around both lines so a long phrase shrinks both by the
    // same factor and the columns stay aligned.
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          line('вы', userSpans()),
          const SizedBox(height: 4),
          line('верно', correctSpans()),
        ],
      ),
    );
  }
}

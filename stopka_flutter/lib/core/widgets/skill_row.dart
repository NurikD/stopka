import 'package:flutter/material.dart';

import '../theme/app_theme_extension.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';

/// One skill on the main screen: a number (`01`), the name, a counter and a
/// 3px straight progress track (no rounding — part of the look).
///
/// The number is `accent` once the block has been started, `lineStrong`
/// before.
class SkillRow extends StatelessWidget {
  final String number;
  final String label;
  final String counter;

  /// 0..1 fill of the track.
  final double progress;
  final bool started;

  const SkillRow({
    super.key,
    required this.number,
    required this.label,
    required this.counter,
    required this.progress,
    required this.started,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s18, vertical: AppSpacing.s14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 22,
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.s4),
                child: Text(
                  number,
                  style: AppTypography.monoMeta.copyWith(
                    fontWeight: FontWeight.w600,
                    color: started ? colors.accent : colors.lineStrong,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.s14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(label, style: AppTypography.label.copyWith(color: colors.ink)),
                      Text(counter, style: AppTypography.monoMeta.copyWith(color: colors.muted)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s10),
                  SizedBox(
                    height: 3,
                    child: LayoutBuilder(
                      builder: (context, box) => Stack(
                        children: [
                          Positioned.fill(child: ColoredBox(color: colors.line)),
                          Positioned(
                            left: 0,
                            top: 0,
                            bottom: 0,
                            width: box.maxWidth * progress.clamp(0.0, 1.0),
                            child: ColoredBox(color: colors.accent),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

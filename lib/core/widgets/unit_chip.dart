import 'package:flutter/material.dart';

import '../theme/app_theme_extension.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';

/// Small tag for a unit code or level: `accentTint` fill, mono, radius 8.
class UnitChip extends StatelessWidget {
  final String label;

  const UnitChip({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s8, vertical: AppSpacing.s4),
      decoration: BoxDecoration(
        color: colors.accentTint,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Text(label, style: AppTypography.monoMeta.copyWith(fontWeight: FontWeight.w600, color: colors.accent)),
    );
  }
}

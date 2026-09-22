import 'package:flutter/material.dart';

import '../theme/app_theme_extension.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';

/// Small tag for a unit code (e.g. "Unit 4B") — accent-coloured, radius 8.
class UnitChip extends StatelessWidget {
  final String label;

  const UnitChip({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        border: Border.all(color: colors.accent),
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Text(
        label,
        style: AppTypography.label.copyWith(color: colors.accent),
      ),
    );
  }
}

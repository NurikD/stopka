import 'package:flutter/material.dart';

import '../theme/app_theme_extension.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';

/// A tappable tag that can be switched on, for multi-select lists such as
/// interests. Selected: `accentTint` fill and accent line; radius 8.
class ChoiceTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const ChoiceTile({super.key, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s14, vertical: AppSpacing.s10),
          decoration: BoxDecoration(
            color: selected ? colors.accentTint : colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.chip),
            border: Border.all(color: selected ? colors.accent : colors.line),
          ),
          child: Text(
            label,
            style: AppTypography.label.copyWith(color: selected ? colors.accent : colors.ink),
          ),
        ),
      ),
    );
  }
}

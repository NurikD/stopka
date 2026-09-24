import 'package:flutter/material.dart';

import '../theme/app_theme_extension.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';

/// Secondary action next to a [PrimaryButton]: same height, transparent
/// fill, 1px `lineStrong` border, `muted` text.
class GhostButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const GhostButton({super.key, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 56),
        foregroundColor: colors.muted,
        side: BorderSide(color: colors.lineStrong),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
      ),
      child: Text(label, style: AppTypography.label.copyWith(fontSize: 16), textAlign: TextAlign.center),
    );
  }
}

import 'package:flutter/material.dart';

import '../theme/app_theme_extension.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';

enum PrimaryButtonVariant {
  /// The default: `ink` fill, `inkOn` text.
  ink,

  /// Accent fill with white text — only for actions that check an answer.
  accent,
}

/// The main button: 56 high, radius 14, no pill. Names the result
/// ("Проверить", "Заниматься 15 минут"), never "ОК".
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final PrimaryButtonVariant variant;

  /// Arrow-style icon pinned to the right edge.
  final IconData? trailingIcon;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.variant = PrimaryButtonVariant.ink,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isAccent = variant == PrimaryButtonVariant.accent;
    final background = isAccent ? colors.accent : colors.ink;
    final foreground = isAccent ? Colors.white : colors.inkOn;

    return FilledButton(
      onPressed: loading ? null : onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 56),
        backgroundColor: background,
        foregroundColor: foreground,
        disabledBackgroundColor: background.withValues(alpha: 0.4),
        disabledForegroundColor: foreground.withValues(alpha: 0.7),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
      ),
      child: loading
          ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: foreground))
          : trailingIcon == null
              ? Text(label, style: AppTypography.label.copyWith(fontSize: 16), textAlign: TextAlign.center)
              // Label at the left edge, arrow pinned to the right.
              : Row(
                  children: [
                    Expanded(
                      child: Text(label, style: AppTypography.label.copyWith(fontSize: 16)),
                    ),
                    const SizedBox(width: AppSpacing.s10),
                    Icon(trailingIcon, size: 20),
                  ],
                ),
    );
  }
}

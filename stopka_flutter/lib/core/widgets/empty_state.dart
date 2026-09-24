import 'package:flutter/material.dart';

import '../theme/app_theme_extension.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';
import 'app_card.dart';
import 'primary_button.dart';

/// An empty screen as an invitation, not a status report: a dashed card
/// with text like "Сфоткайте список слов с урока — разберу и переведу" and,
/// when there is something to do, the action button.
class EmptyState extends StatelessWidget {
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screen),
        child: AppCard(
          dashed: true,
          padding: const EdgeInsets.all(AppSpacing.s22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTypography.bodyText.copyWith(color: colors.muted),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: AppSpacing.s18),
                PrimaryButton(label: actionLabel!, onPressed: onAction),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

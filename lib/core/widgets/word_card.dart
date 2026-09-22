import 'package:flutter/material.dart';

import '../theme/app_theme_extension.dart';
import '../theme/tokens.dart';

/// The hero surface panel — radius 24, one tone lighter than the
/// background. Used for the "Сегодня" stat card, SRS flashcards, and
/// anywhere content needs to read as the most important thing on screen.
class WordCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const WordCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.hero),
      ),
      child: child,
    );
  }
}

import 'package:flutter/material.dart';

import '../theme/app_theme_extension.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';

/// The prompt of a card asked by ear: play the word again, or slower. The
/// word itself stays hidden until the answer is checked.
class ListenPrompt extends StatelessWidget {
  final VoidCallback onPlay;
  final VoidCallback onPlaySlow;

  const ListenPrompt({super.key, required this.onPlay, required this.onPlaySlow});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final style = OutlinedButton.styleFrom(
      minimumSize: const Size(0, 56),
      foregroundColor: colors.ink,
      side: BorderSide(color: colors.lineStrong),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
    );
    final label = AppTypography.label.copyWith(fontSize: 16);
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onPlay,
            style: style,
            icon: const Icon(Icons.volume_up_outlined),
            label: Text('Слушать', style: label),
          ),
        ),
        const SizedBox(width: AppSpacing.s10),
        Expanded(
          child: OutlinedButton(
            onPressed: onPlaySlow,
            style: style,
            child: Text('Медленно', style: label),
          ),
        ),
      ],
    );
  }
}

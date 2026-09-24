import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/core_providers.dart';
import '../../core/theme/app_theme_extension.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/ghost_button.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/sticky_action_bar.dart';
import '../../domain/models/dictation_session.dart';
import '../../domain/models/word_card.dart';
import 'dictation_session_screen.dart';

class SessionSummaryScreen extends ConsumerWidget {
  final String setId;
  final DictationDirection direction;
  final int roundsCount;
  final int totalWords;
  final List<WordCard> problemCards;

  const SessionSummaryScreen({
    super.key,
    required this.setId,
    required this.direction,
    required this.roundsCount,
    required this.totalWords,
    required this.problemCards,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return Scaffold(
      appBar: AppBar(title: const Text('Итог диктанта')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.s14),
        children: [
          Text('Готово!', style: AppTypography.title.copyWith(color: colors.ink)),
          const SizedBox(height: AppSpacing.s8),
          Text(
            '$totalWords слов выучено за $roundsCount ${_roundsWord(roundsCount)}.',
            style: AppTypography.bodyText.copyWith(color: colors.muted),
          ),
          if (problemCards.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s22),
            Text('Самые проблемные слова', style: AppTypography.heading.copyWith(color: colors.ink)),
            const SizedBox(height: AppSpacing.s8),
            for (final card in problemCards)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.s8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${card.term} — ${card.translation}',
                        style: AppTypography.bodyText.copyWith(color: colors.ink),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.volume_up_outlined),
                      color: colors.muted,
                      onPressed: () => ref.read(ttsServiceProvider).speak(card.term),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
      bottomNavigationBar: StickyActionBar(
        children: [
          if (problemCards.isNotEmpty)
            GhostButton(
              label: 'Повторить проблемные',
              onPressed: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => DictationSessionScreen(
                    setId: setId,
                    direction: direction,
                    stackSize: problemCards.length.clamp(5, 15),
                    requiredStreak: 1,
                    onlyCards: problemCards,
                  ),
                ),
              ),
            ),
          PrimaryButton(label: 'Готово', onPressed: () => Navigator.of(context).pop()),
        ],
      ),
    );
  }

  String _roundsWord(int count) {
    final mod10 = count % 10;
    final mod100 = count % 100;
    if (mod10 == 1 && mod100 != 11) return 'раунд';
    if ([2, 3, 4].contains(mod10) && ![12, 13, 14].contains(mod100)) return 'раунда';
    return 'раундов';
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/core_providers.dart';
import '../../core/theme/app_theme_extension.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/text/russian_plural.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_header_bar.dart';
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
    final rounds = pluralRu(roundsCount, one: 'раунд', few: 'раунда', many: 'раундов');
    final words = pluralRu(totalWords, one: 'слово', few: 'слова', many: 'слов');
    return Scaffold(
      appBar: const AppHeaderBar(nested: true, title: 'Итог диктанта'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.s8, AppSpacing.screen, AppSpacing.s22),
        children: [
          Text('Готово', style: AppTypography.title.copyWith(color: colors.ink)),
          const SizedBox(height: AppSpacing.s22),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$totalWords', style: AppTypography.display.copyWith(color: colors.ink)),
                Text(
                  '$words выучено за $roundsCount $rounds',
                  style: AppTypography.bodyText.copyWith(color: colors.muted),
                ),
              ],
            ),
          ),
          if (problemCards.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s22),
            Text('Самые проблемные слова', style: AppTypography.heading.copyWith(color: colors.ink)),
            const SizedBox(height: AppSpacing.s10),
            for (final card in problemCards)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.s10),
                child: AppCard(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.s18, AppSpacing.s10, AppSpacing.s8, AppSpacing.s10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(card.term, style: AppTypography.monoWord.copyWith(color: colors.ink)),
                            if (card.translation.isNotEmpty)
                              Text(card.translation, style: AppTypography.caption.copyWith(color: colors.muted)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.volume_up_outlined),
                        color: colors.muted,
                        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                        onPressed: () => ref.read(ttsServiceProvider).speak(card.term),
                      ),
                    ],
                  ),
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
}

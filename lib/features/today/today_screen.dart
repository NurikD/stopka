import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/core_providers.dart';
import '../../core/text/russian_date.dart';
import '../../core/theme/app_theme_extension.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/sticky_action_bar.dart';
import '../../core/widgets/word_card.dart';
import '../srs/srs_review_screen.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final dueStream = ref.watch(cardStateRepositoryProvider).watchDueCount(DateTime.now().toUtc());
    final newStream = ref.watch(cardStateRepositoryProvider).watchNewCount();

    return Scaffold(
      appBar: AppBar(title: const Text('Сегодня')),
      body: StreamBuilder<int>(
        stream: dueStream,
        builder: (context, dueSnapshot) {
          return StreamBuilder<int>(
            stream: newStream,
            builder: (context, newSnapshot) {
              final due = dueSnapshot.data ?? 0;
              final newCount = newSnapshot.data ?? 0;
              final total = due + newCount;

              if (!dueSnapshot.hasData && !newSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              if (total == 0) {
                return const EmptyState(
                  message: 'Пока нечего повторять — пройдите диктант в любом юните, '
                      'и выученные слова появятся здесь по расписанию.',
                );
              }

              return Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      RussianDate.longFormat(DateTime.now()),
                      style: AppTypography.caption.copyWith(color: colors.textMuted),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    WordCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$total',
                            style: AppTypography.hero.copyWith(color: colors.textPrimary),
                          ),
                          Text(
                            'слов к повторению',
                            style: AppTypography.body.copyWith(color: colors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: StreamBuilder<int>(
        stream: dueStream,
        builder: (context, dueSnapshot) {
          return StreamBuilder<int>(
            stream: newStream,
            builder: (context, newSnapshot) {
              final total = (dueSnapshot.data ?? 0) + (newSnapshot.data ?? 0);
              if (total == 0) return const SizedBox.shrink();
              return StickyActionBar(
                children: [
                  PrimaryButton(
                    label: 'Начать повторение',
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SrsReviewScreen()),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

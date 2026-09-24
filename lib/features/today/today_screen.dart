import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/core_providers.dart';
import '../../core/srs/srs_queue.dart';
import '../../core/srs/srs_settings_store.dart';
import '../../core/text/russian_date.dart';
import '../../core/text/russian_plural.dart';
import '../../core/theme/app_theme_extension.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_header_bar.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/sticky_action_bar.dart';
import '../srs/srs_review_screen.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final repo = ref.watch(cardStateRepositoryProvider);
    final limit = ref.watch(newCardLimitProvider).value ?? defaultNewCardLimit;
    final streak = ref.watch(streakDaysProvider).value ?? 0;
    final now = DateTime.now();

    final streakMeta = streak > 0
        ? '$streak ${pluralRu(streak, one: 'день', few: 'дня', many: 'дней')} подряд'
        : null;

    return StreamBuilder<int>(
      stream: repo.watchDueCount(now.toUtc()),
      builder: (context, dueSnapshot) {
        return StreamBuilder<int>(
          stream: repo.watchNewCount(),
          builder: (context, newSnapshot) {
            final loaded = dueSnapshot.hasData && newSnapshot.hasData;
            final due = dueSnapshot.data ?? 0;
            final fresh = newSnapshot.data ?? 0;
            final total = reviewQueueSize(due: due, fresh: fresh, newCardLimit: limit);
            final servedNew = total - due;

            return Scaffold(
              appBar: AppHeaderBar(meta: streakMeta),
              body: !loaded
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.s8, AppSpacing.screen, AppSpacing.s22),
                      children: [
                        Text(RussianDate.weekdayTitle(now), style: AppTypography.title.copyWith(color: colors.ink)),
                        const SizedBox(height: AppSpacing.s4),
                        Text(
                          RussianDate.dayAndMonth(now),
                          style: AppTypography.caption.copyWith(color: colors.muted),
                        ),
                        const SizedBox(height: AppSpacing.s22),
                        if (total == 0)
                          const EmptyState(
                            message: 'Пока нечего повторять — пройдите диктант в любом юните, '
                                'и выученные слова появятся здесь по расписанию.',
                          )
                        else
                          AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('$total', style: AppTypography.display.copyWith(color: colors.ink)),
                                Text(
                                  pluralRu(
                                    total,
                                    one: 'слово к повторению',
                                    few: 'слова к повторению',
                                    many: 'слов к повторению',
                                  ),
                                  style: AppTypography.bodyText.copyWith(color: colors.muted),
                                ),
                                if (servedNew > 0) ...[
                                  const SizedBox(height: AppSpacing.s10),
                                  Text(
                                    'из них новых: $servedNew',
                                    style: AppTypography.monoMeta.copyWith(color: colors.muted),
                                  ),
                                ],
                              ],
                            ),
                          ),
                      ],
                    ),
              bottomNavigationBar: total == 0
                  ? null
                  : StickyActionBar(
                      children: [
                        PrimaryButton(
                          label: 'Начать повторение',
                          trailingIcon: Icons.arrow_forward,
                          onPressed: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const SrsReviewScreen()),
                            );
                            ref.invalidate(streakDaysProvider);
                          },
                        ),
                      ],
                    ),
            );
          },
        );
      },
    );
  }
}

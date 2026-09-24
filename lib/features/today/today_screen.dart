import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
import '../../core/widgets/ghost_button.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/skill_row.dart';
import '../../core/widgets/sticky_action_bar.dart';
import '../../core/pack/pack_content.dart';
import '../session/session_screen.dart';
import '../session/today_plan.dart';
import '../srs/srs_review_screen.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final repo = ref.watch(cardStateRepositoryProvider);
    final limit = ref.watch(newCardLimitProvider).value ?? defaultNewCardLimit;
    final streak = ref.watch(streakDaysProvider).value ?? 0;
    final doneToday = ref.watch(reviewsTodayProvider).value ?? 0;
    final plan = ref.watch(todayPlanProvider).value;
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
            final total = reviewQueueSize(
              due: due,
              fresh: fresh,
              newCardLimit: limit,
            );
            final planned = doneToday + total;

            return Scaffold(
              appBar: AppHeaderBar(meta: streakMeta),
              body: !loaded
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screen,
                        AppSpacing.s8,
                        AppSpacing.screen,
                        AppSpacing.s22,
                      ),
                      children: [
                        Text(
                          RussianDate.weekdayTitle(now),
                          style: AppTypography.title.copyWith(
                            color: colors.ink,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s4),
                        Text(
                          RussianDate.dayAndMonth(now),
                          style: AppTypography.caption.copyWith(
                            color: colors.muted,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s22),
                        if (planned == 0 && plan?.unit == null)
                          const EmptyState(
                            message:
                                'Пока нечего повторять — пройдите диктант в любом юните, '
                                'и выученные слова появятся здесь по расписанию.',
                          )
                        else ...[
                          if (planned > 0) ...[
                            SkillRow(
                              number: '01',
                              label: 'Слова',
                              counter: '$doneToday / $planned',
                              progress: doneToday / planned,
                              started: doneToday > 0,
                            ),
                            const SizedBox(height: AppSpacing.s10),
                          ],
                          if (plan?.pack != null)
                            for (final row in const [
                              ('02', 'Чтение', PackPart.reading),
                              ('03', 'Аудирование', PackPart.listening),
                              ('04', 'Письмо', PackPart.writing),
                            ]) ...[
                              _skillRow(row.$1, row.$2, row.$3, plan!, now),
                              const SizedBox(height: AppSpacing.s10),
                            ],
                          const SizedBox(height: AppSpacing.s10),
                          AppCard(
                            dashed: true,
                            onTap: () => context.go('/courses'),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Слова с урока — сфоткайте лист или вставьте список',
                                    style: AppTypography.caption.copyWith(
                                      color: colors.muted,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.s14),
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.iconButton,
                                    ),
                                    border: Border.all(
                                      color: colors.lineStrong,
                                    ),
                                  ),
                                  child: Icon(Icons.add, color: colors.ink),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
              bottomNavigationBar: (plan?.steps.isEmpty ?? true) && total == 0
                  ? null
                  : StickyActionBar(
                      flexes: total > 0 && (plan?.steps.isNotEmpty ?? false)
                          ? const [1, 2]
                          : null,
                      children: [
                        if (total > 0)
                          GhostButton(
                            label: 'Только повторение',
                            onPressed: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const SrsReviewScreen(),
                                ),
                              );
                              ref.invalidate(streakDaysProvider);
                              ref.invalidate(reviewsTodayProvider);
                              ref.invalidate(todayPlanProvider);
                            },
                          ),
                        if (plan != null && plan.steps.isNotEmpty)
                          PrimaryButton(
                            label:
                                'Заниматься ${plan.totalMinutes} ${pluralRu(plan.totalMinutes, one: 'минуту', few: 'минуты', many: 'минут')}',
                            trailingIcon: Icons.arrow_forward,
                            onPressed: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => SessionScreen(plan: plan),
                                ),
                              );
                              ref.invalidate(streakDaysProvider);
                              ref.invalidate(reviewsTodayProvider);
                              ref.invalidate(todayPlanProvider);
                            },
                          )
                        else if (total > 0)
                          PrimaryButton(
                            label: 'Начать повторение',
                            trailingIcon: Icons.arrow_forward,
                            onPressed: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const SrsReviewScreen(),
                                ),
                              );
                              ref.invalidate(streakDaysProvider);
                              ref.invalidate(reviewsTodayProvider);
                              ref.invalidate(todayPlanProvider);
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

  /// Row 02-04: one block per skill, today's state. A part that is not
  /// ready yet says so instead of pretending to be empty.
  Widget _skillRow(
    String number,
    String label,
    PackPart part,
    TodayPlan plan,
    DateTime now,
  ) {
    final ready = plan.readyParts.contains(part);
    final done = plan.doneToday(part, now);
    return SkillRow(
      number: number,
      label: label,
      counter: !ready ? 'не готово' : (done ? '1 / 1' : '0 / 1'),
      progress: done ? 1 : 0,
      started: done,
    );
  }
}

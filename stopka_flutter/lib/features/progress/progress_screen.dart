import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/llm/writing_check_service.dart' show mistakeCategoryNamesRu;
import '../../core/text/russian_plural.dart';
import '../../core/theme/app_theme_extension.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_header_bar.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/segmented_choice.dart';
import '../../domain/repositories/session_stats_repository.dart';
import '../session/today_plan.dart';
import 'weak_practice_screen.dart';

/// Mistakes over the last N days, grouped by category.
final mistakeGroupsProvider = FutureProvider.autoDispose
    .family<List<MistakeGroup>, int>((ref, days) {
      return ref
          .watch(sessionStatsRepositoryProvider)
          .mistakesSince(DateTime.now().subtract(Duration(days: days)));
    });

final recentMistakesProvider = FutureProvider.autoDispose<List<MistakeItem>>((
  ref,
) {
  return ref.watch(sessionStatsRepositoryProvider).recentMistakes(limit: 15);
});

String _categoryName(String category) =>
    mistakeCategoryNamesRu[category] ?? category;

String _skillName(String skill) => switch (skill) {
  'writing' => 'Письмо',
  'grammar' => 'Грамматика',
  _ => skill,
};

/// The "Прогресс" tab: where the mistakes pile up, and a way to train them.
class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  int _days = 7;

  Future<void> _train(MistakeGroup group) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            WeakPracticeScreen(category: group.category, skill: group.skill),
      ),
    );
    ref.invalidate(mistakeGroupsProvider);
    ref.invalidate(recentMistakesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final groups = ref.watch(mistakeGroupsProvider(_days)).value;
    final recent = ref.watch(recentMistakesProvider).value ?? const [];

    return Scaffold(
      appBar: const AppHeaderBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.s8,
          AppSpacing.screen,
          AppSpacing.s22,
        ),
        children: [
          Text(
            'Ошибки',
            style: AppTypography.title.copyWith(color: colors.ink),
          ),
          const SizedBox(height: AppSpacing.s14),
          SegmentedChoice<int>(
            options: const [
              ChoiceOption(7, '7 дней'),
              ChoiceOption(30, '30 дней'),
            ],
            selected: _days,
            onChanged: (d) => setState(() => _days = d),
          ),
          const SizedBox(height: AppSpacing.s22),
          if (groups == null)
            const Center(child: CircularProgressIndicator())
          else if (groups.isEmpty)
            const EmptyState(
              message: 'За этот период ошибок нет. Они появятся здесь после грамматики и письма.',
            )
          else
            ..._buildStats(context, groups, recent),
        ],
      ),
    );
  }

  List<Widget> _buildStats(
    BuildContext context,
    List<MistakeGroup> groups,
    List<MistakeItem> recent,
  ) {
    final colors = context.colors;
    final bySkill = <String, int>{};
    for (final g in groups) {
      bySkill.update(g.skill, (n) => n + g.count, ifAbsent: () => g.count);
    }
    final skills = bySkill.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxSkill = skills.first.value;
    final maxGroup = groups.first.count;
    final weakest = groups.first;

    return [
      Text(
        'По навыкам',
        style: AppTypography.heading.copyWith(color: colors.ink),
      ),
      const SizedBox(height: AppSpacing.s10),
      for (final e in skills) ...[
        _BarRow(label: _skillName(e.key), count: e.value, max: maxSkill),
        const SizedBox(height: AppSpacing.s10),
      ],
      const SizedBox(height: AppSpacing.s10),
      Text(
        'По категориям',
        style: AppTypography.heading.copyWith(color: colors.ink),
      ),
      const SizedBox(height: AppSpacing.s10),
      for (final g in groups.take(8)) ...[
        _BarRow(
          label: _categoryName(g.category),
          hint: _skillName(g.skill),
          count: g.count,
          max: maxGroup,
          onTap: () => _train(g),
        ),
        const SizedBox(height: AppSpacing.s10),
      ],
      const SizedBox(height: AppSpacing.s8),
      PrimaryButton(
        label: 'Тренировать: ${_categoryName(weakest.category)}',
        trailingIcon: Icons.arrow_forward,
        onPressed: () => _train(weakest),
      ),
      if (recent.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.s30),
        Text(
          'Последние разборы',
          style: AppTypography.heading.copyWith(color: colors.ink),
        ),
        const SizedBox(height: AppSpacing.s10),
        for (final m in recent) ...[
          _MistakeCard(item: m),
          const SizedBox(height: AppSpacing.s10),
        ],
      ],
    ];
  }
}

/// Label, a count, and a straight 3px bar scaled to the largest row.
class _BarRow extends StatelessWidget {
  final String label;
  final String? hint;
  final int count;
  final int max;
  final VoidCallback? onTap;

  const _BarRow({
    required this.label,
    this.hint,
    required this.count,
    required this.max,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: label,
                        style: AppTypography.label.copyWith(color: colors.ink),
                      ),
                      if (hint != null)
                        TextSpan(
                          text: '  $hint',
                          style: AppTypography.caption.copyWith(
                            color: colors.muted,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Text(
                '$count ${pluralRu(count, one: 'ошибка', few: 'ошибки', many: 'ошибок')}',
                style: AppTypography.monoMeta.copyWith(color: colors.muted),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s10),
          SizedBox(
            height: 3,
            child: LayoutBuilder(
              builder: (context, box) => Stack(
                children: [
                  Positioned.fill(child: ColoredBox(color: colors.line)),
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: box.maxWidth * (max == 0 ? 0 : count / max),
                    child: ColoredBox(color: colors.accent),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MistakeCard extends StatelessWidget {
  final MistakeItem item;

  const _MistakeCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_categoryName(item.category)} · ${_skillName(item.skill)}',
            style: AppTypography.monoMeta.copyWith(color: colors.muted),
          ),
          if (item.original.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s8),
            Text(
              item.original,
              style: AppTypography.monoWord.copyWith(
                fontSize: 15,
                color: colors.danger,
                decoration: TextDecoration.lineThrough,
              ),
            ),
          ],
          if (item.corrected.isNotEmpty)
            Text(
              item.corrected,
              style: AppTypography.monoWord.copyWith(
                fontSize: 15,
                color: colors.ink,
              ),
            ),
          if (item.explanation.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s8),
            Text(
              item.explanation,
              style: AppTypography.bodyText.copyWith(color: colors.body),
            ),
          ],
        ],
      ),
    );
  }
}

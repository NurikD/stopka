import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/llm/writing_check_service.dart' show mistakeCategoryNamesRu;
import '../../core/providers/core_providers.dart';
import '../../core/session/session_planner.dart';
import '../../core/text/russian_plural.dart';
import '../../core/theme/app_theme_extension.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_header_bar.dart';
import '../../core/widgets/ghost_button.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/sticky_action_bar.dart';
import '../../domain/repositories/session_stats_repository.dart';
import '../dictation/dictation_setup_screen.dart';
import '../pack/grammar_screen.dart';
import '../pack/listening_screen.dart';
import '../pack/reading_screen.dart';
import '../pack/writing_screen.dart';
import '../srs/srs_review_screen.dart';
import 'today_plan.dart';

enum _StepState { pending, done, skipped }

class _Summary {
  final int reviewed;
  final List<String> problemWords;
  final List<MistakeGroup> mistakes;

  const _Summary({
    required this.reviewed,
    required this.problemWords,
    required this.mistakes,
  });
}

/// The one-button session: walks through the planned blocks in order, then
/// shows what was done and where the trouble was.
class SessionScreen extends ConsumerStatefulWidget {
  final TodayPlan plan;

  const SessionScreen({super.key, required this.plan});

  @override
  ConsumerState<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends ConsumerState<SessionScreen> {
  late final DateTime _startedAt = DateTime.now();
  late final List<_StepState> _states = List.filled(
    widget.plan.steps.length,
    _StepState.pending,
  );
  _Summary? _summary;
  bool _opening = false;

  int? get _currentIndex {
    final i = _states.indexOf(_StepState.pending);
    return i < 0 ? null : i;
  }

  static String _title(SessionStepKind kind) => switch (kind) {
    SessionStepKind.review => 'Повторение слов',
    SessionStepKind.dictation => 'Диктант новых слов',
    SessionStepKind.reading => 'Чтение',
    SessionStepKind.listening => 'Аудирование',
    SessionStepKind.grammar => 'Грамматика',
    SessionStepKind.writing => 'Письмо',
  };

  Widget _screenFor(SessionStep step) {
    final plan = widget.plan;
    return switch (step.kind) {
      SessionStepKind.review => const SrsReviewScreen(),
      SessionStepKind.dictation => DictationSetupScreen(
        setId: plan.setId!,
        setTitle: plan.unit?.code ?? 'слова',
      ),
      SessionStepKind.reading => ReadingScreen(pack: plan.pack!),
      SessionStepKind.listening => ListeningScreen(pack: plan.pack!),
      SessionStepKind.grammar => GrammarScreen(pack: plan.pack!),
      SessionStepKind.writing => WritingScreen(pack: plan.pack!),
    };
  }

  Future<void> _open(int index) async {
    if (_opening) return;
    setState(() => _opening = true);
    final step = widget.plan.steps[index];
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => _screenFor(step)));
    if (!mounted) return;

    var done = true;
    final part = step.packPart;
    if (part != null) {
      // A part counts once its result was saved during this session.
      final progress = await ref
          .read(packRepositoryProvider)
          .getProgress(widget.plan.pack!.packId);
      final at = progress[part]?.completedAt;
      done = at != null && !at.isBefore(_startedAt);
    }
    if (!mounted) return;
    setState(() {
      _opening = false;
      if (done) _states[index] = _StepState.done;
    });
    await _finishIfOver();
  }

  Future<void> _skip(int index) async {
    setState(() => _states[index] = _StepState.skipped);
    await _finishIfOver();
  }

  Future<void> _finishIfOver() async {
    if (_currentIndex != null) return;
    final stats = ref.read(sessionStatsRepositoryProvider);
    final cards = ref.read(wordCardRepositoryProvider);

    final reviewed = await ref
        .read(cardStateRepositoryProvider)
        .countReviewsSince(_startedAt);
    final lapsedIds = await stats.lapsedCardIdsSince(_startedAt);
    final problemWords = <String>[];
    for (final id in lapsedIds.take(6)) {
      final card = await cards.getCard(id);
      if (card != null) {
        problemWords.add(
          card.translation.isEmpty
              ? card.term
              : '${card.term} — ${card.translation}',
        );
      }
    }
    final mistakes = await stats.mistakesSince(_startedAt);
    if (!mounted) return;
    ref.invalidate(streakDaysProvider);
    ref.invalidate(reviewsTodayProvider);
    ref.invalidate(todayPlanProvider);
    setState(
      () => _summary = _Summary(
        reviewed: reviewed,
        problemWords: problemWords,
        mistakes: mistakes,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summary;
    return Scaffold(
      appBar: const AppHeaderBar(nested: true, title: 'занятие'),
      body: summary == null
          ? _buildPlan(context)
          : _buildSummary(context, summary),
      bottomNavigationBar: summary != null
          ? StickyActionBar(
              children: [
                PrimaryButton(
                  label: 'Готово',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            )
          : _buildActions(),
    );
  }

  Widget? _buildActions() {
    final index = _currentIndex;
    if (index == null) return null;
    final started = _states.any((s) => s != _StepState.pending);
    return StickyActionBar(
      flexes: const [1, 2],
      children: [
        GhostButton(
          label: 'Пропустить',
          onPressed: _opening ? null : () => _skip(index),
        ),
        PrimaryButton(
          label: started ? 'Дальше' : 'Начать',
          trailingIcon: Icons.arrow_forward,
          onPressed: _opening ? null : () => _open(index),
        ),
      ],
    );
  }

  Widget _buildPlan(BuildContext context) {
    final colors = context.colors;
    final plan = widget.plan;
    final current = _currentIndex;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.s8,
        AppSpacing.screen,
        AppSpacing.s22,
      ),
      children: [
        Text(
          'Занятие на ${plan.totalMinutes} ${pluralRu(plan.totalMinutes, one: 'минуту', few: 'минуты', many: 'минут')}',
          style: AppTypography.title.copyWith(color: colors.ink),
        ),
        const SizedBox(height: AppSpacing.s8),
        Text(
          'Приложение собрало план само. Можно пропустить любой блок.',
          style: AppTypography.caption.copyWith(color: colors.muted),
        ),
        const SizedBox(height: AppSpacing.s22),
        for (var i = 0; i < plan.steps.length; i++) ...[
          _StepCard(
            number: (i + 1).toString().padLeft(2, '0'),
            title: _title(plan.steps[i].kind),
            minutes: plan.steps[i].minutes,
            state: _states[i],
            current: i == current,
          ),
          const SizedBox(height: AppSpacing.s10),
        ],
      ],
    );
  }

  Widget _buildSummary(BuildContext context, _Summary summary) {
    final colors = context.colors;
    final steps = widget.plan.steps;
    final doneCount = _states.where((s) => s == _StepState.done).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.s8,
        AppSpacing.screen,
        AppSpacing.s22,
      ),
      children: [
        Text(
          'Занятие закончено',
          style: AppTypography.title.copyWith(color: colors.ink),
        ),
        const SizedBox(height: AppSpacing.s22),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$doneCount из ${steps.length}',
                style: AppTypography.display.copyWith(color: colors.ink),
              ),
              Text(
                'блоков сделано'
                '${summary.reviewed > 0 ? ' · ${summary.reviewed} ${pluralRu(summary.reviewed, one: 'ответ', few: 'ответа', many: 'ответов')} в повторении' : ''}',
                style: AppTypography.bodyText.copyWith(color: colors.muted),
              ),
            ],
          ),
        ),
        if (summary.problemWords.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s22),
          Text(
            'Слова, которые не вспомнились',
            style: AppTypography.heading.copyWith(color: colors.ink),
          ),
          const SizedBox(height: AppSpacing.s10),
          for (final word in summary.problemWords)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s4),
              child: Text(
                word,
                style: AppTypography.monoWord.copyWith(
                  fontSize: 15,
                  color: colors.ink,
                ),
              ),
            ),
        ],
        if (summary.mistakes.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s22),
          Text(
            'Над чем поработать',
            style: AppTypography.heading.copyWith(color: colors.ink),
          ),
          const SizedBox(height: AppSpacing.s10),
          for (final m in summary.mistakes.take(5))
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s4),
              child: Text(
                '${mistakeCategoryNamesRu[m.category] ?? m.category} · ${m.skill == 'writing' ? 'письмо' : 'грамматика'} · ×${m.count}',
                style: AppTypography.bodyText.copyWith(color: colors.body),
              ),
            ),
        ],
        if (summary.problemWords.isEmpty && summary.mistakes.isEmpty) ...[
          const SizedBox(height: AppSpacing.s22),
          Text(
            'Проблемных мест сегодня не набралось.',
            style: AppTypography.caption.copyWith(color: colors.muted),
          ),
        ],
      ],
    );
  }
}

class _StepCard extends StatelessWidget {
  final String number;
  final String title;
  final int minutes;
  final _StepState state;
  final bool current;

  const _StepCard({
    required this.number,
    required this.title,
    required this.minutes,
    required this.state,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final finished = state != _StepState.pending;
    return AppCard(
      child: Row(
        children: [
          SizedBox(
            width: AppSpacing.s30,
            child: Text(
              number,
              style: AppTypography.monoMeta.copyWith(
                fontWeight: FontWeight.w600,
                color: current || state == _StepState.done
                    ? colors.accent
                    : colors.lineStrong,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.heading.copyWith(
                    color: finished ? colors.muted : colors.ink,
                  ),
                ),
                const SizedBox(height: AppSpacing.s4),
                Text(switch (state) {
                  _StepState.done => 'Сделано',
                  _StepState.skipped => 'Пропущено',
                  _StepState.pending => '≈ $minutes мин',
                }, style: AppTypography.caption.copyWith(color: colors.muted)),
              ],
            ),
          ),
          if (state == _StepState.done)
            Icon(Icons.check, color: colors.success),
        ],
      ),
    );
  }
}

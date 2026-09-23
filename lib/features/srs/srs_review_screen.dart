import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/core_providers.dart';
import '../../core/srs/srs_engine.dart' as engine;
import '../../core/theme/app_theme_extension.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/sticky_action_bar.dart';
import '../../domain/models/card_state.dart' as domain;
import '../../domain/models/dictation_session.dart';
import '../../domain/models/word_card.dart';

class _QueueItem {
  final domain.CardState state;
  final WordCard card;

  _QueueItem(this.state, this.card);
}

enum _Phase { loading, reviewing, done }

/// The Anki-style review loop: show the prompt, reveal the answer, rate
/// your own recall. See PLAN.md "Интервальное повторение (принцип Anki)".
class SrsReviewScreen extends ConsumerStatefulWidget {
  const SrsReviewScreen({super.key});

  @override
  ConsumerState<SrsReviewScreen> createState() => _SrsReviewScreenState();
}

class _SrsReviewScreenState extends ConsumerState<SrsReviewScreen> {
  _Phase _phase = _Phase.loading;
  List<_QueueItem> _queue = [];
  int _index = 0;
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final stateRepo = ref.read(cardStateRepositoryProvider);
    final cardRepo = ref.read(wordCardRepositoryProvider);
    final limit = await ref.read(srsSettingsStoreProvider).getNewCardLimit();

    final now = DateTime.now().toUtc();
    final due = await stateRepo.getDueForReview(now: now);
    final fresh = await stateRepo.getNewCards(limit: limit);

    final items = <_QueueItem>[];
    for (final s in [...due, ...fresh]) {
      final card = await cardRepo.getCard(s.cardId);
      if (card != null) items.add(_QueueItem(s, card));
    }

    if (!mounted) return;
    setState(() {
      _queue = items;
      _index = 0;
      _revealed = false;
      _phase = items.isEmpty ? _Phase.done : _Phase.reviewing;
    });
  }

  _QueueItem get _current => _queue[_index];

  String get _prompt => _current.state.direction == DictationDirection.ruEn ? _current.card.translation : _current.card.term;

  String get _answer => _current.state.direction == DictationDirection.ruEn ? _current.card.term : _current.card.translation;

  Future<void> _rate(engine.SrsRating rating) async {
    final item = _current;
    final result = ref.read(srsEngineProvider).review(_toEngineSnapshot(item.state), rating);

    final updated = item.state.copyWith(
      due: result.snapshot.due,
      stability: result.snapshot.stability,
      difficulty: result.snapshot.difficulty,
      step: result.snapshot.step,
      reps: item.state.reps + 1,
      lapses: rating == engine.SrsRating.again ? item.state.lapses + 1 : item.state.lapses,
      state: domain.SrsState.values.byName(result.snapshot.state.name),
      lastReview: result.snapshot.lastReview,
    );
    await ref.read(cardStateRepositoryProvider).saveState(updated);

    if (!mounted) return;
    setState(() {
      _revealed = false;
      if (_index + 1 < _queue.length) {
        _index++;
      } else {
        _phase = _Phase.done;
      }
    });
  }

  engine.SrsSnapshot _toEngineSnapshot(domain.CardState s) {
    return engine.SrsSnapshot(
      state: engine.SrsCardState.values.byName(s.state.name),
      step: s.step,
      stability: s.stability,
      difficulty: s.difficulty,
      due: s.due,
      lastReview: s.lastReview,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Повторение')),
      body: switch (_phase) {
        _Phase.loading => const Center(child: CircularProgressIndicator()),
        _Phase.done => _buildDone(context),
        _Phase.reviewing => _buildReviewing(context),
      },
      bottomNavigationBar: _phase == _Phase.reviewing ? _buildActionBar(context) : null,
    );
  }

  Widget _buildDone(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Text('На сегодня всё!', style: AppTypography.title.copyWith(color: colors.textPrimary)),
    );
  }

  Widget _buildReviewing(BuildContext context) {
    final colors = context.colors;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${_index + 1} из ${_queue.length}',
              style: AppTypography.caption.copyWith(color: colors.textMuted),
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_prompt, textAlign: TextAlign.center, style: AppTypography.hero.copyWith(color: colors.textPrimary)),
                  if (_revealed) ...[
                    const SizedBox(height: AppSpacing.xl),
                    Divider(color: colors.hairline),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      _answer,
                      textAlign: TextAlign.center,
                      style: AppTypography.subtitle.copyWith(color: colors.accent),
                    ),
                    if (_current.card.transcription.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        _current.card.transcription,
                        style: AppTypography.transcription.copyWith(color: colors.textMuted),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    IconButton(
                      icon: const Icon(Icons.volume_up_outlined),
                      color: colors.textMuted,
                      onPressed: () => ref.read(ttsServiceProvider).speak(_current.card.term),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionBar(BuildContext context) {
    if (!_revealed) {
      return StickyActionBar(
        children: [
          FilledButton(
            onPressed: () => setState(() => _revealed = true),
            child: const Text('Показать ответ'),
          ),
        ],
      );
    }
    return StickyActionBar(
      children: [
        _RatingButton(label: 'Забыл', onPressed: () => _rate(engine.SrsRating.again)),
        _RatingButton(label: 'Трудно', onPressed: () => _rate(engine.SrsRating.hard)),
        _RatingButton(label: 'Хорошо', onPressed: () => _rate(engine.SrsRating.good)),
        _RatingButton(label: 'Легко', onPressed: () => _rate(engine.SrsRating.easy)),
      ],
    );
  }
}

class _RatingButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _RatingButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.textPrimary,
        side: BorderSide(color: colors.hairline),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      ),
      child: Text(label, style: AppTypography.label, textAlign: TextAlign.center),
    );
  }
}

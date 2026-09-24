import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/core_providers.dart';
import '../../core/srs/srs_engine.dart' as engine;
import '../../core/theme/app_theme_extension.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_header_bar.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/stacked_card.dart';
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
/// your own recall.
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

  bool get _ruToEn => _current.state.direction == DictationDirection.ruEn;

  String get _prompt => _ruToEn ? _current.card.translation : _current.card.term;

  String get _answer => _ruToEn ? _current.card.term : _current.card.translation;

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
    final stateRepo = ref.read(cardStateRepositoryProvider);
    await stateRepo.saveState(updated);
    await stateRepo.logReview(
      cardStateId: item.state.id,
      rating: domain.ReviewRating.values.byName(rating.name),
    );

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
      appBar: AppHeaderBar(
        nested: true,
        navIcon: Icons.close,
        title: _phase == _Phase.reviewing
            ? 'повторение · ${(_index + 1).toString().padLeft(2, '0')}/${_queue.length.toString().padLeft(2, '0')}'
            : 'повторение',
      ),
      body: switch (_phase) {
        _Phase.loading => const Center(child: CircularProgressIndicator()),
        _Phase.done => _buildDone(context),
        _Phase.reviewing => _buildReviewing(context),
      },
      bottomNavigationBar: switch (_phase) {
        _Phase.reviewing => _buildActionBar(context),
        _Phase.done => StickyActionBar(
            children: [PrimaryButton(label: 'Готово', onPressed: () => Navigator.of(context).pop())],
          ),
        _Phase.loading => null,
      },
    );
  }

  Widget _buildDone(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screen),
        child: AppCard(
          dashed: true,
          padding: const EdgeInsets.all(AppSpacing.s22),
          child: Text(
            'На сегодня всё',
            textAlign: TextAlign.center,
            style: AppTypography.heading.copyWith(color: colors.ink),
          ),
        ),
      ),
    );
  }

  Widget _buildReviewing(BuildContext context) {
    final colors = context.colors;
    final layers = (_queue.length - _index - 1).clamp(0, 2);

    // English text is mono; Russian is Onest.
    TextStyle promptStyle(bool english) => english
        ? AppTypography.monoWord.copyWith(fontSize: 34, height: 40 / 34, letterSpacing: 0)
        : AppTypography.display;

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.s22, AppSpacing.screen, AppSpacing.s22),
      children: [
        StackedCard(
          layers: layers,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s22),
            child: Column(
              children: [
                Text(
                  _prompt,
                  textAlign: TextAlign.center,
                  style: promptStyle(!_ruToEn).copyWith(color: colors.ink),
                ),
                if (_revealed) ...[
                  const SizedBox(height: AppSpacing.s22),
                  Divider(color: colors.line, height: 1),
                  const SizedBox(height: AppSpacing.s22),
                  Text(
                    _answer,
                    textAlign: TextAlign.center,
                    style: (_ruToEn ? AppTypography.monoWord.copyWith(fontSize: 26) : AppTypography.heading)
                        .copyWith(color: colors.accent),
                  ),
                  if (_current.card.transcription.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.s8),
                    Text(
                      _current.card.transcription,
                      style: AppTypography.transcription.copyWith(color: colors.muted),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.s8),
                  IconButton(
                    icon: const Icon(Icons.volume_up_outlined),
                    color: colors.muted,
                    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                    onPressed: () => ref.read(ttsServiceProvider).speak(_current.card.term),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionBar(BuildContext context) {
    if (!_revealed) {
      return StickyActionBar(
        children: [PrimaryButton(label: 'Показать ответ', onPressed: () => setState(() => _revealed = true))],
      );
    }
    return StickyActionBar(
      children: [
        _RatingButton(label: 'Забыл', onPressed: () => _rate(engine.SrsRating.again)),
        _RatingButton(label: 'Трудно', onPressed: () => _rate(engine.SrsRating.hard)),
        _RatingButton(label: 'Хорошо', primary: true, onPressed: () => _rate(engine.SrsRating.good)),
        _RatingButton(label: 'Легко', onPressed: () => _rate(engine.SrsRating.easy)),
      ],
    );
  }
}

/// Four ratings share one row, so these have tighter padding than the
/// full-width buttons. "Хорошо" is the ink-filled default.
class _RatingButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool primary;

  const _RatingButton({required this.label, required this.onPressed, this.primary = false});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button));
    const padding = EdgeInsets.symmetric(horizontal: AppSpacing.s4);
    final text = Text(label, style: AppTypography.label, maxLines: 1, textAlign: TextAlign.center);

    if (primary) {
      return FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 56),
          padding: padding,
          shape: shape,
          backgroundColor: colors.ink,
          foregroundColor: colors.inkOn,
        ),
        child: text,
      );
    }
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 56),
        padding: padding,
        shape: shape,
        foregroundColor: colors.muted,
        side: BorderSide(color: colors.lineStrong),
      ),
      child: text,
    );
  }
}

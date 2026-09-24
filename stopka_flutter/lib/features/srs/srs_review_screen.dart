import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dictation/answer_checker.dart';
import '../../core/llm/llm_exception.dart';
import '../../core/providers/core_providers.dart';
import '../../core/srs/auto_rating.dart';
import '../../core/srs/srs_engine.dart' as engine;
import '../../core/theme/app_theme_extension.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_header_bar.dart';
import '../../core/widgets/diff_row.dart';
import '../../core/widgets/dictation_field.dart';
import '../../core/widgets/ghost_button.dart';
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

/// The review loop: show the prompt, the learner types the answer, and the
/// checker — not the learner — decides the rating. Only a Russian answer
/// (English prompt), where synonyms are legitimate, can be overruled by the
/// learner ask the AI ("Мой ответ тоже верный?") — never grade themselves.
class SrsReviewScreen extends ConsumerStatefulWidget {
  const SrsReviewScreen({super.key});

  @override
  ConsumerState<SrsReviewScreen> createState() => _SrsReviewScreenState();
}

class _SrsReviewScreenState extends ConsumerState<SrsReviewScreen> {
  _Phase _phase = _Phase.loading;
  List<_QueueItem> _queue = [];
  int _index = 0;
  final _controller = TextEditingController();
  DictationVerdict? _verdict; // null while the learner is still answering
  bool _overruled = false;
  bool _appealed = false;
  bool _appealing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _check({bool skipped = false}) {
    final input = _controller.text.trim();
    if (!skipped && input.isEmpty) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _verdict = skipped
          ? DictationVerdict.skipped
          : AnswerChecker.check(userInput: input, correctAnswer: _answer);
      _overruled = false;
      _appealed = false;
    });
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
      _phase = items.isEmpty ? _Phase.done : _Phase.reviewing;
    });
  }

  _QueueItem get _current => _queue[_index];

  bool get _ruToEn => _current.state.direction == DictationDirection.ruEn;

  String get _prompt =>
      _ruToEn ? _current.card.translation : _current.card.term;

  String get _answer =>
      _ruToEn ? _current.card.term : _current.card.translation;

  Future<void> _appeal() async {
    final messenger = ScaffoldMessenger.of(context);
    if (!await ref.read(apiKeyStoreProvider).hasKey()) {
      messenger.showSnackBar(const SnackBar(
        content: Text('Проверка ответа через ИИ работает с ключом Gemini — добавьте его в «Профиле».'),
      ));
      return;
    }
    setState(() => _appealing = true);
    try {
      final result = await ref.read(answerAppealServiceProvider).appeal(
            term: _current.card.term,
            correctAnswer: _answer,
            userAnswer: _controller.text.trim(),
            direction: 'EN -> RU',
          );
      if (!mounted) return;
      setState(() {
        _appealing = false;
        _appealed = true;
        _overruled = result.accepted;
      });
      messenger.showSnackBar(SnackBar(
        content: Text(result.accepted ? 'ИИ согласен: ${result.explanationRu}' : result.explanationRu),
      ));
    } on LlmException catch (e) {
      if (!mounted) return;
      setState(() => _appealing = false);
      messenger.showSnackBar(SnackBar(content: Text(e.messageRu)));
    }
  }

  Future<void> _next() async {
    final verdict = _verdict;
    if (verdict == null) return;
    final rating = _overruled
        ? engine.SrsRating.good
        : ratingForVerdict(verdict);
    final item = _current;
    final result = ref
        .read(srsEngineProvider)
        .review(_toEngineSnapshot(item.state), rating);

    final updated = item.state.copyWith(
      due: result.snapshot.due,
      stability: result.snapshot.stability,
      difficulty: result.snapshot.difficulty,
      step: result.snapshot.step,
      reps: item.state.reps + 1,
      lapses: rating == engine.SrsRating.again
          ? item.state.lapses + 1
          : item.state.lapses,
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
    _controller.clear();
    setState(() {
      _verdict = null;
      _overruled = false;
      _appealed = false;
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
          children: [
            PrimaryButton(
              label: 'Готово',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
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
    final verdict = _verdict;

    // English text is mono; Russian is Onest.
    TextStyle promptStyle(bool english) => english
        ? AppTypography.monoWord.copyWith(
            fontSize: 34,
            height: 40 / 34,
            letterSpacing: 0,
          )
        : AppTypography.display;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.s22,
        AppSpacing.screen,
        AppSpacing.s22,
      ),
      children: [
        StackedCard(
          layers: layers,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s22),
            child: Text(
              _prompt,
              textAlign: TextAlign.center,
              style: promptStyle(!_ruToEn).copyWith(color: colors.ink),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s22),
        if (verdict == null)
          DictationField(
            key: ValueKey(_index),
            controller: _controller,
            onSubmitted: _check,
          )
        else
          _buildResult(context, verdict),
      ],
    );
  }

  Widget _buildResult(BuildContext context, DictationVerdict verdict) {
    final colors = context.colors;
    final input = _controller.text.trim();
    final correct = AnswerChecker.closestVariant(
      userInput: input,
      storedAnswer: _answer,
    );
    final accepted = _overruled || verdict == DictationVerdict.correct;

    final (String label, Color color) = _overruled
        ? ('Засчитано ИИ', colors.success)
        : switch (verdict) {
            DictationVerdict.correct => ('Верно', colors.success),
            DictationVerdict.typo => ('Почти, опечатка', colors.markLine),
            DictationVerdict.wrong => ('Неверно', colors.danger),
            DictationVerdict.skipped => ('Не знаю', colors.danger),
          };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.label.copyWith(color: color)),
        const SizedBox(height: AppSpacing.s10),
        if (!accepted && _ruToEn && input.isNotEmpty)
          DiffRow(user: input, correct: correct)
        else
          Text(
            correct,
            style:
                (_ruToEn
                        ? AppTypography.monoWord.copyWith(fontSize: 26)
                        : AppTypography.heading)
                    .copyWith(color: colors.ink),
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
          onPressed: () =>
              ref.read(ttsServiceProvider).speak(_current.card.term),
        ),
      ],
    );
  }

  Widget _buildActionBar(BuildContext context) {
    final verdict = _verdict;
    if (verdict == null) {
      return StickyActionBar(
        flexes: const [1, 2],
        children: [
          GhostButton(label: 'Не знаю', onPressed: () => _check(skipped: true)),
          PrimaryButton(label: 'Проверить', onPressed: _check),
        ],
      );
    }
    final canOverrule =
        !_ruToEn &&
        !_appealed &&
        !_overruled &&
        verdict != DictationVerdict.correct;
    return StickyActionBar(
      flexes: canOverrule ? const [1, 2] : null,
      children: [
        if (canOverrule)
          GhostButton(
            label: _appealing ? 'Проверяю…' : 'Мой ответ тоже верный?',
            onPressed: _appealing ? null : _appeal,
          ),
        PrimaryButton(
          label: 'Дальше',
          trailingIcon: Icons.arrow_forward,
          onPressed: _next,
        ),
      ],
    );
  }
}

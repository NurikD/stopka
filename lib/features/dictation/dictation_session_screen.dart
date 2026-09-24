import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dictation/answer_checker.dart';
import '../../core/dictation/dictation_engine.dart';
import '../../core/llm/llm_exception.dart';
import '../../core/providers/core_providers.dart';
import '../../core/text/russian_plural.dart';
import '../../core/theme/app_theme_extension.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_header_bar.dart';
import '../../core/widgets/diff_row.dart';
import '../../core/widgets/dictation_field.dart';
import '../../core/widgets/ghost_button.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/stack_progress.dart';
import '../../core/widgets/stacked_card.dart';
import '../../core/widgets/sticky_action_bar.dart';
import '../../domain/models/dictation_answer.dart' as domain;
import '../../domain/models/dictation_session.dart';
import '../../domain/models/word_card.dart';
import 'session_summary_screen.dart';

enum _Phase { loading, playing, showingResult, stackReview, finishing }

class _RoundAnswer {
  final DictationWord word;
  final String userInput;
  final DictationVerdict verdict;
  String? answerId; // set once persisted, used by the AI-appeal update

  _RoundAnswer({required this.word, required this.userInput, required this.verdict});
}

class DictationSessionScreen extends ConsumerStatefulWidget {
  final String setId;
  final DictationDirection direction;
  final int stackSize;
  final int requiredStreak;

  /// When set, restricts the session to just these cards — used by "Повторить проблемные".
  final List<WordCard>? onlyCards;

  /// When both are set, continues an existing session instead of starting
  /// a fresh one — see DictationSetupScreen's "Продолжить" path.
  final DictationEngine? resumedEngine;
  final String? resumedSessionId;

  const DictationSessionScreen({
    super.key,
    required this.setId,
    required this.direction,
    required this.stackSize,
    required this.requiredStreak,
    this.onlyCards,
    this.resumedEngine,
    this.resumedSessionId,
  });

  /// Builds the DictationWord list a set's cards turn into for a given
  /// direction — shared by a fresh session and by DictationSetupScreen
  /// when it needs to replay history to resume or close out a session.
  static List<DictationWord> buildWords(List<WordCard> cards, DictationDirection direction) {
    final ruToEn = direction == DictationDirection.ruEn;
    return cards
        .map((c) => DictationWord(
              cardId: c.id,
              prompt: ruToEn ? c.translation : c.term,
              correctAnswer: ruToEn ? c.term : c.translation,
            ))
        .where((w) => w.prompt.isNotEmpty && w.correctAnswer.isNotEmpty)
        .toList();
  }

  @override
  ConsumerState<DictationSessionScreen> createState() => _DictationSessionScreenState();
}

class _DictationSessionScreenState extends ConsumerState<DictationSessionScreen> {
  _Phase _phase = _Phase.loading;
  late DictationEngine _engine;
  late String _sessionId;
  late Map<String, WordCard> _cardsById;

  List<DictationWord> _stack = [];
  int _index = 0;
  final _inputController = TextEditingController();
  final _focusNode = FocusNode();

  final List<_RoundAnswer> _currentStackAnswers = [];
  final Map<String, int> _mistakeCounts = {};
  _RoundAnswer? _lastAnswer;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final cards = widget.onlyCards ?? await ref.read(wordCardRepositoryProvider).watchCards(widget.setId).first;
    _cardsById = {for (final c in cards) c.id: c};

    if (widget.resumedEngine != null && widget.resumedSessionId != null) {
      _engine = widget.resumedEngine!;
      _sessionId = widget.resumedSessionId!;
    } else {
      final words = DictationSessionScreen.buildWords(cards, widget.direction);
      _engine = DictationEngine(words: words, stackSize: widget.stackSize, requiredStreak: widget.requiredStreak);

      final session = await ref.read(dictationRepositoryProvider).startSession(
            setId: widget.setId,
            direction: widget.direction,
            stackSize: widget.stackSize,
            requiredStreak: widget.requiredStreak,
          );
      _sessionId = session.id;
    }

    if (!mounted) return;
    _startNextStack();
  }

  void _startNextStack() {
    setState(() {
      _stack = _engine.nextStack();
      _index = 0;
      _currentStackAnswers.clear();
      _phase = _Phase.playing;
      _inputController.clear();
    });
  }

  DictationWord get _currentWord => _stack[_index];

  Future<void> _submit({required bool skipped}) async {
    final userInput = skipped ? '' : _inputController.text;
    final verdict = skipped
        ? DictationVerdict.skipped
        : AnswerChecker.check(userInput: userInput, correctAnswer: _currentWord.correctAnswer);

    _engine.recordAnswer(_currentWord.cardId, verdict);
    if (verdict != DictationVerdict.correct) {
      _mistakeCounts.update(_currentWord.cardId, (v) => v + 1, ifAbsent: () => 1);
    }

    final answer = _RoundAnswer(word: _currentWord, userInput: userInput, verdict: verdict);
    _currentStackAnswers.add(answer);

    if (verdict == DictationVerdict.correct) {
      HapticFeedback.lightImpact();
    } else if (verdict != DictationVerdict.skipped) {
      HapticFeedback.mediumImpact();
    }

    setState(() {
      _lastAnswer = answer;
      _phase = _Phase.showingResult;
    });

    final repoAnswer = await ref.read(dictationRepositoryProvider).recordAnswer(
          sessionId: _sessionId,
          cardId: _currentWord.cardId,
          roundIndex: _engine.roundIndex,
          userInput: userInput,
          verdict: _toDomainVerdict(verdict),
        );
    answer.answerId = repoAnswer.id;

    // Only the transition itself is skipped under reduce-motion — the
    // pause here is reading time for the result, not decorative motion.
    final reduceMotion = mounted && MediaQuery.disableAnimationsOf(context);
    final transitionDuration = reduceMotion ? Duration.zero : AppMotion.checkDuration;
    await Future.delayed(transitionDuration + const Duration(milliseconds: 500));
    if (!mounted) return;

    if (_index + 1 < _stack.length) {
      setState(() {
        _index++;
        _inputController.clear();
        _phase = _Phase.playing;
      });
    } else {
      setState(() => _phase = _Phase.stackReview);
    }
  }

  domain.DictationAnswerVerdict _toDomainVerdict(DictationVerdict v) {
    return domain.DictationAnswerVerdict.values.byName(v.name);
  }

  Future<void> _onStackReviewContinue() async {
    if (_engine.isFinished) {
      setState(() => _phase = _Phase.finishing);
      await ref.read(dictationRepositoryProvider).finishSession(
            _sessionId,
            roundsCount: _engine.roundIndex,
            totalWords: _engine.masteredWords.length,
          );

      // Mastering a word in dictation is what sets its starting SRS state
      // (PLAN.md: "результаты диктанта задают стартовое состояние
      // карточек") — it enters the deck due immediately, ungraded.
      final cardStateRepo = ref.read(cardStateRepositoryProvider);
      for (final word in _engine.masteredWords) {
        await cardStateRepo.ensureState(word.cardId, widget.direction);
      }

      if (!mounted) return;
      final problemCardIds = (_mistakeCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
          .take(10)
          .map((e) => e.key)
          .toList();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => SessionSummaryScreen(
            setId: widget.setId,
            direction: widget.direction,
            roundsCount: _engine.roundIndex,
            totalWords: _engine.masteredWords.length,
            problemCards: problemCardIds.map((id) => _cardsById[id]).whereType<WordCard>().toList(),
          ),
        ),
      );
    } else {
      _startNextStack();
    }
  }

  Future<void> _appeal(_RoundAnswer answer) async {
    try {
      final result = await ref.read(answerAppealServiceProvider).appeal(
            term: _cardsById[answer.word.cardId]?.term ?? answer.word.correctAnswer,
            correctAnswer: answer.word.correctAnswer,
            userAnswer: answer.userInput,
            direction: widget.direction == DictationDirection.ruEn ? 'RU -> EN' : 'EN -> RU',
          );
      if (!mounted) return;
      if (result.accepted && answer.answerId != null) {
        await ref.read(dictationRepositoryProvider).updateAnswerVerdict(
              answer.answerId!,
              domain.DictationAnswerVerdict.correct,
              domain.DictationCheckedBy.llm,
            );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.accepted ? 'ИИ согласен: ${result.explanationRu}' : result.explanationRu)),
      );
    } on LlmException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.messageRu)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final inRound = _phase == _Phase.playing || _phase == _Phase.showingResult;
    return Scaffold(
      appBar: AppHeaderBar(
        nested: true,
        navIcon: Icons.close,
        title: 'Диктант',
        meta: inRound ? 'раунд ${_engine.roundIndex}' : null,
      ),
      body: switch (_phase) {
        _Phase.loading || _Phase.finishing => const Center(child: CircularProgressIndicator()),
        _Phase.playing || _Phase.showingResult => _buildRound(context),
        _Phase.stackReview => _buildStackReview(context),
      },
    );
  }

  bool get _promptIsEnglish => widget.direction == DictationDirection.enRu;

  Widget _buildRound(BuildContext context) {
    final colors = context.colors;
    // DESIGN_v2: reduce-motion makes transitions instant; haptics stay.
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final checkDuration = reduceMotion ? Duration.zero : AppMotion.checkDuration;

    final showingResult = _phase == _Phase.showingResult;
    final passed = showingResult ? _index + 1 : _index;
    final wrong = {
      for (var i = 0; i < _currentStackAnswers.length; i++)
        if (_currentStackAnswers[i].verdict != DictationVerdict.correct) i,
    };
    final layers = (_engine.unintroducedCount / widget.stackSize).ceil();

    // English prompts (EN -> RU) are mono like every English word.
    final promptStyle = _promptIsEnglish
        ? AppTypography.monoWord.copyWith(fontSize: 34, height: 40 / 34, letterSpacing: 0)
        : AppTypography.display;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.s8, AppSpacing.screen, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StackProgress(total: _stack.length, current: passed, wrong: wrong),
              const SizedBox(height: AppSpacing.s8),
              Text(
                '${_index + 1} / ${_stack.length}',
                style: AppTypography.monoMeta.copyWith(color: colors.muted),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.s22, AppSpacing.screen, AppSpacing.s22),
            children: [
              StackedCard(
                layers: layers,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.s30),
                  child: Center(
                    child: Text(
                      _currentWord.prompt,
                      textAlign: TextAlign.center,
                      style: promptStyle.copyWith(color: colors.ink),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s22),
              AnimatedSwitcher(
                duration: checkDuration,
                switchInCurve: AppMotion.checkCurve,
                switchOutCurve: AppMotion.checkCurve,
                child: showingResult ? _buildResultReveal(context) : _buildInput(context),
              ),
            ],
          ),
        ),
        if (_phase == _Phase.playing)
          StickyActionBar(
            children: [
              GhostButton(label: 'Не знаю', onPressed: () => _submit(skipped: true)),
              PrimaryButton(
                label: 'Проверить',
                variant: PrimaryButtonVariant.accent,
                onPressed: () => _submit(skipped: false),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildInput(BuildContext context) {
    return DictationField(
      key: const ValueKey('input'),
      controller: _inputController,
      focusNode: _focusNode,
      onSubmitted: () => _submit(skipped: false),
    );
  }

  Widget _buildResultReveal(BuildContext context) {
    final colors = context.colors;
    final answer = _lastAnswer!;
    final (String label, Color color) = switch (answer.verdict) {
      DictationVerdict.correct => ('Верно', colors.success),
      DictationVerdict.typo => ('Почти — опечатка', colors.markLine),
      DictationVerdict.wrong => ('Неверно', colors.danger),
      DictationVerdict.skipped => ('Пропущено', colors.muted),
    };
    return Column(
      key: const ValueKey('result'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: AppTypography.heading.copyWith(color: color)),
        if (answer.verdict != DictationVerdict.correct) ...[
          const SizedBox(height: AppSpacing.s14),
          AppCard(
            child: DiffRow(
              user: answer.userInput,
              correct: AnswerChecker.closestVariant(
                userInput: answer.userInput,
                storedAnswer: answer.word.correctAnswer,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStackReview(BuildContext context) {
    final colors = context.colors;
    final mistakes = _currentStackAnswers.where((a) => a.verdict != DictationVerdict.correct).toList();
    final correctCount = _currentStackAnswers.length - mistakes.length;
    final returning = pluralRu(
      mistakes.length,
      one: 'слово вернётся',
      few: 'слова вернутся',
      many: 'слов вернутся',
    );

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.s8, AppSpacing.screen, AppSpacing.s22),
            children: [
              Text(
                '$correctCount из ${_currentStackAnswers.length}',
                style: AppTypography.display.copyWith(color: colors.ink),
              ),
              const SizedBox(height: AppSpacing.s4),
              Text(
                mistakes.isEmpty ? 'Всё верно в этом раунде' : '${mistakes.length} $returning в стопку',
                style: AppTypography.bodyText.copyWith(color: colors.muted),
              ),
              const SizedBox(height: AppSpacing.s22),
              for (final a in mistakes) ...[
                _buildMistake(context, a),
                const SizedBox(height: AppSpacing.s10),
              ],
            ],
          ),
        ),
        StickyActionBar(
          children: [
            PrimaryButton(
              label: _engine.isFinished ? 'Завершить диктант' : 'Следующая стопка',
              onPressed: _onStackReviewContinue,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMistake(BuildContext context, _RoundAnswer a) {
    final colors = context.colors;
    final card = _cardsById[a.word.cardId];
    final correct = AnswerChecker.closestVariant(userInput: a.userInput, storedAnswer: a.word.correctAnswer);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(a.word.prompt, style: AppTypography.caption.copyWith(color: colors.muted)),
              ),
              if (card != null && card.transcription.isNotEmpty)
                Text(card.transcription, style: AppTypography.transcription.copyWith(color: colors.muted)),
              IconButton(
                icon: const Icon(Icons.volume_up_outlined),
                color: colors.muted,
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                onPressed: () => ref.read(ttsServiceProvider).speak(card?.term ?? correct),
              ),
            ],
          ),
          DiffRow(user: a.userInput, correct: correct),
          if (a.verdict == DictationVerdict.wrong || a.verdict == DictationVerdict.typo)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => _appeal(a),
                child: Text('Мой ответ тоже верный?', style: AppTypography.label.copyWith(color: colors.accent)),
              ),
            ),
        ],
      ),
    );
  }
}

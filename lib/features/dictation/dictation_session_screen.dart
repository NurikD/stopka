import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dictation/answer_checker.dart';
import '../../core/dictation/dictation_engine.dart';
import '../../core/llm/llm_exception.dart';
import '../../core/providers/core_providers.dart';
import '../../core/theme/app_theme_extension.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/ghost_button.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/result_row.dart';
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

  const DictationSessionScreen({
    super.key,
    required this.setId,
    required this.direction,
    required this.stackSize,
    required this.requiredStreak,
    this.onlyCards,
  });

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

    final words = cards.map((c) {
      final ruToEn = widget.direction == DictationDirection.ruEn;
      return DictationWord(
        cardId: c.id,
        prompt: ruToEn ? c.translation : c.term,
        correctAnswer: ruToEn ? c.term : c.translation,
      );
    }).where((w) => w.prompt.isNotEmpty && w.correctAnswer.isNotEmpty).toList();

    _engine = DictationEngine(words: words, stackSize: widget.stackSize, requiredStreak: widget.requiredStreak);

    final session = await ref.read(dictationRepositoryProvider).startSession(
          setId: widget.setId,
          direction: widget.direction,
        );
    _sessionId = session.id;

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

    await Future.delayed(AppMotion.checkDuration + const Duration(milliseconds: 500));
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
    return Scaffold(
      appBar: AppBar(title: const Text('Диктант')),
      body: switch (_phase) {
        _Phase.loading || _Phase.finishing => const Center(child: CircularProgressIndicator()),
        _Phase.playing || _Phase.showingResult => _buildRound(context),
        _Phase.stackReview => _buildStackReview(context),
      },
    );
  }

  Widget _buildRound(BuildContext context) {
    final colors = context.colors;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
          child: Row(
            children: [
              Text(
                'Раунд ${_engine.roundIndex} · слово ${_index + 1} из ${_stack.length}',
                style: AppTypography.caption.copyWith(color: colors.textMuted),
              ),
              const Spacer(),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: LinearProgressIndicator(
            value: (_index + (_phase == _Phase.showingResult ? 1 : 0)) / _stack.length,
            color: colors.accent,
            backgroundColor: colors.hairline,
          ),
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: AppMotion.checkDuration,
            switchInCurve: AppMotion.checkCurve,
            switchOutCurve: AppMotion.checkCurve,
            child: _phase == _Phase.showingResult ? _buildResultReveal(context) : _buildInput(context),
          ),
        ),
        if (_phase == _Phase.playing)
          StickyActionBar(
            children: [
              GhostButton(label: 'Не знаю', onPressed: () => _submit(skipped: true)),
              PrimaryButton(label: 'Проверить', onPressed: () => _submit(skipped: false)),
            ],
          ),
      ],
    );
  }

  Widget _buildInput(BuildContext context) {
    final colors = context.colors;
    return Column(
      key: const ValueKey('input'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Center(
          child: Text(
            _currentWord.prompt,
            textAlign: TextAlign.center,
            style: AppTypography.hero.copyWith(color: colors.textPrimary),
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: TextField(
            controller: _inputController,
            focusNode: _focusNode,
            autofocus: true,
            textAlign: TextAlign.center,
            style: AppTypography.subtitle.copyWith(color: colors.textPrimary),
            decoration: const InputDecoration(hintText: 'ваш ответ', border: UnderlineInputBorder()),
            onSubmitted: (_) => _submit(skipped: false),
          ),
        ),
      ],
    );
  }

  Widget _buildResultReveal(BuildContext context) {
    final colors = context.colors;
    final answer = _lastAnswer!;
    final color = switch (answer.verdict) {
      DictationVerdict.correct => colors.statusCorrect,
      DictationVerdict.typo => colors.statusTypo,
      DictationVerdict.wrong => colors.statusWrong,
      DictationVerdict.skipped => colors.statusSkipped,
    };
    final label = switch (answer.verdict) {
      DictationVerdict.correct => 'Верно',
      DictationVerdict.typo => 'Почти — опечатка',
      DictationVerdict.wrong => 'Неверно',
      DictationVerdict.skipped => 'Пропущено',
    };
    return Center(
      key: const ValueKey('result'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: AppTypography.title.copyWith(color: color)),
          if (answer.verdict != DictationVerdict.correct) ...[
            const SizedBox(height: AppSpacing.md),
            Text('верно: ${answer.word.correctAnswer}', style: AppTypography.subtitle.copyWith(color: colors.textPrimary)),
          ],
        ],
      ),
    );
  }

  Widget _buildStackReview(BuildContext context) {
    final colors = context.colors;
    final mistakes = _currentStackAnswers.where((a) => a.verdict != DictationVerdict.correct).toList();
    final correctCount = _currentStackAnswers.length - mistakes.length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$correctCount из ${_currentStackAnswers.length}',
                style: AppTypography.hero.copyWith(color: colors.statusCorrect, fontSize: 32, height: 1.1),
              ),
              if (mistakes.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    '${mistakes.length} слов вернутся в стопку',
                    style: AppTypography.body.copyWith(color: colors.textMuted),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: mistakes.isEmpty
              ? Center(
                  child: Text('Всё верно в этом раунде!', style: AppTypography.body.copyWith(color: colors.textMuted)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  itemCount: mistakes.length,
                  itemBuilder: (context, i) {
                    final a = mistakes[i];
                    final card = _cardsById[a.word.cardId];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ResultRow(
                          term: a.word.correctAnswer,
                          transcription: card?.transcription ?? '',
                          correctAnswer: a.word.correctAnswer,
                          userAnswer: a.userInput,
                          verdict: switch (a.verdict) {
                            DictationVerdict.typo => ResultVerdict.typo,
                            DictationVerdict.wrong => ResultVerdict.wrong,
                            DictationVerdict.skipped => ResultVerdict.skipped,
                            DictationVerdict.correct => ResultVerdict.correct,
                          },
                          onPlayAudio: () => ref.read(ttsServiceProvider).speak(card?.term ?? a.word.correctAnswer),
                        ),
                        if (a.verdict == DictationVerdict.wrong || a.verdict == DictationVerdict.typo)
                          Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.md),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton(
                                onPressed: () => _appeal(a),
                                child: const Text('Мой ответ тоже верный?'),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
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
}

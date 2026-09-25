import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dictation/answer_checker.dart';
import '../../core/dictation/dictation_engine.dart';
import '../../core/providers/core_providers.dart';
import '../../core/theme/app_theme_extension.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_header_bar.dart';
import '../../core/widgets/ghost_button.dart';
import '../../core/widgets/labeled_field.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/segmented_choice.dart';
import '../../domain/models/dictation_answer.dart' as domain;
import '../../domain/models/dictation_session.dart';
import 'dictation_session_screen.dart';

enum _Mode { checking, resumeChoice, config }

/// Direction, stack size, and streak all live here rather than as global
/// settings — DESIGN.md's dictation screens assume you decide this right
/// before you start, not in a settings menu.
class DictationSetupScreen extends ConsumerStatefulWidget {
  final String setId;
  final String setTitle;

  const DictationSetupScreen({super.key, required this.setId, required this.setTitle});

  @override
  ConsumerState<DictationSetupScreen> createState() => _DictationSetupScreenState();
}

class _DictationSetupScreenState extends ConsumerState<DictationSetupScreen> {
  _Mode _mode = _Mode.checking;
  DictationSession? _unfinished;
  bool _resolving = false;

  DictationDirection _direction = DictationDirection.ruEn;
  int _stackSize = 12;
  static const _stackSizeChoices = [8, 10, 12, 15, 20];
  int _requiredStreak = 1;

  @override
  void initState() {
    super.initState();
    _checkForUnfinishedSession();
  }

  Future<void> _checkForUnfinishedSession() async {
    final unfinished = await ref.read(dictationRepositoryProvider).findUnfinishedSession(widget.setId);
    if (!mounted) return;
    setState(() {
      _unfinished = unfinished;
      _mode = unfinished != null ? _Mode.resumeChoice : _Mode.config;
    });
  }

  List<DictationHistoryEntry> _historyFor(List<domain.DictationAnswer> answers) {
    return answers
        .map((a) => DictationHistoryEntry(
              cardId: a.cardId,
              roundIndex: a.roundIndex,
              verdict: DictationVerdict.values.byName(a.verdict.name),
            ))
        .toList();
  }

  Future<void> _continueSession() async {
    final session = _unfinished!;
    setState(() => _resolving = true);

    final cards = await ref.read(wordCardRepositoryProvider).watchCards(widget.setId).first;
    final answers = await ref.read(dictationRepositoryProvider).getAnswers(session.id);
    final words = DictationSessionScreen.buildWords(cards, session.direction);
    final engine = DictationEngine.resume(
      words: words,
      answers: _historyFor(answers),
      stackSize: session.stackSize,
      requiredStreak: session.requiredStreak,
    );

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => DictationSessionScreen(
          setId: widget.setId,
          direction: session.direction,
          stackSize: session.stackSize,
          requiredStreak: session.requiredStreak,
          resumedEngine: engine,
          resumedSessionId: session.id,
        ),
      ),
    );
  }

  Future<void> _startOver() async {
    final session = _unfinished!;
    setState(() => _resolving = true);

    // Replay the abandoned session so we can close it out with real
    // numbers instead of zeros — not required for correctness, but there's
    // no reason to leave misleading stats behind.
    final cards = await ref.read(wordCardRepositoryProvider).watchCards(widget.setId).first;
    final answers = await ref.read(dictationRepositoryProvider).getAnswers(session.id);
    final words = DictationSessionScreen.buildWords(cards, session.direction);
    final engine = DictationEngine.resume(
      words: words,
      answers: _historyFor(answers),
      stackSize: session.stackSize,
      requiredStreak: session.requiredStreak,
    );
    await ref.read(dictationRepositoryProvider).finishSession(
          session.id,
          roundsCount: engine.roundIndex,
          totalWords: engine.masteredWords.length,
        );

    if (!mounted) return;
    setState(() {
      _unfinished = null;
      _mode = _Mode.config;
      _resolving = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeaderBar(nested: true, title: 'Диктант · ${widget.setTitle}'),
      body: switch (_mode) {
        _Mode.checking => const Center(child: CircularProgressIndicator()),
        _Mode.resumeChoice => _buildResumeChoice(context),
        _Mode.config => _buildConfig(context),
      },
    );
  }

  Widget _buildResumeChoice(BuildContext context) {
    final colors = context.colors;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screen),
      children: [
        AppCard(
          child: Text(
            'Есть незавершённая сессия по этому набору.',
            style: AppTypography.heading.copyWith(color: colors.ink),
          ),
        ),
        const SizedBox(height: AppSpacing.s22),
        PrimaryButton(label: 'Продолжить', onPressed: _resolving ? null : _continueSession, loading: _resolving),
        const SizedBox(height: AppSpacing.s10),
        GhostButton(label: 'Начать заново', onPressed: _resolving ? null : _startOver),
      ],
    );
  }

  Widget _buildConfig(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screen),
      children: [
        LabeledField(
          label: 'Направление',
          child: SegmentedChoice<DictationDirection>(
            options: const [
              ChoiceOption(DictationDirection.ruEn, 'RU / EN'),
              ChoiceOption(DictationDirection.enRu, 'EN / RU'),
            ],
            selected: _direction,
            onChanged: (v) => setState(() => _direction = v),
          ),
        ),
        const SizedBox(height: AppSpacing.s22),
        LabeledField(
          label: 'Слов в стопке',
          child: SegmentedChoice<int>(
            options: [for (final n in _stackSizeChoices) ChoiceOption(n, '$n')],
            selected: _stackSize,
            onChanged: (v) => setState(() => _stackSize = v),
          ),
        ),
        const SizedBox(height: AppSpacing.s22),
        LabeledField(
          label: 'Верных подряд, чтобы слово считалось выученным',
          child: SegmentedChoice<int>(
            options: const [ChoiceOption(1, '1'), ChoiceOption(2, '2')],
            selected: _requiredStreak,
            onChanged: (v) => setState(() => _requiredStreak = v),
          ),
        ),
        const SizedBox(height: AppSpacing.s30),
        PrimaryButton(
          label: 'Начать диктант',
          trailingIcon: Icons.arrow_forward,
          onPressed: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => DictationSessionScreen(
                setId: widget.setId,
                direction: _direction,
                stackSize: _stackSize,
                requiredStreak: _requiredStreak,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

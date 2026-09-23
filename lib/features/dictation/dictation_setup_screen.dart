import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dictation/answer_checker.dart';
import '../../core/dictation/dictation_engine.dart';
import '../../core/providers/core_providers.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/ghost_button.dart';
import '../../core/widgets/primary_button.dart';
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
      appBar: AppBar(title: Text('Диктант · ${widget.setTitle}')),
      body: switch (_mode) {
        _Mode.checking => const Center(child: CircularProgressIndicator()),
        _Mode.resumeChoice => _buildResumeChoice(context),
        _Mode.config => _buildConfig(context),
      },
    );
  }

  Widget _buildResumeChoice(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Есть незавершённая сессия по этому набору.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(label: 'Продолжить', onPressed: _resolving ? null : _continueSession, loading: _resolving),
          const SizedBox(height: AppSpacing.md),
          GhostButton(label: 'Начать заново', onPressed: _resolving ? null : _startOver),
        ],
      ),
    );
  }

  Widget _buildConfig(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text('Направление', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        SegmentedButton<DictationDirection>(
          segments: const [
            ButtonSegment(value: DictationDirection.ruEn, label: Text('RU → EN')),
            ButtonSegment(value: DictationDirection.enRu, label: Text('EN → RU')),
          ],
          selected: {_direction},
          onSelectionChanged: (s) => setState(() => _direction = s.first),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('Размер стопки', style: Theme.of(context).textTheme.titleLarge),
        Slider(
          value: _stackSize.toDouble(),
          min: 5,
          max: 20,
          divisions: 15,
          label: '$_stackSize',
          onChanged: (v) => setState(() => _stackSize = v.round()),
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Верных подряд для освоения слова', style: Theme.of(context).textTheme.titleLarge),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 1, label: Text('1')),
            ButtonSegment(value: 2, label: Text('2')),
          ],
          selected: {_requiredStreak},
          onSelectionChanged: (s) => setState(() => _requiredStreak = s.first),
        ),
        const SizedBox(height: AppSpacing.xxl),
        PrimaryButton(
          label: 'Начать диктант',
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

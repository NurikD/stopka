import 'package:flutter/material.dart';

import '../../core/llm/llm_exception.dart';
import '../../core/pack/exercise_check.dart';
import '../../core/pack/pack_content.dart';
import '../../core/text/russian_plural.dart';
import '../../core/theme/app_theme_extension.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/choice_tile.dart';
import '../../core/widgets/dictation_field.dart';
import '../../core/widgets/ghost_button.dart';
import '../../core/widgets/primary_button.dart';

/// Turns a comprehension question into a choice exercise, so reading and
/// listening questions run through the same flow as grammar exercises.
Exercise exerciseFromQuestion(Question q) => Exercise(
  kind: ExerciseKind.choice,
  prompt: q.prompt,
  options: q.options,
  answer: q.options[q.answerIndex],
  why: q.why,
);

/// The AI's verdict on a translation the checker rejected.
class AppealOutcome {
  final bool accepted;
  final String note;

  const AppealOutcome({required this.accepted, required this.note});
}

/// One exercise at a time: answer, see whether it was right and why, go on.
/// Every finished item is reported through [onAnswer] (with the final
/// correctness) and the whole run through [onFinished].
class ExerciseFlow extends StatefulWidget {
  final List<Exercise> items;
  final Future<void> Function(int index, String answer, bool correct) onAnswer;
  final Future<void> Function(int score, int total) onFinished;

  /// "Мой ответ тоже верный?" for translations, judged by the AI. Null hides
  /// the button. A translation can be right in another wording, but the
  /// learner never grades themselves: only this can flip a wrong answer.
  final Future<AppealOutcome> Function(Exercise exercise, String given)?
  onAppeal;

  const ExerciseFlow({
    super.key,
    required this.items,
    required this.onAnswer,
    required this.onFinished,
    this.onAppeal,
  });

  @override
  State<ExerciseFlow> createState() => _ExerciseFlowState();
}

class _ExerciseFlowState extends State<ExerciseFlow> {
  final _controller = TextEditingController();
  int _index = 0;
  int _score = 0;
  String? _given; // null while unanswered
  bool _overruled = false;
  bool _appealed = false;
  bool _appealing = false;
  String? _appealNote;
  bool _finished = false;

  Exercise get _item => widget.items[_index];

  bool get _correct =>
      _overruled || (_given != null && exerciseAnswerMatches(_item, _given!));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit(String answer) {
    if (_given != null || answer.trim().isEmpty) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _given = answer.trim());
  }

  Future<void> _next() async {
    final correct = _correct;
    await widget.onAnswer(_index, _given!, correct);
    if (!mounted) return;
    if (correct) _score++;
    _controller.clear();
    if (_index + 1 < widget.items.length) {
      setState(() {
        _index++;
        _given = null;
        _overruled = false;
        _appealed = false;
        _appealNote = null;
      });
    } else {
      setState(() => _finished = true);
      await widget.onFinished(_score, widget.items.length);
    }
  }

  Future<void> _appeal() async {
    final appeal = widget.onAppeal;
    if (appeal == null || _given == null) return;
    setState(() => _appealing = true);
    AppealOutcome outcome;
    try {
      outcome = await appeal(_item, _given!);
    } on LlmException catch (e) {
      outcome = AppealOutcome(accepted: false, note: e.messageRu);
    }
    if (!mounted) return;
    setState(() {
      _appealing = false;
      _appealed = true;
      _overruled = outcome.accepted;
      _appealNote = outcome.note;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final total = widget.items.length;

    if (_finished) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$_score из $total',
            style: AppTypography.display.copyWith(color: colors.ink),
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            _score == total
                ? 'Без ошибок.'
                : '${total - _score} ${pluralRu(total - _score, one: 'ответ', few: 'ответа', many: 'ответов')} с ошибкой — они сохранены в разборе.',
            style: AppTypography.caption.copyWith(color: colors.muted),
          ),
        ],
      );
    }

    final item = _item;
    final answered = _given != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${_index + 1} / $total',
          style: AppTypography.monoMeta.copyWith(color: colors.muted),
        ),
        const SizedBox(height: AppSpacing.s10),
        Text(
          item.prompt,
          style: AppTypography.heading.copyWith(color: colors.ink),
        ),
        const SizedBox(height: AppSpacing.s18),
        if (item.kind == ExerciseKind.choice)
          for (final option in item.options) ...[
            ChoiceTile(
              label: option,
              selected: _given == option,
              onTap: answered ? null : () => _submit(option),
            ),
            const SizedBox(height: AppSpacing.s8),
          ]
        else if (!answered) ...[
          DictationField(
            key: ValueKey('field$_index'),
            controller: _controller,
            onSubmitted: () => _submit(_controller.text),
          ),
          const SizedBox(height: AppSpacing.s14),
          PrimaryButton(
            label: 'Проверить',
            onPressed: () => _submit(_controller.text),
          ),
        ] else
          Text(
            _given!,
            style: AppTypography.monoWord.copyWith(
              fontSize: 18,
              color: colors.ink,
            ),
          ),
        if (answered) ...[
          const SizedBox(height: AppSpacing.s14),
          Text(
            _correct ? (_overruled ? 'Засчитано ИИ' : 'Верно') : 'Неверно',
            style: AppTypography.label.copyWith(
              color: _correct ? colors.success : colors.danger,
            ),
          ),
          if (!_correct) ...[
            const SizedBox(height: AppSpacing.s4),
            Text(
              item.answer,
              style: AppTypography.monoWord.copyWith(
                fontSize: 18,
                color: colors.ink,
              ),
            ),
          ],
          if (item.why.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s8),
            Text(
              item.why,
              style: AppTypography.bodyText.copyWith(color: colors.body),
            ),
          ],
          const SizedBox(height: AppSpacing.s18),
          if (_appealNote != null && _appealNote!.isNotEmpty) ...[
            Text(
              _appealNote!,
              style: AppTypography.caption.copyWith(color: colors.muted),
            ),
            const SizedBox(height: AppSpacing.s10),
          ],
          // A translation can be right in another wording; the AI, not the
          // learner, decides, and only once per answer.
          if (!_correct &&
              !_appealed &&
              item.kind == ExerciseKind.translate &&
              widget.onAppeal != null) ...[
            GhostButton(
              label: _appealing ? 'Проверяю…' : 'Мой ответ тоже верный?',
              onPressed: _appealing ? null : _appeal,
            ),
            const SizedBox(height: AppSpacing.s8),
          ],
          PrimaryButton(
            label: _index + 1 < total ? 'Дальше' : 'Завершить',
            trailingIcon: Icons.arrow_forward,
            onPressed: _next,
          ),
        ],
      ],
    );
  }
}

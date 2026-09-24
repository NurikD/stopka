import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/pack/pack_content.dart';
import '../../core/providers/core_providers.dart';
import '../../core/theme/app_theme_extension.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/tts/tts_service.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/segmented_choice.dart';
import 'exercise_flow.dart';
import 'pack_context.dart';

/// Speech rates for the two playback speeds. 1x matches a natural pace on the
/// device's engine; 0.75x is three quarters of it.
const double normalSpeechRate = 0.5;
const double slowSpeechRate = normalSpeechRate * 0.75;

class ListeningScreen extends StatelessWidget {
  final PackContext pack;

  const ListeningScreen({super.key, required this.pack});

  @override
  Widget build(BuildContext context) {
    return PackPartView(
      pack: pack,
      part: PackPart.listening,
      title: 'аудирование',
      builder: (context, payload) => _ListeningBody(
        pack: pack,
        content: ListeningContent.fromJson(payload, level: pack.key.level),
      ),
    );
  }
}

class _ListeningBody extends ConsumerStatefulWidget {
  final PackContext pack;
  final ListeningContent content;

  const _ListeningBody({required this.pack, required this.content});

  @override
  ConsumerState<_ListeningBody> createState() => _ListeningBodyState();
}

class _ListeningBodyState extends ConsumerState<_ListeningBody> {
  late final TtsService _tts;
  double _rate = normalSpeechRate;
  bool _playing = false;
  bool _answered = false; // the text opens only after the questions

  @override
  void initState() {
    super.initState();
    _tts = ref.read(ttsServiceProvider);
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_playing) {
      await _tts.stop();
      if (mounted) setState(() => _playing = false);
      return;
    }
    setState(() => _playing = true);
    try {
      await _tts.speakDialogue([
        for (final l in widget.content.lines)
          (speaker: l.speaker, text: l.text),
      ], speed: _rate);
    } finally {
      if (mounted) setState(() => _playing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final content = widget.content;
    final repo = ref.read(packRepositoryProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.s8,
        AppSpacing.screen,
        AppSpacing.s30,
      ),
      children: [
        Text(
          content.title,
          style: AppTypography.title.copyWith(color: colors.ink),
        ),
        const SizedBox(height: AppSpacing.s8),
        Text(
          'Послушайте диалог и ответьте на вопросы. Текст откроется после ответов.',
          style: AppTypography.caption.copyWith(color: colors.muted),
        ),
        const SizedBox(height: AppSpacing.s18),
        SegmentedChoice<double>(
          options: const [
            ChoiceOption(slowSpeechRate, '0.75×'),
            ChoiceOption(normalSpeechRate, '1×'),
          ],
          selected: _rate,
          onChanged: _playing ? (_) {} : (rate) => setState(() => _rate = rate),
        ),
        const SizedBox(height: AppSpacing.s10),
        PrimaryButton(
          label: _playing ? 'Стоп' : 'Слушать',
          trailingIcon: _playing ? Icons.stop : Icons.play_arrow,
          onPressed: _togglePlay,
        ),
        const SizedBox(height: AppSpacing.s30),
        Text(
          'Вопросы',
          style: AppTypography.heading.copyWith(color: colors.ink),
        ),
        const SizedBox(height: AppSpacing.s14),
        ExerciseFlow(
          items: [for (final q in content.questions) exerciseFromQuestion(q)],
          onAnswer: (i, answer, correct) => repo.logAttempt(
            widget.pack.packId,
            PackPart.listening,
            itemIndex: i,
            userAnswer: answer,
            isCorrect: correct,
          ),
          onFinished: (score, total) async {
            await repo.saveProgress(
              widget.pack.packId,
              PackPart.listening,
              score: score,
              total: total,
            );
            if (mounted) setState(() => _answered = true);
          },
        ),
        if (_answered) ...[
          const SizedBox(height: AppSpacing.s30),
          Text(
            'Текст',
            style: AppTypography.heading.copyWith(color: colors.ink),
          ),
          const SizedBox(height: AppSpacing.s14),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final line in content.lines)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.s10),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${line.name}  ',
                            style: AppTypography.monoMeta.copyWith(
                              color: colors.muted,
                            ),
                          ),
                          TextSpan(
                            text: line.text,
                            style: AppTypography.bodyText.copyWith(
                              color: colors.body,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.s30),
        BadMaterialButton(pack: widget.pack, part: PackPart.listening),
      ],
    );
  }
}

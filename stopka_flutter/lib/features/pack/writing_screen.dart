import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/llm/llm_exception.dart';
import '../../core/llm/writing_check_service.dart';
import '../../core/pack/pack_content.dart';
import '../../core/providers/core_providers.dart';
import '../../core/text/russian_plural.dart';
import '../../core/theme/app_theme_extension.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/primary_button.dart';
import '../../domain/models/unit_pack.dart';
import 'pack_context.dart';

class WritingScreen extends StatelessWidget {
  final PackContext pack;

  const WritingScreen({super.key, required this.pack});

  @override
  Widget build(BuildContext context) {
    return PackPartView(
      pack: pack,
      part: PackPart.writing,
      title: 'письмо',
      builder: (context, payload) =>
          _WritingBody(pack: pack, content: WritingContent.fromJson(payload)),
    );
  }
}

class _WritingBody extends ConsumerStatefulWidget {
  final PackContext pack;
  final WritingContent content;

  const _WritingBody({required this.pack, required this.content});

  @override
  ConsumerState<_WritingBody> createState() => _WritingBodyState();
}

class _WritingBodyState extends ConsumerState<_WritingBody> {
  final _controller = TextEditingController();
  bool _checking = false;
  String? _message;
  WritingFeedback? _feedback;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    if (!await ref.read(aiAvailabilityProvider).isAvailable()) {
      if (mounted) {
        setState(
          () => _message =
              'Проверка письма сейчас недоступна: нет связи с сервером. '
              'Ваш текст останется в поле.',
        );
      }
      return;
    }
    setState(() {
      _checking = true;
      _message = null;
    });
    final repo = ref.read(packRepositoryProvider);
    try {
      final text = _controller.text.trim();
      final feedback = await ref
          .read(writingCheckServiceProvider)
          .check(
            level: widget.pack.key.level,
            task: widget.content.task,
            text: text,
          );
      await repo.saveWritingAttempt(
        widget.pack.packId,
        userText: text,
        correctedText: feedback.corrected,
        nativeText: feedback.native,
        summary: feedback.summary,
      );
      await repo.addMistakes(widget.pack.packId, [
        for (final e in feedback.errors)
          MistakeInput(
            skill: 'writing',
            category: e.category,
            original: e.original,
            corrected: e.fixed,
            explanation: e.explanation,
          ),
      ]);
      await repo.saveProgress(
        widget.pack.packId,
        PackPart.writing,
        score: feedback.errors.isEmpty ? 1 : 0,
        total: 1,
      );
      if (!mounted) return;
      setState(() {
        _feedback = feedback;
        _checking = false;
      });
    } on LlmException catch (e) {
      if (!mounted) return;
      setState(() {
        _checking = false;
        _message = e.messageRu;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final content = widget.content;
    final feedback = _feedback;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.s8,
        AppSpacing.screen,
        AppSpacing.s30,
      ),
      children: [
        Text('Задание', style: AppTypography.title.copyWith(color: colors.ink)),
        const SizedBox(height: AppSpacing.s14),
        AppCard(
          child: Text(
            content.task,
            style: AppTypography.bodyText.copyWith(
              fontSize: 16,
              color: colors.body,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s14),
        for (final hint in content.hints)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s4),
            child: Text(
              hint,
              style: AppTypography.monoMeta.copyWith(color: colors.muted),
            ),
          ),
        const SizedBox(height: AppSpacing.s18),
        TextField(
          controller: _controller,
          enabled: feedback == null,
          minLines: 6,
          maxLines: 12,
          autocorrect: false,
          textCapitalization: TextCapitalization.sentences,
          style: AppTypography.monoWord.copyWith(
            fontSize: 15,
            color: colors.ink,
          ),
          decoration: const InputDecoration(hintText: 'Ваш текст по-английски'),
        ),
        if (_message != null) ...[
          const SizedBox(height: AppSpacing.s10),
          Text(
            _message!,
            style: AppTypography.bodyText.copyWith(color: colors.danger),
          ),
        ],
        if (feedback == null) ...[
          const SizedBox(height: AppSpacing.s14),
          PrimaryButton(
            label: 'Проверить',
            onPressed: _check,
            loading: _checking,
          ),
        ] else
          ..._buildFeedback(colors, feedback),
      ],
    );
  }

  List<Widget> _buildFeedback(AppColorTokens colors, WritingFeedback feedback) {
    final n = feedback.errors.length;
    return [
      const SizedBox(height: AppSpacing.s22),
      Text(
        n == 0
            ? 'Ошибок нет'
            : '$n ${pluralRu(n, one: 'ошибка', few: 'ошибки', many: 'ошибок')}',
        style: AppTypography.heading.copyWith(
          color: n == 0 ? colors.success : colors.ink,
        ),
      ),
      if (feedback.summary.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.s8),
        Text(
          feedback.summary,
          style: AppTypography.bodyText.copyWith(color: colors.body),
        ),
      ],
      const SizedBox(height: AppSpacing.s14),
      for (final e in feedback.errors) ...[
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                mistakeCategoryNamesRu[e.category] ?? 'Другое',
                style: AppTypography.monoMeta.copyWith(color: colors.muted),
              ),
              const SizedBox(height: AppSpacing.s8),
              Text(
                e.original,
                style: AppTypography.monoWord.copyWith(
                  fontSize: 15,
                  color: colors.danger,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              Text(
                e.fixed,
                style: AppTypography.monoWord.copyWith(
                  fontSize: 15,
                  color: colors.ink,
                ),
              ),
              if (e.explanation.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.s8),
                Text(
                  e.explanation,
                  style: AppTypography.bodyText.copyWith(color: colors.body),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s10),
      ],
      const SizedBox(height: AppSpacing.s8),
      Text(
        'Исправленный текст',
        style: AppTypography.label.copyWith(color: colors.muted),
      ),
      const SizedBox(height: AppSpacing.s8),
      Text(
        feedback.corrected,
        style: AppTypography.monoWord.copyWith(fontSize: 15, color: colors.ink),
      ),
      if (feedback.native.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.s18),
        Text(
          'Как сказал бы носитель',
          style: AppTypography.label.copyWith(color: colors.muted),
        ),
        const SizedBox(height: AppSpacing.s8),
        Text(
          feedback.native,
          style: AppTypography.monoWord.copyWith(
            fontSize: 15,
            color: colors.ink,
          ),
        ),
      ],
    ];
  }
}

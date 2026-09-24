import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/core_providers.dart';
import '../../core/theme/app_theme_extension.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/labeled_field.dart';
import '../../core/widgets/primary_button.dart';
import '../../domain/models/word_card.dart';

Future<void> showCardFormSheet(BuildContext context, WidgetRef ref, {required WordCard card}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => _CardFormSheet(card: card),
  );
}

class _CardFormSheet extends ConsumerStatefulWidget {
  final WordCard card;

  const _CardFormSheet({required this.card});

  @override
  ConsumerState<_CardFormSheet> createState() => _CardFormSheetState();
}

class _CardFormSheetState extends ConsumerState<_CardFormSheet> {
  late final _termController = TextEditingController(text: widget.card.term);
  late final _translationController = TextEditingController(text: widget.card.translation);
  late final _transcriptionController = TextEditingController(text: widget.card.transcription);
  late final _partOfSpeechController = TextEditingController(text: widget.card.partOfSpeech);
  bool _saving = false;

  @override
  void dispose() {
    _termController.dispose();
    _translationController.dispose();
    _transcriptionController.dispose();
    _partOfSpeechController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final term = _termController.text.trim();
    if (term.isEmpty) return;
    setState(() => _saving = true);
    await ref.read(wordCardRepositoryProvider).updateCard(
          widget.card.copyWith(
            term: term,
            translation: _translationController.text.trim(),
            transcription: _transcriptionController.text.trim(),
            partOfSpeech: _partOfSpeechController.text.trim(),
          ),
        );
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final mono = AppTypography.monoWord.copyWith(fontSize: 15, color: colors.ink);
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.s22,
        AppSpacing.screen,
        AppSpacing.s22 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Редактировать слово', style: AppTypography.heading.copyWith(color: colors.ink)),
          const SizedBox(height: AppSpacing.s18),
          LabeledField(label: 'Слово', child: TextField(controller: _termController, style: mono)),
          const SizedBox(height: AppSpacing.s14),
          LabeledField(label: 'Перевод', child: TextField(controller: _translationController)),
          const SizedBox(height: AppSpacing.s14),
          LabeledField(
            label: 'Транскрипция',
            child: TextField(
              controller: _transcriptionController,
              style: AppTypography.transcription.copyWith(fontSize: 15, color: colors.ink),
            ),
          ),
          const SizedBox(height: AppSpacing.s14),
          LabeledField(label: 'Часть речи', child: TextField(controller: _partOfSpeechController)),
          const SizedBox(height: AppSpacing.s22),
          PrimaryButton(label: 'Сохранить', onPressed: _save, loading: _saving),
        ],
      ),
    );
  }
}

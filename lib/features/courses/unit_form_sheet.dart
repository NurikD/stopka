import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/core_providers.dart';
import '../../core/theme/app_theme_extension.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/labeled_field.dart';
import '../../core/widgets/primary_button.dart';

/// Unit creation: code, title, and free-text grammar/vocab topics the user
/// writes in their own words — the app doesn't know the textbook, they do.
Future<void> showUnitFormSheet(BuildContext context, WidgetRef ref, {required String courseId}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => _UnitFormSheet(courseId: courseId),
  );
}

class _UnitFormSheet extends ConsumerStatefulWidget {
  final String courseId;

  const _UnitFormSheet({required this.courseId});

  @override
  ConsumerState<_UnitFormSheet> createState() => _UnitFormSheetState();
}

class _UnitFormSheetState extends ConsumerState<_UnitFormSheet> {
  final _codeController = TextEditingController();
  final _titleController = TextEditingController();
  final _grammarController = TextEditingController();
  final _vocabController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _codeController.dispose();
    _titleController.dispose();
    _grammarController.dispose();
    _vocabController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;
    setState(() => _saving = true);
    await ref.read(unitRepositoryProvider).createUnit(
          courseId: widget.courseId,
          code: code,
          title: _titleController.text.trim(),
          grammarTopic: _grammarController.text.trim(),
          vocabTopic: _vocabController.text.trim(),
        );
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
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
          Text('Новый юнит', style: AppTypography.heading.copyWith(color: colors.ink)),
          const SizedBox(height: AppSpacing.s18),
          LabeledField(
            label: 'Код',
            child: TextField(
              controller: _codeController,
              autofocus: true,
              style: AppTypography.monoWord.copyWith(fontSize: 15, color: colors.ink),
              decoration: const InputDecoration(hintText: '4B'),
            ),
          ),
          const SizedBox(height: AppSpacing.s14),
          LabeledField(
            label: 'Название (необязательно)',
            child: TextField(controller: _titleController),
          ),
          const SizedBox(height: AppSpacing.s14),
          LabeledField(
            label: 'Грамматика',
            child: TextField(
              controller: _grammarController,
              decoration: const InputDecoration(hintText: 'Present perfect'),
            ),
          ),
          const SizedBox(height: AppSpacing.s14),
          LabeledField(
            label: 'Лексика',
            child: TextField(
              controller: _vocabController,
              decoration: const InputDecoration(hintText: 'Путешествия'),
            ),
          ),
          const SizedBox(height: AppSpacing.s22),
          PrimaryButton(label: 'Создать юнит', onPressed: _save, loading: _saving),
        ],
      ),
    );
  }
}

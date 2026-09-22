import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/core_providers.dart';
import '../../core/theme/tokens.dart';
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
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Новый юнит', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _codeController,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Код (например, 4B)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Название (необязательно)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _grammarController,
            decoration: const InputDecoration(labelText: 'Грамматика', border: OutlineInputBorder()),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _vocabController,
            decoration: const InputDecoration(labelText: 'Лексика', border: OutlineInputBorder()),
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(label: 'Создать юнит', onPressed: _save, loading: _saving),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/core_providers.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/primary_button.dart';
import '../../domain/models/course.dart';

/// 30-second course creation: title, level, publisher. See PLAN.md — the
/// app has no bundled book content, so this is the only setup a course needs.
Future<void> showCourseFormSheet(BuildContext context, WidgetRef ref) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _CourseFormSheet(),
  );
}

class _CourseFormSheet extends ConsumerStatefulWidget {
  const _CourseFormSheet();

  @override
  ConsumerState<_CourseFormSheet> createState() => _CourseFormSheetState();
}

class _CourseFormSheetState extends ConsumerState<_CourseFormSheet> {
  final _titleController = TextEditingController();
  final _publisherController = TextEditingController();
  String _level = cefrLevels[1];
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _publisherController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    setState(() => _saving = true);
    await ref.read(courseRepositoryProvider).createCourse(
          title: title,
          level: _level,
          publisher: _publisherController.text.trim(),
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
          Text('Новый курс', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _titleController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Название',
              hintText: 'English File Pre-Intermediate, школа X',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: _level,
            decoration: const InputDecoration(labelText: 'Уровень', border: OutlineInputBorder()),
            items: cefrLevels.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
            onChanged: (v) {
              if (v != null) setState(() => _level = v);
            },
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _publisherController,
            decoration: const InputDecoration(
              labelText: 'Издательство / заметка (необязательно)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(label: 'Создать курс', onPressed: _save, loading: _saving),
        ],
      ),
    );
  }
}

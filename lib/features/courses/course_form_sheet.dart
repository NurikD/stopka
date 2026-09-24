import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/core_providers.dart';
import '../../core/theme/app_theme_extension.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/labeled_field.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/segmented_choice.dart';
import '../../domain/models/course.dart';

/// 30-second course creation: title, level, publisher. There is no bundled
/// book content, so this is the only setup a course needs.
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
          Text('Новый курс', style: AppTypography.heading.copyWith(color: colors.ink)),
          const SizedBox(height: AppSpacing.s18),
          LabeledField(
            label: 'Название',
            child: TextField(
              controller: _titleController,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'English File Pre-Intermediate, школа X'),
            ),
          ),
          const SizedBox(height: AppSpacing.s14),
          LabeledField(
            label: 'Уровень',
            child: SegmentedChoice<String>(
              options: [for (final l in cefrLevels) ChoiceOption(l, l)],
              selected: _level,
              onChanged: (v) => setState(() => _level = v),
            ),
          ),
          const SizedBox(height: AppSpacing.s14),
          LabeledField(
            label: 'Издательство или заметка (необязательно)',
            child: TextField(controller: _publisherController),
          ),
          const SizedBox(height: AppSpacing.s22),
          PrimaryButton(label: 'Создать курс', onPressed: _save, loading: _saving),
        ],
      ),
    );
  }
}

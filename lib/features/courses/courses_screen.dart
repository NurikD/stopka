import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/core_providers.dart';
import '../../core/theme/app_theme_extension.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/unit_chip.dart';
import '../../domain/models/course.dart';
import 'course_form_sheet.dart';

class CoursesScreen extends ConsumerWidget {
  const CoursesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Курсы'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Создать курс',
            onPressed: () => showCourseFormSheet(context, ref),
          ),
        ],
      ),
      body: StreamBuilder<List<Course>>(
        stream: ref.watch(courseRepositoryProvider).watchCourses(),
        builder: (context, snapshot) {
          final courses = snapshot.data ?? const [];
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (courses.isEmpty) {
            return EmptyState(
              message: 'Создайте первый курс — название книги, уровень, и можно заносить слова.',
              actionLabel: 'Создать курс',
              onAction: () => showCourseFormSheet(context, ref),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.s14),
            itemCount: courses.length,
            itemBuilder: (context, i) => _CourseTile(course: courses[i]),
          );
        },
      ),
    );
  }
}

class _CourseTile extends StatelessWidget {
  final Course course;

  const _CourseTile({required this.course});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s10),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: () => context.go('/courses/${course.id}'),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.s14),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(course.title, style: AppTypography.heading.copyWith(color: colors.ink)),
                    if (course.publisher.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.s4),
                      Text(
                        course.publisher,
                        style: AppTypography.caption.copyWith(color: colors.muted),
                      ),
                    ],
                  ],
                ),
              ),
              UnitChip(label: course.level),
            ],
          ),
        ),
      ),
    );
  }
}

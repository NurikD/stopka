import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/core_providers.dart';
import '../../core/theme/app_theme_extension.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_header_bar.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/unit_chip.dart';
import '../../domain/models/course.dart';
import 'course_form_sheet.dart';

class CoursesScreen extends ConsumerWidget {
  const CoursesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return Scaffold(
      appBar: const AppHeaderBar(),
      body: StreamBuilder<List<Course>>(
        stream: ref.watch(courseRepositoryProvider).watchCourses(),
        builder: (context, snapshot) {
          final courses = snapshot.data ?? const [];
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (courses.isEmpty) {
            return EmptyState(
              message: 'Создайте первый курс — название книги и уровень, и можно заносить слова.',
              actionLabel: 'Создать курс',
              onAction: () => showCourseFormSheet(context, ref),
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.s8, AppSpacing.screen, AppSpacing.s22),
            children: [
              Text('Словарь', style: AppTypography.title.copyWith(color: colors.ink)),
              const SizedBox(height: AppSpacing.s22),
              for (final course in courses)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.s10),
                  child: _CourseTile(course: course),
                ),
              AppCard(
                dashed: true,
                onTap: () => showCourseFormSheet(context, ref),
                child: Center(
                  child: Text('Добавить курс', style: AppTypography.label.copyWith(color: colors.muted)),
                ),
              ),
            ],
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
    return AppCard(
      // push (not go): detail screens have no bottom nav, so they need a
      // route stack to go back through.
      onTap: () => context.push('/courses/${course.id}'),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(course.title, style: AppTypography.heading.copyWith(color: colors.ink)),
                if (course.publisher.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.s4),
                  Text(course.publisher, style: AppTypography.caption.copyWith(color: colors.muted)),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s10),
          UnitChip(label: course.level),
        ],
      ),
    );
  }
}

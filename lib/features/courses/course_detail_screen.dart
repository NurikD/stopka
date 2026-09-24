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
import '../../domain/models/unit.dart';
import 'unit_form_sheet.dart';

class CourseDetailScreen extends ConsumerWidget {
  final String courseId;

  const CourseDetailScreen({super.key, required this.courseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return FutureBuilder(
      future: ref.watch(courseRepositoryProvider).getCourse(courseId),
      builder: (context, courseSnapshot) {
        final title = courseSnapshot.data?.title ?? 'Курс';
        return Scaffold(
          appBar: AppHeaderBar(nested: true, title: title),
          body: StreamBuilder<List<Unit>>(
            stream: ref.watch(unitRepositoryProvider).watchUnits(courseId),
            builder: (context, snapshot) {
              final units = snapshot.data ?? const [];
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (units.isEmpty) {
                return EmptyState(
                  message: 'Добавьте первый юнит — код и темы грамматики и лексики своими словами.',
                  actionLabel: 'Добавить юнит',
                  onAction: () => showUnitFormSheet(context, ref, courseId: courseId),
                );
              }
              return ListView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.s8, AppSpacing.screen, AppSpacing.s22),
                children: [
                  Text('Юниты', style: AppTypography.title.copyWith(color: colors.ink)),
                  const SizedBox(height: AppSpacing.s22),
                  for (final unit in units)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.s10),
                      child: _UnitTile(courseId: courseId, unit: unit),
                    ),
                  AppCard(
                    dashed: true,
                    onTap: () => showUnitFormSheet(context, ref, courseId: courseId),
                    child: Center(
                      child: Text('Добавить юнит', style: AppTypography.label.copyWith(color: colors.muted)),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _UnitTile extends StatelessWidget {
  final String courseId;
  final Unit unit;

  const _UnitTile({required this.courseId, required this.unit});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final topics = [unit.grammarTopic, unit.vocabTopic].where((s) => s.isNotEmpty).join(' · ');
    return AppCard(
      onTap: () => context.push('/courses/$courseId/units/${unit.id}'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UnitChip(label: unit.code),
          const SizedBox(width: AppSpacing.s14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (unit.title.isNotEmpty)
                  Text(unit.title, style: AppTypography.heading.copyWith(color: colors.ink)),
                if (topics.isNotEmpty)
                  Text(topics, style: AppTypography.caption.copyWith(color: colors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

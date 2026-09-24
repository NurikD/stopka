import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/core_providers.dart';
import '../../core/theme/app_theme_extension.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/unit_chip.dart';
import '../../domain/models/unit.dart';
import 'unit_form_sheet.dart';

class CourseDetailScreen extends ConsumerWidget {
  final String courseId;

  const CourseDetailScreen({super.key, required this.courseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder(
          future: ref.watch(courseRepositoryProvider).getCourse(courseId),
          builder: (context, snapshot) => Text(snapshot.data?.title ?? 'Курс'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Добавить юнит',
            onPressed: () => showUnitFormSheet(context, ref, courseId: courseId),
          ),
        ],
      ),
      body: StreamBuilder<List<Unit>>(
        stream: ref.watch(unitRepositoryProvider).watchUnits(courseId),
        builder: (context, snapshot) {
          final units = snapshot.data ?? const [];
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (units.isEmpty) {
            return EmptyState(
              message: 'Добавьте первый юнит — код и темы грамматики/лексики своими словами.',
              actionLabel: 'Добавить юнит',
              onAction: () => showUnitFormSheet(context, ref, courseId: courseId),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.s14),
            itemCount: units.length,
            itemBuilder: (context, i) => _UnitTile(courseId: courseId, unit: units[i]),
          );
        },
      ),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s10),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: () => context.go('/courses/$courseId/units/${unit.id}'),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.s14),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Row(
            children: [
              UnitChip(label: unit.code),
              const SizedBox(width: AppSpacing.s10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (unit.title.isNotEmpty)
                      Text(unit.title, style: AppTypography.heading.copyWith(color: colors.ink)),
                    if (unit.grammarTopic.isNotEmpty || unit.vocabTopic.isNotEmpty)
                      Text(
                        [unit.grammarTopic, unit.vocabTopic].where((s) => s.isNotEmpty).join(' · '),
                        style: AppTypography.caption.copyWith(color: colors.muted),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

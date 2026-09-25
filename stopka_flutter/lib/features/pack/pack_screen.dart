import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/pack/pack_content.dart';
import '../../core/pack/pack_service.dart';
import '../../core/providers/core_providers.dart';
import '../../core/theme/app_theme_extension.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_header_bar.dart';
import '../../domain/models/unit_pack.dart';
import 'grammar_screen.dart';
import 'listening_screen.dart';
import 'pack_context.dart';
import 'reading_screen.dart';
import 'writing_screen.dart';

const Map<PackPart, String> _titles = {
  PackPart.reading: 'Чтение',
  PackPart.listening: 'Аудирование',
  PackPart.grammar: 'Грамматика',
  PackPart.writing: 'Письмо',
};

/// Compact entry in the unit screen: how many parts are ready, and a way in.
class PackEntryCard extends ConsumerWidget {
  final String unitId;

  const PackEntryCard({super.key, required this.unitId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final packContext = ref.watch(packContextProvider(unitId)).value;
    final pack = packContext == null
        ? null
        : ref.watch(packProvider(packContext.packId)).value;
    final ready = pack == null
        ? 0
        : PackPart.values
              .where((p) => pack.statusOf(p) == PartStatus.ready)
              .length;

    return AppCard(
      onTap: packContext == null
          ? null
          : () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => PackScreen(pack: packContext)),
            ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Комплект юнита',
                  style: AppTypography.heading.copyWith(color: colors.ink),
                ),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  'Чтение, аудирование, грамматика, письмо · готово $ready из 4',
                  style: AppTypography.caption.copyWith(color: colors.muted),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: colors.muted),
        ],
      ),
    );
  }
}

/// The four parts of a unit pack with their state.
class PackScreen extends ConsumerWidget {
  final PackContext pack;

  const PackScreen({super.key, required this.pack});

  Widget _screenFor(PackPart part) => switch (part) {
    PackPart.reading => ReadingScreen(pack: pack),
    PackPart.listening => ListeningScreen(pack: pack),
    PackPart.grammar => GrammarScreen(pack: pack),
    PackPart.writing => WritingScreen(pack: pack),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final service = ref.watch(packServiceProvider);
    final data = ref.watch(packProvider(pack.packId)).value;
    final progress =
        ref.watch(packProgressProvider(pack.packId)).value ?? const {};
    final hasKey = ref.watch(hasApiKeyProvider).value ?? false;

    return Scaffold(
      appBar: const AppHeaderBar(nested: true, title: 'комплект'),
      body: ValueListenableBuilder<Set<String>>(
        valueListenable: service.generating,
        builder: (context, running, _) => ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.s8,
            AppSpacing.screen,
            AppSpacing.s22,
          ),
          children: [
            if (!hasKey &&
                (data == null ||
                    PackPart.values.any(
                      (p) => data.statusOf(p) != PartStatus.ready,
                    ))) ...[
              Text(
                'Чтобы подготовить материал, нужна связь с сервером. '
                'Уже подготовленное открывается без связи.',
                style: AppTypography.caption.copyWith(color: colors.muted),
              ),
              const SizedBox(height: AppSpacing.s14),
            ],
            for (final part in PackPart.values) ...[
              _PartRow(
                title: _titles[part]!,
                status: _statusText(
                  part,
                  data,
                  progress[part],
                  running,
                  service,
                  hasKey,
                ),
                onTap: () => _open(context, ref, part, data),
              ),
              const SizedBox(height: AppSpacing.s10),
            ],
          ],
        ),
      ),
    );
  }

  String _statusText(
    PackPart part,
    UnitPack? data,
    PackProgress? progress,
    Set<String> running,
    PackService service,
    bool hasKey,
  ) {
    final slot = PackService.slot(pack.packId, part);
    if (running.contains(slot)) return 'Готовится…';
    final status = data?.statusOf(part) ?? PartStatus.pending;
    switch (status) {
      case PartStatus.ready:
        if (progress == null) return 'Готово';
        return part == PackPart.writing
            ? 'Пройдено'
            : 'Пройдено · ${progress.score} из ${progress.total}';
      case PartStatus.failed:
      case PartStatus.flagged:
        return '${service.lastError[slot] ?? 'Не получилось подготовить.'} Нажмите, чтобы повторить.';
      case PartStatus.pending:
        return hasKey
            ? 'В очереди · нажмите, чтобы подготовить сейчас'
            : 'Нет связи с сервером';
    }
  }

  void _open(
    BuildContext context,
    WidgetRef ref,
    PackPart part,
    UnitPack? data,
  ) {
    if (data?.statusOf(part) == PartStatus.ready) {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => _screenFor(part)));
      return;
    }
    ref.read(packServiceProvider).generatePart(pack.packId, pack.key, part);
  }
}

class _PartRow extends StatelessWidget {
  final String title;
  final String status;
  final VoidCallback onTap;

  const _PartRow({
    required this.title,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.heading.copyWith(color: colors.ink)),
          const SizedBox(height: AppSpacing.s4),
          Text(
            status,
            style: AppTypography.caption.copyWith(color: colors.muted),
          ),
        ],
      ),
    );
  }
}

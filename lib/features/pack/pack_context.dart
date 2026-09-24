import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/pack/content_source.dart';
import '../../core/pack/pack_content.dart';
import '../../core/pack/pack_key.dart';
import '../../core/pack/pack_service.dart';
import '../../core/providers/core_providers.dart';
import '../../core/theme/app_theme_extension.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/app_header_bar.dart';
import '../../core/widgets/ghost_button.dart';
import '../../domain/models/unit_pack.dart';

/// Which pack a unit uses. Opening it also starts preparing the missing parts
/// in the background (nothing happens without a key).
class PackContext {
  final String packId;
  final PackKey key;
  final String unitId;

  const PackContext({
    required this.packId,
    required this.key,
    required this.unitId,
  });
}

final packContextProvider = FutureProvider.autoDispose
    .family<PackContext, String>((ref, unitId) async {
      final unit = await ref.watch(unitRepositoryProvider).getUnit(unitId);
      if (unit == null) throw StateError('unit $unitId not found');
      final course = await ref
          .watch(courseRepositoryProvider)
          .getCourse(unit.courseId);
      final profile = ref.watch(currentProfileProvider).value;
      final key = packKeyFor(
        unit: unit,
        profile: profile,
        courseLevel: course?.level ?? '',
      );

      final service = ref.watch(packServiceProvider);
      final pack = await service.open(key);
      // Fire and forget: what finishes is picked up through watchPack.
      service.generateMissing(pack.id, key);
      return PackContext(packId: pack.id, key: key, unitId: unitId);
    });

final packProvider = StreamProvider.autoDispose.family<UnitPack?, String>((
  ref,
  packId,
) {
  return ref.watch(packRepositoryProvider).watchPack(packId);
});

final packProgressProvider = StreamProvider.autoDispose
    .family<Map<PackPart, PackProgress>, String>((ref, packId) {
      return ref.watch(packRepositoryProvider).watchProgress(packId);
    });

/// Shell of one part's screen: shows its content when it is ready, and an
/// honest state (preparing / needs a key / failed with retry) otherwise.
class PackPartView extends ConsumerWidget {
  final PackContext pack;
  final PackPart part;
  final String title;
  final Widget Function(BuildContext context, Map<String, dynamic> payload)
  builder;

  const PackPartView({
    super.key,
    required this.pack,
    required this.part,
    required this.title,
    required this.builder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final service = ref.watch(packServiceProvider);
    final data = ref.watch(packProvider(pack.packId)).value;
    final payload = data?.payloadOf(part);

    if (payload != null) {
      return Scaffold(
        appBar: AppHeaderBar(nested: true, title: title),
        // A fresh state for every version of the content.
        body: KeyedSubtree(
          key: ValueKey(payload.toString().hashCode),
          child: builder(context, payload),
        ),
      );
    }

    return Scaffold(
      appBar: AppHeaderBar(nested: true, title: title),
      body: ValueListenableBuilder<Set<String>>(
        valueListenable: service.generating,
        builder: (context, running, _) {
          final busy = running.contains(PackService.slot(pack.packId, part));
          final error = service.lastError[PackService.slot(pack.packId, part)];
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.screen),
              child: busy
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: AppSpacing.s14),
                        Text(
                          'Готовлю ${partNamesRu[part]}…',
                          style: TextStyle(color: colors.muted),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          error ?? 'Этот материал ещё не готов.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: colors.muted),
                        ),
                        const SizedBox(height: AppSpacing.s14),
                        GhostButton(
                          label: 'Подготовить',
                          onPressed: () => ref
                              .read(packServiceProvider)
                              .generatePart(pack.packId, pack.key, part),
                        ),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }
}

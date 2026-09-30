import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/core_providers.dart';
import '../../core/theme/app_theme_extension.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/update/app_release.dart';
import '../../core/update/update_service.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_header_bar.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/sticky_action_bar.dart';

/// "Доступна версия 0.2.0" on the main screen; opens [UpdateScreen].
class UpdateCard extends ConsumerWidget {
  final AppRelease release;

  const UpdateCard({super.key, required this.release});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return AppCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => UpdateScreen(release: release)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Доступна версия ${release.version}',
                  style: AppTypography.label.copyWith(color: colors.ink),
                ),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  'Обновить — прогресс сохранится',
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

enum _Stage { idle, downloading, needsPermission, installing, failed }

/// What is new, then download and hand the APK to the system installer.
class UpdateScreen extends ConsumerStatefulWidget {
  final AppRelease release;

  const UpdateScreen({super.key, required this.release});

  @override
  ConsumerState<UpdateScreen> createState() => _UpdateScreenState();
}

class _UpdateScreenState extends ConsumerState<UpdateScreen> {
  _Stage _stage = _Stage.idle;
  double _progress = 0;
  String? _apkPath; // kept, so a second tap does not download again

  Future<void> _update() async {
    final service = ref.read(updateServiceProvider);
    try {
      var path = _apkPath;
      if (path == null) {
        setState(() {
          _stage = _Stage.downloading;
          _progress = 0;
        });
        path = await service.download(widget.release, (p) {
          if (mounted) setState(() => _progress = p);
        });
        _apkPath = path;
      }
      if (!mounted) return;
      setState(() => _stage = _Stage.installing);
      final start = await service.install(path);
      if (!mounted) return;
      setState(() => _stage = start == InstallStart.needsPermission ? _Stage.needsPermission : _Stage.idle);
    } on Exception {
      if (mounted) setState(() => _stage = _Stage.failed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final release = widget.release;
    final size = release.apkSize > 0 ? ' · ${(release.apkSize / 1024 / 1024).toStringAsFixed(1)} МБ' : '';
    final notes = plainNotes(release.notes);
    final busy = _stage == _Stage.downloading || _stage == _Stage.installing;

    final status = switch (_stage) {
      _Stage.needsPermission =>
        'Разрешите Стопке устанавливать приложения в открывшихся настройках, вернитесь и нажмите «Установить».',
      _Stage.failed => 'Не удалось скачать или установить обновление. Проверьте интернет и попробуйте ещё раз.',
      _ => null,
    };

    return Scaffold(
      appBar: const AppHeaderBar(nested: true, title: 'обновление'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.s8, AppSpacing.screen, AppSpacing.s22),
        children: [
          Text('Версия ${release.version}', style: AppTypography.title.copyWith(color: colors.ink)),
          const SizedBox(height: AppSpacing.s4),
          Text(
            '${release.apkName}$size',
            style: AppTypography.monoMeta.copyWith(color: colors.muted),
          ),
          const SizedBox(height: AppSpacing.s22),
          if (notes.isNotEmpty)
            AppCard(
              child: Text(notes, style: AppTypography.bodyText.copyWith(color: colors.body)),
            ),
          const SizedBox(height: AppSpacing.s14),
          Text(
            'Слова, повторение и настройки останутся: обновление ставится поверх.',
            style: AppTypography.caption.copyWith(color: colors.muted),
          ),
          if (_stage == _Stage.downloading) ...[
            const SizedBox(height: AppSpacing.s22),
            // Straight 3px track, like every progress bar in the app.
            LinearProgressIndicator(
              value: _progress,
              minHeight: 3,
              color: colors.accent,
              backgroundColor: colors.line,
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(
              'скачано ${(_progress * 100).round()}%',
              style: AppTypography.monoMeta.copyWith(color: colors.muted),
            ),
          ],
          if (status != null) ...[
            const SizedBox(height: AppSpacing.s22),
            Text(status, style: AppTypography.bodyText.copyWith(color: colors.ink)),
          ],
        ],
      ),
      bottomNavigationBar: StickyActionBar(
        children: [
          PrimaryButton(
            label: _apkPath == null ? 'Скачать и установить' : 'Установить',
            loading: busy,
            onPressed: busy ? null : _update,
          ),
        ],
      ),
    );
  }
}

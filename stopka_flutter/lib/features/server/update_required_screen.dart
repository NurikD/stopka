import 'package:flutter/material.dart';

import '../../core/theme/app_theme_extension.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/app_card.dart';

/// Shown instead of the app when the server no longer supports this version.
/// Nothing is lost: the data stays on the phone.
class UpdateRequiredScreen extends StatelessWidget {
  final String? minVersion;

  const UpdateRequiredScreen({super.key, this.minVersion});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.screen),
            child: AppCard(
              dashed: true,
              padding: const EdgeInsets.all(AppSpacing.s22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Нужно обновить приложение', textAlign: TextAlign.center, style: AppTypography.heading.copyWith(color: colors.ink)),
                  const SizedBox(height: AppSpacing.s10),
                  Text(
                    'Эта версия больше не работает с сервером'
                    '${minVersion == null ? '' : ' (нужна $minVersion или новее)'}. '
                    'Ваши слова и прогресс на телефоне сохранены.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyText.copyWith(color: colors.muted),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../core/theme/app_theme_extension.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/app_header_bar.dart';
import '../../core/widgets/empty_state.dart';

class PracticeScreen extends StatelessWidget {
  const PracticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeaderBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.s8, AppSpacing.screen, 0),
            child: Text('Практика', style: AppTypography.title.copyWith(color: context.colors.ink)),
          ),
          const Expanded(
            child: EmptyState(
              message: 'Диктант и практика в предложениях появятся здесь в следующих фазах.',
            ),
          ),
        ],
      ),
    );
  }
}

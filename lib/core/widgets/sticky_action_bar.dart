import 'package:flutter/material.dart';

import '../theme/app_theme_extension.dart';
import '../theme/tokens.dart';

/// The bottom action row. In the canvas artboards it floats on the screen
/// background with no divider and no shadow.
///
/// [flexes] sets each button's share of the row (default: equal); the
/// dictation screen uses 3:5 so "Проверить" outweighs "Не знаю".
class StickyActionBar extends StatelessWidget {
  final List<Widget> children;
  final List<int>? flexes;

  const StickyActionBar({super.key, required this.children, this.flexes});

  @override
  Widget build(BuildContext context) {
    assert(flexes == null || flexes!.length == children.length);
    final colors = context.colors;
    return ColoredBox(
      color: colors.bg,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.s10,
          AppSpacing.screen,
          AppSpacing.s22 + MediaQuery.of(context).padding.bottom,
        ),
        child: Row(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.s10),
              Expanded(flex: flexes?[i] ?? 1, child: children[i]),
            ],
          ],
        ),
      ),
    );
  }
}

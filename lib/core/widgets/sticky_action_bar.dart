import 'package:flutter/material.dart';

import '../theme/app_theme_extension.dart';
import '../theme/tokens.dart';

/// The bottom action bar. DESIGN_v2 has no shadows anywhere, so it is
/// separated from the content by a 1px `line` border on top.
class StickyActionBar extends StatelessWidget {
  final List<Widget> children;

  const StickyActionBar({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.s14,
        AppSpacing.screen,
        AppSpacing.s14 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: colors.bg,
        border: Border(top: BorderSide(color: colors.line)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.s10),
            Expanded(child: children[i]),
          ],
        ],
      ),
    );
  }
}

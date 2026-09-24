import 'package:flutter/material.dart';

import '../theme/app_theme_extension.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';

class AppBottomNavItem {
  final IconData icon;
  final String label;

  const AppBottomNavItem({required this.icon, required this.label});
}

/// Bottom navigation without the Material pill/fill under the active item:
/// the active one is drawn in `accent`, the rest `muted`, on a 1px `line`
/// top border (per the canvas artboards).
class AppBottomNav extends StatelessWidget {
  final List<AppBottomNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onSelected;

  const AppBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: colors.bg,
        border: Border(top: BorderSide(color: colors.line)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++)
            Expanded(
              child: InkWell(
                onTap: () => onSelected(i),
                child: SizedBox(
                  height: 60,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(items[i].icon, size: 22, color: i == currentIndex ? colors.accent : colors.muted),
                      const SizedBox(height: AppSpacing.s4),
                      Text(
                        items[i].label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(
                          fontSize: 12,
                          fontWeight: i == currentIndex ? FontWeight.w600 : FontWeight.w400,
                          color: i == currentIndex ? colors.accent : colors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

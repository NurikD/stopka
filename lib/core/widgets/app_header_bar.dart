import 'package:flutter/material.dart';

import '../theme/app_theme_extension.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';

/// The screen header. Top-level screens: the logo (two offset squares) and
/// `stopka` in mono on the left, service text on the right. Nested screens:
/// a back or close button (38×38 visible, 44×44 tappable) instead of the
/// logo, optionally followed by a title.
class AppHeaderBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final String? meta;
  final bool nested;
  final IconData navIcon;
  final VoidCallback? onNavigate;

  const AppHeaderBar({
    super.key,
    this.title,
    this.meta,
    this.nested = false,
    this.navIcon = Icons.arrow_back,
    this.onNavigate,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: 56,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s14),
          child: Row(
            children: [
              if (nested)
                _NavButton(icon: navIcon, onTap: onNavigate ?? () => Navigator.of(context).maybePop())
              else ...[
                const SizedBox(width: AppSpacing.s8),
                const _Logo(),
                const SizedBox(width: AppSpacing.s10),
                Text('stopka', style: AppTypography.monoWord.copyWith(fontSize: 15, color: colors.ink)),
              ],
              if (nested && title != null) ...[
                const SizedBox(width: AppSpacing.s8),
                Expanded(
                  child: Text(
                    title!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.label.copyWith(color: colors.ink),
                  ),
                ),
              ] else
                const Spacer(),
              if (meta != null)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.s8),
                  child: Text(meta!, style: AppTypography.monoMeta.copyWith(color: colors.muted)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _NavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.iconButton),
      onTap: onTap,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.iconButton),
              border: Border.all(color: colors.line),
            ),
            child: Icon(icon, size: 20, color: colors.ink),
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      width: 20,
      height: 20,
      child: Stack(
        children: [
          Container(
            width: 13,
            height: 13,
            decoration: BoxDecoration(border: Border.all(color: colors.ink, width: 1.6)),
          ),
          Positioned(right: 0, bottom: 0, child: Container(width: 13, height: 13, color: colors.accent)),
        ],
      ),
    );
  }
}

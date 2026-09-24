import 'package:flutter/material.dart';

import '../theme/app_theme_extension.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';

/// The screen header, per the canvas artboards.
///
/// Top-level: the logo (two outlined squares) and `stopka` in mono on the
/// left, service text on the right.
/// Nested: a plain back/close icon on the left (44×44 tap area, no frame)
/// and the screen's label centred in `monoMeta`, e.g. "раунд 2 · 07/12".
class AppHeaderBar extends StatelessWidget implements PreferredSizeWidget {
  /// Centre label of a nested header.
  final String? title;

  /// Top-level: right-hand service text.
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
    final metaStyle = AppTypography.monoMeta.copyWith(color: colors.muted);

    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: 56,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s10),
          child: nested
              ? Row(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.iconButton),
                      onTap: onNavigate ?? () => Navigator.of(context).maybePop(),
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: Icon(navIcon, size: 22, color: colors.ink),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        title ?? '',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: metaStyle,
                      ),
                    ),
                    // Balances the icon so the label is truly centred; a
                    // right-hand action would go here.
                    const SizedBox(width: 44),
                  ],
                )
              : Row(
                  children: [
                    const SizedBox(width: AppSpacing.s10),
                    const _Logo(),
                    const SizedBox(width: AppSpacing.s10),
                    Text('stopka', style: AppTypography.monoWord.copyWith(fontSize: 15, color: colors.ink)),
                    const Spacer(),
                    if (meta != null)
                      Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.s10),
                        child: Text(meta!, style: metaStyle.copyWith(fontWeight: FontWeight.w600)),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Two outlined squares, the back one offset up and to the right and faint.
class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    Widget square(Color border, double width) => Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: colors.bg,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: border, width: width),
          ),
        );
    return SizedBox(
      width: 24,
      height: 24,
      child: Stack(
        children: [
          Positioned(top: 0, right: 0, child: square(colors.lineStrong, 1.4)),
          Positioned(bottom: 0, left: 0, child: square(colors.ink, 1.8)),
        ],
      ),
    );
  }
}

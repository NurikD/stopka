import 'package:flutter/material.dart';

import '../theme/app_theme_extension.dart';
import '../theme/tokens.dart';
import 'app_card.dart';

/// A card with the pile made literal. Per the artboards, 1-2 lower sheets
/// peek out **above** the card, each a little narrower than the one in
/// front. [layers] is how many stacks remain after the current one (max
/// two).
class StackedCard extends StatelessWidget {
  final Widget child;
  final int layers;

  const StackedCard({super.key, required this.child, required this.layers});

  static const _rise = 7.0;
  static const _inset = 12.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final count = layers.clamp(0, 2);

    return Padding(
      padding: EdgeInsets.only(top: _rise * count),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = count; i >= 1; i--)
            Positioned(
              left: _inset * i,
              right: _inset * i,
              top: -_rise * i,
              bottom: 0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.surfaceSunk,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: colors.line),
                ),
              ),
            ),
          SizedBox(width: double.infinity, child: AppCard(child: child)),
        ],
      ),
    );
  }
}

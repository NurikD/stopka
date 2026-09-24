import 'package:flutter/material.dart';

import '../theme/app_theme_extension.dart';
import '../theme/tokens.dart';
import 'app_card.dart';

/// A card with the pile made literal: 1-2 lower sheets peek out beneath it.
/// [layers] is how many stacks remain after the current one (max two).
class StackedCard extends StatelessWidget {
  final Widget child;
  final int layers;

  const StackedCard({super.key, required this.child, required this.layers});

  static const _offset = 7.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final count = layers.clamp(0, 2);

    return Padding(
      padding: EdgeInsets.only(bottom: _offset * count),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = count; i >= 1; i--)
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              bottom: -_offset * i,
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

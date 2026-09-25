import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../theme/app_theme_extension.dart';
import '../theme/tokens.dart';

/// The card: `surface` fill, 1px `line` border, radius 14, padding 18.
/// [dashed] draws a `lineStrong` dashed border on a transparent fill — an
/// invitation to act ("добавить слова с урока"), not content.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool dashed;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.s18),
    this.dashed = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final radius = BorderRadius.circular(AppRadius.card);

    final content = Padding(padding: padding, child: child);
    final Widget card = dashed
        ? CustomPaint(
            painter: _DashedBorderPainter(color: colors.lineStrong, radius: AppRadius.card),
            child: content,
          )
        : DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: radius,
              border: Border.all(color: colors.line),
            ),
            child: content,
          );

    if (onTap == null) return card;
    return InkWell(borderRadius: radius, onTap: onTap, child: card);
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;

  _DashedBorderPainter({required this.color, required this.radius});

  static const _dash = 6.0;
  static const _gap = 5.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)));

    for (final PathMetric metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + _dash), paint);
        distance += _dash + _gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) => old.color != color || old.radius != radius;
}

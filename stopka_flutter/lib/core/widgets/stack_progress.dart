import 'package:flutter/material.dart';

import '../theme/app_theme_extension.dart';

/// One straight segment per word in the stack (3 high, 3 gap, no rounding):
/// passed = `ink`, current = `accent`, upcoming = `line`, mistaken = `danger`.
class StackProgress extends StatelessWidget {
  final int total;

  /// Index of the word being answered; everything before it is passed.
  final int current;

  /// Indices (within the stack) answered wrongly.
  final Set<int> wrong;

  const StackProgress({super.key, required this.total, required this.current, this.wrong = const {}});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) const SizedBox(width: 3),
          Expanded(
            child: SizedBox(
              height: 3,
              child: ColoredBox(
                color: i < current
                    ? (wrong.contains(i) ? colors.danger : colors.ink)
                    : i == current
                        ? colors.accent
                        : colors.line,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

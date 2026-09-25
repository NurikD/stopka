import 'package:flutter/material.dart';

import '../theme/app_theme_extension.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';

class ChoiceOption<T> {
  final T value;
  final String label;

  const ChoiceOption(this.value, this.label);
}

/// A row of mutually exclusive options in one bordered block (radius 14).
/// The selected one is filled `ink`. Replaces Material's SegmentedButton.
class SegmentedChoice<T> extends StatelessWidget {
  final List<ChoiceOption<T>> options;
  final T selected;
  final ValueChanged<T> onChanged;

  const SegmentedChoice({super.key, required this.options, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.field),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.field),
          border: Border.all(color: colors.line),
          color: colors.surface,
        ),
        child: Row(
          children: [
            for (final option in options)
              Expanded(
                child: InkWell(
                  onTap: () => onChanged(option.value),
                  child: Container(
                    height: 48,
                    alignment: Alignment.center,
                    color: option.value == selected ? colors.ink : Colors.transparent,
                    child: Text(
                      option.label,
                      style: AppTypography.label.copyWith(
                        color: option.value == selected ? colors.inkOn : colors.muted,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

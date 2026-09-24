import 'package:flutter/material.dart';

import '../text/russian_plural.dart';
import '../theme/app_theme_extension.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';

/// The dictation input: 66 high, radius 14, mono text, accent caret. Border
/// is `line` at rest and `ink` in focus. Under it: how many letters were
/// typed (left) and the submit hint (right).
class DictationField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final VoidCallback? onSubmitted;
  final bool autofocus;

  const DictationField({
    super.key,
    required this.controller,
    this.focusNode,
    this.onSubmitted,
    this.autofocus = true,
  });

  @override
  State<DictationField> createState() => _DictationFieldState();
}

class _DictationFieldState extends State<DictationField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Focus(
          onFocusChange: (value) => setState(() => _focused = value),
          child: Container(
            height: 66,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s18),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppRadius.field),
              border: Border.all(color: _focused ? colors.ink : colors.line),
            ),
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              autofocus: widget.autofocus,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.done,
              style: AppTypography.monoInput.copyWith(color: colors.ink),
              cursorColor: colors.accent,
              cursorWidth: 2,
              cursorHeight: 30,
              onSubmitted: (_) => widget.onSubmitted?.call(),
              decoration: const InputDecoration(
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isCollapsed: true,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: widget.controller,
              builder: (context, value, _) {
                final n = value.text.length;
                return Text(
                  '$n ${pluralRu(n, one: 'буква', few: 'буквы', many: 'букв')}',
                  style: AppTypography.monoMeta.copyWith(color: colors.muted),
                );
              },
            ),
            Text('enter — проверить', style: AppTypography.monoMeta.copyWith(color: colors.muted)),
          ],
        ),
      ],
    );
  }
}

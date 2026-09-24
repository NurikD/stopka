import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Inline highlights inside reading text. Grammar target: `accentTint`
/// background with a 1.5px `accent` underline. Unfamiliar word: `markBg`
/// with a `markLine` underline.
///
/// Built as [TextSpan]s so they wrap with the text; the design's small
/// 1px/2px padding around a mark can't be expressed in a TextSpan.
class Mark {
  static TextSpan grammar(String text, TextStyle base, AppColorTokens colors) {
    return TextSpan(
      text: text,
      style: base.copyWith(
        backgroundColor: colors.accentTint,
        decoration: TextDecoration.underline,
        decorationColor: colors.accent,
        decorationThickness: 1.5,
      ),
    );
  }

  static TextSpan unfamiliar(String text, TextStyle base, AppColorTokens colors) {
    return TextSpan(
      text: text,
      style: base.copyWith(
        backgroundColor: colors.markBg,
        decoration: TextDecoration.underline,
        decorationColor: colors.markLine,
        decorationThickness: 1.5,
      ),
    );
  }
}

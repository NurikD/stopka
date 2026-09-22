import 'package:flutter/material.dart';

/// Type scale from DESIGN.md (module 1.25). English text (words, examples,
/// screen titles) uses Literata; Russian interface text uses Golos Text.
/// Styles here carry no colour — apply [AppColorTokens.textPrimary] or
/// `.textMuted` at the call site so the same style works in both themes.
class AppTypography {
  static const _literata = 'Literata';
  static const _golosText = 'GolosText';
  static const _notoSans = 'NotoSans';

  /// The word in the dictation card. Literata Medium.
  static const hero = TextStyle(
    fontFamily: _literata,
    fontWeight: FontWeight.w500,
    fontSize: 40,
    height: 44 / 40,
  );

  /// Screen titles. Literata Regular.
  static const title = TextStyle(
    fontFamily: _literata,
    fontWeight: FontWeight.w400,
    fontSize: 28,
    height: 34 / 28,
  );

  static const subtitle = TextStyle(
    fontFamily: _golosText,
    fontWeight: FontWeight.w500,
    fontSize: 20,
    height: 28 / 20,
  );

  static const body = TextStyle(
    fontFamily: _golosText,
    fontWeight: FontWeight.w400,
    fontSize: 16,
    height: 24 / 16,
  );

  /// Buttons and field labels.
  static const label = TextStyle(
    fontFamily: _golosText,
    fontWeight: FontWeight.w500,
    fontSize: 14,
    height: 20 / 14,
  );

  /// Transcription, counters — pair with `textMuted`.
  static const caption = TextStyle(
    fontFamily: _golosText,
    fontWeight: FontWeight.w400,
    fontSize: 13,
    height: 18 / 13,
  );

  /// Same size/role as [caption] but in a font with guaranteed IPA glyph
  /// coverage (ɜː, ʃ, ð, ...) — Literata/Golos Text don't guarantee this.
  /// Verify glyphs render (not tofu boxes) before shipping a build.
  static const transcription = TextStyle(
    fontFamily: _notoSans,
    fontWeight: FontWeight.w400,
    fontSize: 13,
    height: 18 / 13,
  );
}

import 'package:flutter/material.dart';

/// Type scale from DESIGN_v2.md. Russian interface text is Onest; anything
/// English (words, dictation input, counters, unit codes) is JetBrains Mono
/// so letters line up in columns and a missing letter is visible at a
/// glance. Styles carry no colour — apply a token at the call site.
///
/// `height` is line-height divided by font size, i.e. "36/40" -> 40 / 36.
class AppTypography {
  static const _onest = 'Onest';
  static const _mono = 'JetBrainsMono';
  static const _ipa = 'NotoSans';

  /// The dictation word, big numbers.
  static const display = TextStyle(
    fontFamily: _onest,
    fontWeight: FontWeight.w600,
    fontSize: 36,
    height: 40 / 36,
    letterSpacing: -1,
  );

  /// Screen title.
  static const title = TextStyle(
    fontFamily: _onest,
    fontWeight: FontWeight.w600,
    fontSize: 32,
    height: 36 / 32,
    letterSpacing: -0.8,
  );

  /// Heading of a reading text.
  static const heading = TextStyle(
    fontFamily: _onest,
    fontWeight: FontWeight.w600,
    fontSize: 20,
    height: 25 / 20,
  );

  /// Reading text and explanations.
  static const bodyText = TextStyle(
    fontFamily: _onest,
    fontWeight: FontWeight.w400,
    fontSize: 15,
    height: 25 / 15,
  );

  /// Block names and buttons.
  static const label = TextStyle(
    fontFamily: _onest,
    fontWeight: FontWeight.w600,
    fontSize: 15,
    height: 20 / 15,
  );

  static const caption = TextStyle(
    fontFamily: _onest,
    fontWeight: FontWeight.w400,
    fontSize: 13,
    height: 18 / 13,
  );

  /// Dictation input.
  static const monoInput = TextStyle(
    fontFamily: _mono,
    fontWeight: FontWeight.w500,
    fontSize: 26,
    height: 30 / 26,
    letterSpacing: 1,
  );

  /// An English word in lists and in the review.
  static const monoWord = TextStyle(
    fontFamily: _mono,
    fontWeight: FontWeight.w500,
    fontSize: 19,
    height: 24 / 19,
    letterSpacing: 0.5,
  );

  /// Counters, 01-04, "enter — проверить". Weight varies 400..600 by use.
  static const monoMeta = TextStyle(
    fontFamily: _mono,
    fontWeight: FontWeight.w500,
    fontSize: 11,
    height: 15 / 11,
  );

  /// IPA transcription — needs a font with guaranteed phonetic glyphs.
  /// Verify ɜː ʃ ð ə render (not tofu boxes) before shipping a build.
  static const transcription = TextStyle(
    fontFamily: _ipa,
    fontWeight: FontWeight.w400,
    fontSize: 13,
    height: 18 / 13,
  );
}

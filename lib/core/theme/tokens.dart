import 'package:flutter/material.dart';

/// Colour tokens from DESIGN_v2.md. Every token has exactly one counterpart
/// in the other theme; widgets read colours only from here (a hex literal
/// inside features/ is a review error, enforced by test/design_rules_test).
@immutable
class AppColorTokens {
  /// Screen background.
  final Color bg;

  /// Cards and fields.
  final Color surface;

  /// Lower sheets of the visible stack.
  final Color surfaceSunk;

  /// Borders, dividers, progress track.
  final Color line;

  /// Dashes, secondary button border.
  final Color lineStrong;

  /// Primary text, primary button fill.
  final Color ink;

  /// Text on the primary button.
  final Color inkOn;

  /// Long reading text.
  final Color body;

  /// Captions, service text.
  final Color muted;

  /// Progress, focus, the key action. At most ~10% of a screen.
  final Color accent;

  /// Grammar highlights, chips.
  final Color accentTint;

  /// A correct answer — only at the moment of review.
  final Color success;

  /// A mistake — only at the moment of review.
  final Color danger;

  /// Background of an unfamiliar word in a text.
  final Color markBg;

  /// Underline of that word. Also used for "almost" (a typo) — the design
  /// has no dedicated token for it.
  final Color markLine;

  const AppColorTokens({
    required this.bg,
    required this.surface,
    required this.surfaceSunk,
    required this.line,
    required this.lineStrong,
    required this.ink,
    required this.inkOn,
    required this.body,
    required this.muted,
    required this.accent,
    required this.accentTint,
    required this.success,
    required this.danger,
    required this.markBg,
    required this.markLine,
  });

  static const light = AppColorTokens(
    bg: Color(0xFFF3F2EF),
    surface: Color(0xFFFFFFFF),
    surfaceSunk: Color(0xFFFAFAF8),
    line: Color(0xFFE2E1DC),
    lineStrong: Color(0xFFC9C7C0),
    ink: Color(0xFF17181C),
    inkOn: Color(0xFFFFFFFF),
    body: Color(0xFF2A2C32),
    muted: Color(0xFF6E7076),
    accent: Color(0xFF2B44FF),
    accentTint: Color(0xFFE6E8FF),
    success: Color(0xFF1F7A54),
    danger: Color(0xFFC2412D),
    markBg: Color(0xFFFFF0CC),
    markLine: Color(0xFFC08A1E),
  );

  static const dark = AppColorTokens(
    bg: Color(0xFF0F1012),
    surface: Color(0xFF17181B),
    surfaceSunk: Color(0xFF131417),
    line: Color(0xFF26282C),
    lineStrong: Color(0xFF3A3C41),
    ink: Color(0xFFEDEBE6),
    inkOn: Color(0xFF0F1012),
    body: Color(0xFFD9D7D2),
    muted: Color(0xFF8E8F94),
    accent: Color(0xFF6E7BFF),
    accentTint: Color(0xFF232748),
    success: Color(0xFF3DBE87),
    danger: Color(0xFFFF6B5A),
    markBg: Color(0xFF3A3218),
    markLine: Color(0xFFE0B44A),
  );
}

/// Spacing scale: 4 / 8 / 10 / 14 / 18 / 22 / 30. Screen side padding is
/// [s22]; between cards [s10]; between meaningful blocks [s22] or more.
class AppSpacing {
  static const s4 = 4.0;
  static const s8 = 8.0;
  static const s10 = 10.0;
  static const s14 = 14.0;
  static const s18 = 18.0;
  static const s22 = 22.0;
  static const s30 = 30.0;

  static const screen = s22;
}

/// Radii. There are deliberately no pills in this system.
class AppRadius {
  static const card = 14.0;
  static const field = 14.0;
  static const button = 14.0;
  static const chip = 8.0;
  static const iconButton = 12.0;
}

/// The one deliberate motion in the app: the answer-check transition.
class AppMotion {
  static const checkDuration = Duration(milliseconds: 200);
  static const checkCurve = Curves.easeOutCubic;
}

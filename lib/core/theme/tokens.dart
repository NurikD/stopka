import 'package:flutter/material.dart';

/// Colour tokens from DESIGN.md ("ночь и латунь"). DESIGN.md names six
/// tokens (night, surface, brass, paper, muted, line) but reuses `paper`
/// for two different roles across themes — text on dark, background on
/// light. To keep call sites unambiguous, roles are split into semantic
/// fields here; each field's doc comment names its DESIGN.md token.
@immutable
class AppColorTokens {
  /// `night` (dark) / light background — app background.
  final Color background;

  /// `surface` — cards and panels, one step lighter than [background].
  final Color surface;

  /// `brass` — the single accent: active action, progress, the hero word.
  final Color accent;

  /// `paper` (dark) / light theme's `текст` — primary text on [background].
  final Color textPrimary;

  /// `muted` — captions, transcription, secondary text.
  final Color textMuted;

  /// `line` — hairlines and field borders, 1px.
  final Color hairline;

  /// `jade` — dictation answer was correct.
  final Color statusCorrect;

  /// Reuses [accent]: a typo is "almost", not a failure.
  final Color statusTypo;

  /// `clay` — dictation answer was wrong.
  final Color statusWrong;

  /// Reuses [textMuted]: a skipped answer isn't an error.
  final Color statusSkipped;

  const AppColorTokens({
    required this.background,
    required this.surface,
    required this.accent,
    required this.textPrimary,
    required this.textMuted,
    required this.hairline,
    required this.statusCorrect,
    required this.statusTypo,
    required this.statusWrong,
    required this.statusSkipped,
  });

  static const dark = AppColorTokens(
    background: Color(0xFF0E1A2B),
    surface: Color(0xFF16273E),
    accent: Color(0xFFC9A227),
    textPrimary: Color(0xFFE8EAEE),
    textMuted: Color(0xFF8A99AE),
    hairline: Color(0xFF24374F),
    statusCorrect: Color(0xFF2E8B6B),
    statusTypo: Color(0xFFC9A227),
    statusWrong: Color(0xFFB8412F),
    statusSkipped: Color(0xFF8A99AE),
  );

  static const light = AppColorTokens(
    background: Color(0xFFEDEFF3),
    surface: Color(0xFFFFFFFF),
    accent: Color(0xFFA8851B),
    textPrimary: Color(0xFF131F30),
    textMuted: Color(0xFF5C6B80),
    hairline: Color(0xFFD7DBE3),
    statusCorrect: Color(0xFF2E8B6B),
    statusTypo: Color(0xFFA8851B),
    statusWrong: Color(0xFFB8412F),
    statusSkipped: Color(0xFF5C6B80),
  );
}

/// Spacing scale: 4 / 8 / 12 / 16 / 24 / 32 / 48.
class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const xxxl = 48.0;
}

/// Radii are hierarchical, not uniform — see DESIGN.md "Форма и пространство".
class AppRadius {
  /// Hero word card.
  static const hero = 24.0;

  /// Panels and input fields.
  static const panel = 12.0;

  /// Chips and unit tags.
  static const chip = 8.0;

  /// Pill-shaped primary button — large enough to always render as a stadium.
  static const pill = 999.0;
}

/// The one deliberate motion in the app: the answer-check transition.
class AppMotion {
  static const checkDuration = Duration(milliseconds: 200);
  static const checkCurve = Curves.easeOutCubic;
}

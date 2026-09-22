import 'package:flutter/material.dart';

import 'app_theme_extension.dart';
import 'tokens.dart';
import 'typography.dart';

class AppTheme {
  static ThemeData light() => _build(AppColorTokens.light, Brightness.light);

  static ThemeData dark() => _build(AppColorTokens.dark, Brightness.dark);

  static ThemeData _build(AppColorTokens tokens, Brightness brightness) {
    final onAccent = brightness == Brightness.dark ? tokens.background : Colors.white;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: tokens.accent,
      onPrimary: onAccent,
      secondary: tokens.accent,
      onSecondary: onAccent,
      error: tokens.statusWrong,
      onError: Colors.white,
      surface: tokens.surface,
      onSurface: tokens.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: tokens.background,
      dividerColor: tokens.hairline,
      textTheme: _textTheme(tokens),
      extensions: [AppThemeExtension(tokens)],
    );
  }

  static TextTheme _textTheme(AppColorTokens tokens) {
    return TextTheme(
      headlineMedium: AppTypography.hero.copyWith(color: tokens.textPrimary),
      headlineSmall: AppTypography.title.copyWith(color: tokens.textPrimary),
      titleLarge: AppTypography.subtitle.copyWith(color: tokens.textPrimary),
      bodyLarge: AppTypography.body.copyWith(color: tokens.textPrimary),
      labelLarge: AppTypography.label.copyWith(color: tokens.textPrimary),
      bodySmall: AppTypography.caption.copyWith(color: tokens.textMuted),
    );
  }
}

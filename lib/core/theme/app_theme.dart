import 'package:flutter/material.dart';

import 'app_theme_extension.dart';
import 'tokens.dart';
import 'typography.dart';

class AppTheme {
  static ThemeData light() => _build(AppColorTokens.light, Brightness.light);

  static ThemeData dark() => _build(AppColorTokens.dark, Brightness.dark);

  static ThemeData _build(AppColorTokens t, Brightness brightness) {
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: t.ink,
      onPrimary: t.inkOn,
      secondary: t.accent,
      onSecondary: t.inkOn,
      error: t.danger,
      onError: t.inkOn,
      surface: t.surface,
      onSurface: t.ink,
      outline: t.lineStrong,
      outlineVariant: t.line,
    );

    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.field),
      borderSide: BorderSide(color: t.line),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: t.bg,
      canvasColor: t.bg,
      dividerColor: t.line,
      splashFactory: NoSplash.splashFactory,
      textTheme: _textTheme(t),
      appBarTheme: AppBarTheme(
        backgroundColor: t.bg,
        foregroundColor: t.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: AppTypography.heading.copyWith(color: t.ink),
      ),
      // The floating label that cuts a notch in the border is not part of
      // this system; fields use a hint or a caption above instead.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: t.surface,
        floatingLabelBehavior: FloatingLabelBehavior.never,
        hintStyle: AppTypography.bodyText.copyWith(color: t.muted),
        labelStyle: AppTypography.bodyText.copyWith(color: t.muted),
        border: fieldBorder,
        enabledBorder: fieldBorder,
        focusedBorder: fieldBorder.copyWith(borderSide: BorderSide(color: t.ink)),
        errorBorder: fieldBorder.copyWith(borderSide: BorderSide(color: t.danger)),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.s14, vertical: AppSpacing.s14),
      ),
      textSelectionTheme: TextSelectionThemeData(cursorColor: t.accent, selectionColor: t.accentTint),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: t.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: t.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: t.ink,
        contentTextStyle: AppTypography.bodyText.copyWith(color: t.inkOn),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: t.accent, linearTrackColor: t.line),
      extensions: [AppThemeExtension(t)],
    );
  }

  static TextTheme _textTheme(AppColorTokens t) {
    return TextTheme(
      displaySmall: AppTypography.display.copyWith(color: t.ink),
      headlineMedium: AppTypography.title.copyWith(color: t.ink),
      titleLarge: AppTypography.heading.copyWith(color: t.ink),
      bodyLarge: AppTypography.bodyText.copyWith(color: t.body),
      bodyMedium: AppTypography.bodyText.copyWith(color: t.body),
      labelLarge: AppTypography.label.copyWith(color: t.ink),
      bodySmall: AppTypography.caption.copyWith(color: t.muted),
    );
  }
}

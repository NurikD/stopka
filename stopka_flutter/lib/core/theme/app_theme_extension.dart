import 'package:flutter/material.dart';

import 'tokens.dart';

/// Exposes the full [AppColorTokens] set via Theme.of(context), for colours
/// DESIGN.md defines (hairline, muted, status colours) that don't map onto
/// a stock Material [ColorScheme] role.
@immutable
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  final AppColorTokens colors;

  const AppThemeExtension(this.colors);

  @override
  AppThemeExtension copyWith({AppColorTokens? colors}) {
    return AppThemeExtension(colors ?? this.colors);
  }

  @override
  AppThemeExtension lerp(ThemeExtension<AppThemeExtension>? other, double t) {
    if (other is! AppThemeExtension) return this;
    // A hard swap, not a cross-fade: DESIGN.md rules out gradients, and
    // blending hand-picked dark/light tokens would produce muddy colours
    // no one chose.
    return t < 0.5 ? this : other;
  }
}

extension AppThemeContext on BuildContext {
  AppColorTokens get colors => Theme.of(this).extension<AppThemeExtension>()!.colors;
}

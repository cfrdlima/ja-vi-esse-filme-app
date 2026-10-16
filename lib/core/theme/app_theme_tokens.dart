import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radii.dart';
import 'app_spacing.dart';

/// Tokens do `MASTER.md` que o `ColorScheme` e o `TextTheme` não cobrem.
/// Nos widgets: `Theme.of(context).extension<AppThemeTokens>()!`.
class AppThemeTokens extends ThemeExtension<AppThemeTokens> {
  const AppThemeTokens({
    required this.watched,
    required this.onWatched,
    required this.focusRing,
    required this.spacing,
    required this.radii,
  });

  static const dark = AppThemeTokens(
    watched: AppColors.watched,
    onWatched: AppColors.onWatched,
    focusRing: AppColors.focusRing,
    spacing: AppSpacing.standard,
    radii: AppRadii.standard,
  );

  /// Cor do selo "já visto"; sempre acompanhada de ícone e texto.
  final Color watched;
  final Color onWatched;

  /// Anel de 2dp em volta do elemento focado por teclado ou D-pad.
  final Color focusRing;
  final AppSpacing spacing;
  final AppRadii radii;

  @override
  AppThemeTokens copyWith({
    Color? watched,
    Color? onWatched,
    Color? focusRing,
    AppSpacing? spacing,
    AppRadii? radii,
  }) {
    return AppThemeTokens(
      watched: watched ?? this.watched,
      onWatched: onWatched ?? this.onWatched,
      focusRing: focusRing ?? this.focusRing,
      spacing: spacing ?? this.spacing,
      radii: radii ?? this.radii,
    );
  }

  @override
  AppThemeTokens lerp(
    covariant ThemeExtension<AppThemeTokens>? other,
    double t,
  ) {
    if (other is! AppThemeTokens) return this;
    // Medidas não interpolam: a escala é a mesma em qualquer tema.
    return AppThemeTokens(
      watched: Color.lerp(watched, other.watched, t)!,
      onWatched: Color.lerp(onWatched, other.onWatched, t)!,
      focusRing: Color.lerp(focusRing, other.focusRing, t)!,
      spacing: t < 0.5 ? spacing : other.spacing,
      radii: t < 0.5 ? radii : other.radii,
    );
  }
}

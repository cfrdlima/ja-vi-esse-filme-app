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
    required this.spacing,
    required this.radii,
  });

  static const dark = AppThemeTokens(
    watched: AppColors.watched,
    onWatched: AppColors.onWatched,
    spacing: AppSpacing.standard,
    radii: AppRadii.standard,
  );

  /// Cor do selo "já visto"; sempre acompanhada de ícone e texto.
  final Color watched;
  final Color onWatched;
  final AppSpacing spacing;
  final AppRadii radii;

  @override
  AppThemeTokens copyWith({
    Color? watched,
    Color? onWatched,
    AppSpacing? spacing,
    AppRadii? radii,
  }) {
    return AppThemeTokens(
      watched: watched ?? this.watched,
      onWatched: onWatched ?? this.onWatched,
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
      spacing: t < 0.5 ? spacing : other.spacing,
      radii: t < 0.5 ? radii : other.radii,
    );
  }
}

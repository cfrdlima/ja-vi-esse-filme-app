import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radii.dart';
import 'app_theme_tokens.dart';
import 'app_typography.dart';

/// `ThemeData` do app, montado a partir dos tokens do `MASTER.md`.
abstract final class AppTheme {
  static const _minTouchTarget = Size(64, 48);

  static ThemeData dark() {
    const scheme = AppColors.darkScheme;
    const radii = AppRadii.standard;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: AppTypography.textTheme,
      extensions: const [AppThemeTokens.dark],
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: _minTouchTarget,
          shape: _rounded(radii.sm),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: _minTouchTarget,
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: scheme.outline),
          shape: _rounded(radii.sm),
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainer,
        elevation: 0,
        shape: _rounded(radii.md),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        shape: _rounded(radii.lg),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: scheme.surfaceContainerHigh,
        border: _inputBorder(radii.sm, BorderSide.none),
        focusedBorder: _inputBorder(
          radii.sm,
          BorderSide(color: scheme.outline),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainer,
        indicatorColor: scheme.primary,
        // O padrão do M3 (onSecondaryContainer) dá ~2,9:1 sobre o dourado.
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? scheme.onPrimary
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  static RoundedRectangleBorder _rounded(double radius) =>
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius));

  static OutlineInputBorder _inputBorder(double radius, BorderSide side) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: side,
      );
}

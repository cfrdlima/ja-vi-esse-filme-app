import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radii.dart';
import 'app_spacing.dart';
import 'app_theme_tokens.dart';
import 'app_typography.dart';

/// `ThemeData` do app, montado a partir dos tokens do `MASTER.md`.
abstract final class AppTheme {
  static const _minTouchTarget = Size(64, 48);
  static const _focusedBorderWidth = 2.0;
  static const _scrimOpacity = 0.5;
  // Opacidade padrão do M3 para contornos de componentes desabilitados.
  static const _disabledOpacity = 0.12;

  static ThemeData dark() {
    const scheme = AppColors.darkScheme;
    const radii = AppRadii.standard;
    final barrier = scheme.scrim.withValues(alpha: _scrimOpacity);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      // Família padrão para o que a escala não cobre (ex.: primaryTextTheme).
      fontFamily: AppTypography.bodyFamily,
      textTheme: AppTypography.textTheme,
      extensions: const [AppThemeTokens.dark],
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: _minTouchTarget,
          shape: _rounded(radii.sm),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style:
            OutlinedButton.styleFrom(
              minimumSize: _minTouchTarget,
              foregroundColor: scheme.onSurface,
              shape: _rounded(radii.sm),
            ).copyWith(
              side: WidgetStateProperty.resolveWith(
                (states) => BorderSide(
                  color: states.contains(WidgetState.disabled)
                      ? scheme.onSurface.withValues(alpha: _disabledOpacity)
                      : scheme.outline,
                ),
              ),
            ),
      ),
      // O selecionado já se distingue pelo preenchimento e pela semântica
      // `selected`. Sem o check e com respiro `xs` no rótulo, os três chips
      // da Descobrir cabem numa linha num celular de 412dp.
      chipTheme: ChipThemeData(
        showCheckmark: false,
        labelPadding: EdgeInsets.symmetric(horizontal: AppSpacing.standard.xs),
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainer,
        elevation: 0,
        shape: _rounded(radii.md),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        shape: _rounded(radii.lg),
        barrierColor: barrier,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radii.lg)),
        ),
        modalBarrierColor: barrier,
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: scheme.surfaceContainerHigh,
        border: _inputBorder(radii.sm, BorderSide.none),
        focusedBorder: _inputBorder(
          radii.sm,
          BorderSide(color: scheme.outline, width: _focusedBorderWidth),
        ),
        errorBorder: _inputBorder(radii.sm, BorderSide(color: scheme.error)),
        focusedErrorBorder: _inputBorder(
          radii.sm,
          BorderSide(color: scheme.error, width: _focusedBorderWidth),
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

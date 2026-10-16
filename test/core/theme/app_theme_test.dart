import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/core/theme/app_colors.dart';
import 'package:ja_vi_esse_filme/core/theme/app_radii.dart';
import 'package:ja_vi_esse_filme/core/theme/app_theme.dart';
import 'package:ja_vi_esse_filme/core/theme/app_theme_tokens.dart';
import 'package:ja_vi_esse_filme/core/theme/app_typography.dart';

const _minTouchTarget = 48.0;
final _scrim50 = AppColors.scrim.withValues(alpha: 0.5);

RoundedRectangleBorder _shapeOf(ButtonStyle? style) =>
    style!.shape!.resolve({})! as RoundedRectangleBorder;

void main() {
  final theme = AppTheme.dark();
  const radii = AppRadii.standard;

  group('AppTheme.dark', () {
    test('deve usar Material 3', () {
      expect(theme.useMaterial3, isTrue);
    });

    test('deve usar o ColorScheme escuro do MASTER.md', () {
      expect(theme.colorScheme, AppColors.darkScheme);
    });

    test('deve registrar a extensão de tokens', () {
      expect(theme.extension<AppThemeTokens>(), AppThemeTokens.dark);
    });

    test('deve usar o fundo da paleta no Scaffold', () {
      expect(theme.scaffoldBackgroundColor, AppColors.background);
    });

    test('deve usar Playfair Display nos títulos', () {
      expect(
        theme.textTheme.headlineLarge!.fontFamily,
        AppTypography.headingFamily,
      );
    });

    test('deve usar Inter no corpo', () {
      expect(theme.textTheme.bodyLarge!.fontFamily, AppTypography.bodyFamily);
    });

    test('deve usar Inter também no primaryTextTheme', () {
      expect(
        theme.primaryTextTheme.bodyLarge!.fontFamily,
        AppTypography.bodyFamily,
      );
    });

    test('deve manter o letterSpacing do MASTER.md após o merge com o M3', () {
      expect(theme.textTheme.bodyLarge!.letterSpacing, 0);
    });

    test('deve aplicar a cor do texto às famílias empacotadas', () {
      expect(theme.textTheme.bodyLarge!.color, AppColors.foreground);
    });
  });

  group('componentes (seção 5 do MASTER.md)', () {
    test('o botão principal deve ter raio sm', () {
      expect(
        _shapeOf(theme.filledButtonTheme.style).borderRadius,
        BorderRadius.circular(radii.sm),
      );
    });

    test('o botão principal deve ter alvo de toque de 48dp', () {
      expect(
        theme.filledButtonTheme.style!.minimumSize!.resolve({})!.height,
        _minTouchTarget,
      );
    });

    test('o botão secundário deve ter borda na cor outline', () {
      expect(
        theme.outlinedButtonTheme.style!.side!.resolve({})!.color,
        AppColors.outline,
      );
    });

    test('o card deve usar surfaceContainer, raio md e nenhuma sombra', () {
      final card = theme.cardTheme;
      expect(
        (
          card.color,
          card.elevation,
          (card.shape! as RoundedRectangleBorder).borderRadius,
        ),
        (AppColors.card, 0.0, BorderRadius.circular(radii.md)),
      );
    });

    test('o diálogo deve usar surfaceContainerHigh e raio lg', () {
      final dialog = theme.dialogTheme;
      expect(
        (
          dialog.backgroundColor,
          (dialog.shape! as RoundedRectangleBorder).borderRadius,
        ),
        (AppColors.muted, BorderRadius.circular(radii.lg)),
      );
    });

    test('o diálogo deve ter scrim preto a 50%', () {
      expect(theme.dialogTheme.barrierColor, _scrim50);
    });

    test('o bottom sheet deve usar surfaceContainerHigh', () {
      expect(theme.bottomSheetTheme.backgroundColor, AppColors.muted);
    });

    test('o bottom sheet deve ter raio lg só nos cantos de cima', () {
      final shape = theme.bottomSheetTheme.shape! as RoundedRectangleBorder;
      expect(
        shape.borderRadius,
        BorderRadius.vertical(top: Radius.circular(radii.lg)),
      );
    });

    test('o bottom sheet modal deve ter scrim preto a 50%', () {
      expect(theme.bottomSheetTheme.modalBarrierColor, _scrim50);
    });

    test('o campo de texto deve ser preenchido com surfaceContainerHigh', () {
      final input = theme.inputDecorationTheme;
      expect((input.filled, input.fillColor), (true, AppColors.muted));
    });

    test('o campo de texto em foco deve ter borda outline de 2dp', () {
      final border =
          theme.inputDecorationTheme.focusedBorder! as OutlineInputBorder;
      expect(
        (border.borderSide.color, border.borderSide.width, border.borderRadius),
        (AppColors.outline, 2.0, BorderRadius.circular(radii.sm)),
      );
    });

    test('o campo de texto com erro deve ter borda error de 1dp', () {
      final border =
          theme.inputDecorationTheme.errorBorder! as OutlineInputBorder;
      expect(
        (border.borderSide.color, border.borderSide.width, border.borderRadius),
        (AppColors.error, 1.0, BorderRadius.circular(radii.sm)),
      );
    });

    test('o campo de texto com erro e em foco deve ter borda error de 2dp', () {
      final border =
          theme.inputDecorationTheme.focusedErrorBorder! as OutlineInputBorder;
      expect(
        (border.borderSide.color, border.borderSide.width, border.borderRadius),
        (AppColors.error, 2.0, BorderRadius.circular(radii.sm)),
      );
    });

    test('a aba ativa deve ter indicador na cor primary', () {
      expect(theme.navigationBarTheme.indicatorColor, AppColors.gold);
    });

    test('o ícone da aba ativa deve usar onPrimary sobre o indicador', () {
      final icon = theme.navigationBarTheme.iconTheme!.resolve({
        WidgetState.selected,
      })!;
      expect(icon.color, AppColors.onGold);
    });

    test('o ícone das abas inativas deve usar onSurfaceVariant', () {
      final icon = theme.navigationBarTheme.iconTheme!.resolve({})!;
      expect(icon.color, AppColors.mutedForeground);
    });
  });
}

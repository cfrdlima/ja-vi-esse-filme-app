import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/core/theme/app_colors.dart';
import 'package:ja_vi_esse_filme/core/theme/app_radii.dart';
import 'package:ja_vi_esse_filme/core/theme/app_spacing.dart';
import 'package:ja_vi_esse_filme/core/theme/app_theme_tokens.dart';

void main() {
  const tokens = AppThemeTokens.dark;

  group('AppThemeTokens.dark', () {
    test('deve expor a cor de "já visto" do MASTER.md', () {
      expect(
        (tokens.watched, tokens.onWatched),
        (AppColors.watched, AppColors.onWatched),
      );
    });

    test('deve usar a escala padrão de espaçamento e raios', () {
      expect(
        (tokens.spacing, tokens.radii),
        (AppSpacing.standard, AppRadii.standard),
      );
    });
  });

  group('copyWith', () {
    test('deve trocar só a cor de "já visto"', () {
      final copy = tokens.copyWith(watched: Colors.red);
      expect(
        (copy.watched, copy.onWatched, copy.spacing, copy.radii),
        (Colors.red, tokens.onWatched, tokens.spacing, tokens.radii),
      );
    });
  });

  group('lerp', () {
    final other = tokens.copyWith(watched: Colors.black);

    test('deve interpolar a cor de "já visto"', () {
      final mid = tokens.lerp(other, 0.5);
      expect(mid.watched, Color.lerp(tokens.watched, Colors.black, 0.5));
    });

    test(
      'deve manter os tokens atuais quando o outro não for AppThemeTokens',
      () {
        expect(tokens.lerp(null, 0.5), tokens);
      },
    );
  });
}

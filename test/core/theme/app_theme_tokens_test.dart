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

    test('deve expor o anel de foco do MASTER.md', () {
      expect(tokens.focusRing, const Color(0xFFFFFFFF));
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
        (
          copy.watched,
          copy.onWatched,
          copy.focusRing,
          copy.spacing,
          copy.radii,
        ),
        (
          Colors.red,
          tokens.onWatched,
          tokens.focusRing,
          tokens.spacing,
          tokens.radii,
        ),
      );
    });

    test('deve trocar só o anel de foco', () {
      final copy = tokens.copyWith(focusRing: Colors.red);
      expect((copy.focusRing, copy.watched), (Colors.red, tokens.watched));
    });
  });

  group('lerp', () {
    final other = tokens.copyWith(watched: Colors.black);

    test('deve interpolar a cor de "já visto"', () {
      final mid = tokens.lerp(other, 0.5);
      expect(mid.watched, Color.lerp(tokens.watched, Colors.black, 0.5));
    });

    test('deve interpolar o anel de foco', () {
      final dark = tokens.copyWith(focusRing: Colors.black);
      final mid = tokens.lerp(dark, 0.5);
      expect(mid.focusRing, Color.lerp(tokens.focusRing, Colors.black, 0.5));
    });

    test(
      'deve manter os tokens atuais quando o outro não for AppThemeTokens',
      () {
        expect(tokens.lerp(null, 0.5), tokens);
      },
    );
  });
}

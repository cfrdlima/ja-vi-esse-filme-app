import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/core/theme/app_colors.dart';

/// Razão de contraste WCAG 2.x a partir da luminância relativa.
double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}

const _textAA = 4.5;
const _nonTextAA = 3.0;

void main() {
  const surfaces = {
    'fundo': AppColors.background,
    'card': AppColors.card,
    'muted': AppColors.muted,
  };

  test('o cálculo deve reprovar o índigo sobre o fundo', () {
    expect(
      contrastRatio(AppColors.indigo, AppColors.background),
      lessThan(_nonTextAA),
    );
  });

  final textOnSurfaces = {
    'texto principal': AppColors.foreground,
    'texto secundário': AppColors.mutedForeground,
    'dourado': AppColors.gold,
    'erro': AppColors.error,
    'já visto': AppColors.watched,
  };

  textOnSurfaces.forEach((name, color) {
    surfaces.forEach((surfaceName, surface) {
      test('$name sobre $surfaceName deve atingir AA (4,5:1)', () {
        expect(contrastRatio(color, surface), greaterThanOrEqualTo(_textAA));
      });
    });
  });

  surfaces.forEach((surfaceName, surface) {
    test('a borda sobre $surfaceName deve atingir 3:1', () {
      expect(
        contrastRatio(AppColors.outline, surface),
        greaterThanOrEqualTo(_nonTextAA),
      );
    });
  });

  final onColors = {
    'texto sobre o dourado': (AppColors.onGold, AppColors.gold),
    'texto sobre o erro': (AppColors.onError, AppColors.error),
    'texto sobre o já visto': (AppColors.onWatched, AppColors.watched),
    'texto sobre o índigo': (AppColors.foreground, AppColors.indigo),
    'texto sobre o índigo claro': (
      AppColors.foreground,
      AppColors.indigoBright,
    ),
  };

  onColors.forEach((name, pair) {
    final (foreground, background) = pair;
    test('$name deve atingir AA (4,5:1)', () {
      expect(
        contrastRatio(foreground, background),
        greaterThanOrEqualTo(_textAA),
      );
    });
  });
}

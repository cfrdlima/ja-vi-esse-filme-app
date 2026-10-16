import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/core/theme/app_typography.dart';

typedef _Spec = (
  String family,
  FontWeight weight,
  double size,
  double height,
  double letterSpacing,
);

void main() {
  final textTheme = AppTypography.textTheme;

  // Tabela e regras da seção 3 do MASTER.md: tamanho / altura de linha em dp;
  // letterSpacing 0, exceto nos estilos label (0,1).
  const playfair = AppTypography.headingFamily;
  const inter = AppTypography.bodyFamily;
  final expected = <String, (TextStyle? Function(TextTheme), _Spec)>{
    'displayLarge': (
      (t) => t.displayLarge,
      (playfair, FontWeight.w700, 57, 64, 0),
    ),
    'displayMedium': (
      (t) => t.displayMedium,
      (playfair, FontWeight.w700, 45, 52, 0),
    ),
    'displaySmall': (
      (t) => t.displaySmall,
      (playfair, FontWeight.w700, 36, 44, 0),
    ),
    'headlineLarge': (
      (t) => t.headlineLarge,
      (playfair, FontWeight.w700, 32, 40, 0),
    ),
    'headlineMedium': (
      (t) => t.headlineMedium,
      (playfair, FontWeight.w700, 28, 36, 0),
    ),
    'headlineSmall': (
      (t) => t.headlineSmall,
      (playfair, FontWeight.w600, 24, 32, 0),
    ),
    'titleLarge': ((t) => t.titleLarge, (playfair, FontWeight.w600, 22, 28, 0)),
    'titleMedium': ((t) => t.titleMedium, (inter, FontWeight.w600, 16, 24, 0)),
    'titleSmall': ((t) => t.titleSmall, (inter, FontWeight.w600, 14, 20, 0)),
    'bodyLarge': ((t) => t.bodyLarge, (inter, FontWeight.w400, 16, 24, 0)),
    'bodyMedium': ((t) => t.bodyMedium, (inter, FontWeight.w400, 14, 20, 0)),
    'bodySmall': ((t) => t.bodySmall, (inter, FontWeight.w400, 12, 16, 0)),
    'labelLarge': ((t) => t.labelLarge, (inter, FontWeight.w500, 14, 20, 0.1)),
    'labelMedium': (
      (t) => t.labelMedium,
      (inter, FontWeight.w500, 12, 16, 0.1),
    ),
    'labelSmall': ((t) => t.labelSmall, (inter, FontWeight.w500, 11, 16, 0.1)),
  };

  test('as famílias devem ser as declaradas no pubspec.yaml', () {
    expect((playfair, inter), ('PlayfairDisplay', 'Inter'));
  });

  expected.forEach((name, entry) {
    final (read, (family, weight, size, height, letterSpacing)) = entry;
    test('$name deve seguir o MASTER.md', () {
      final style = read(textTheme)!;
      expect(
        (
          style.fontFamily,
          style.fontWeight,
          style.fontSize,
          style.height,
          style.letterSpacing,
        ),
        (family, weight, size, height / size, letterSpacing),
      );
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/core/theme/app_typography.dart';

typedef _Spec = (String family, FontWeight weight, double size, double height);

void main() {
  final textTheme = AppTypography.textTheme;

  // Tabela da seção 3 do MASTER.md: tamanho / altura de linha em dp.
  const playfair = AppTypography.headingFamily;
  const inter = AppTypography.bodyFamily;
  final expected = <String, (TextStyle? Function(TextTheme), _Spec)>{
    'displaySmall': (
      (t) => t.displaySmall,
      (playfair, FontWeight.w700, 36, 44),
    ),
    'headlineLarge': (
      (t) => t.headlineLarge,
      (playfair, FontWeight.w700, 32, 40),
    ),
    'headlineMedium': (
      (t) => t.headlineMedium,
      (playfair, FontWeight.w700, 28, 36),
    ),
    'headlineSmall': (
      (t) => t.headlineSmall,
      (playfair, FontWeight.w600, 24, 32),
    ),
    'titleLarge': ((t) => t.titleLarge, (playfair, FontWeight.w600, 22, 28)),
    'titleMedium': ((t) => t.titleMedium, (inter, FontWeight.w600, 16, 24)),
    'titleSmall': ((t) => t.titleSmall, (inter, FontWeight.w600, 14, 20)),
    'bodyLarge': ((t) => t.bodyLarge, (inter, FontWeight.w400, 16, 24)),
    'bodyMedium': ((t) => t.bodyMedium, (inter, FontWeight.w400, 14, 20)),
    'bodySmall': ((t) => t.bodySmall, (inter, FontWeight.w400, 12, 16)),
    'labelLarge': ((t) => t.labelLarge, (inter, FontWeight.w500, 14, 20)),
    'labelMedium': ((t) => t.labelMedium, (inter, FontWeight.w500, 12, 16)),
    'labelSmall': ((t) => t.labelSmall, (inter, FontWeight.w500, 11, 16)),
  };

  test('as famílias devem ser as declaradas no pubspec.yaml', () {
    expect((playfair, inter), ('PlayfairDisplay', 'Inter'));
  });

  expected.forEach((name, entry) {
    final (read, (family, weight, size, height)) = entry;
    test('$name deve seguir o MASTER.md', () {
      final style = read(textTheme)!;
      expect(
        (style.fontFamily, style.fontWeight, style.fontSize, style.height),
        (family, weight, size, height / size),
      );
    });
  });
}

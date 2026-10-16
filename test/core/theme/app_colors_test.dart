import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/core/theme/app_colors.dart';

void main() {
  group('AppColors.darkScheme', () {
    final scheme = AppColors.darkScheme;

    test('deve ser um esquema escuro', () {
      expect(scheme.brightness, Brightness.dark);
    });

    // Valores do design-system/ja-vi-esse-filme/MASTER.md, seção 2.
    final expectedRoles = <String, (Color Function(ColorScheme), int)>{
      'surface': ((s) => s.surface, 0xFF0F0F23),
      'surfaceContainer': ((s) => s.surfaceContainer, 0xFF1B1B30),
      'surfaceContainerHigh': ((s) => s.surfaceContainerHigh, 0xFF27273B),
      'onSurface': ((s) => s.onSurface, 0xFFF8FAFC),
      'onSurfaceVariant': ((s) => s.onSurfaceVariant, 0xFF94A3B8),
      'primary': ((s) => s.primary, 0xFFCA8A04),
      'onPrimary': ((s) => s.onPrimary, 0xFF0F172A),
      'secondary': ((s) => s.secondary, 0xFF312E81),
      'onSecondary': ((s) => s.onSecondary, 0xFFF8FAFC),
      'secondaryContainer': ((s) => s.secondaryContainer, 0xFF1E1B4B),
      'onSecondaryContainer': ((s) => s.onSecondaryContainer, 0xFFF8FAFC),
      'outline': ((s) => s.outline, 0xFF6366F1),
      'error': ((s) => s.error, 0xFFF87171),
      'onError': ((s) => s.onError, 0xFF000000),
    };

    expectedRoles.forEach((role, expectation) {
      final (read, value) = expectation;
      test('deve usar a cor do MASTER.md em $role', () {
        expect(read(scheme), Color(value));
      });
    });
  });
}

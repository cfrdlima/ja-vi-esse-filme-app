import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/core/theme/app_spacing.dart';

void main() {
  test('a escala padrão deve seguir o MASTER.md', () {
    const s = AppSpacing.standard;
    expect(
      [s.xs, s.sm, s.md, s.lg, s.xl, s.xxl, s.xxxl],
      [4, 8, 16, 24, 32, 48, 64],
    );
  });
}

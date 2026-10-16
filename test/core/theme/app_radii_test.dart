import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/core/theme/app_radii.dart';

void main() {
  test('os raios padrão devem seguir o MASTER.md', () {
    const r = AppRadii.standard;
    expect([r.sm, r.md, r.lg], [8, 12, 16]);
  });
}

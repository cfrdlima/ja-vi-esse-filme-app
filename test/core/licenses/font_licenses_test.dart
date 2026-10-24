import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/core/licenses/font_licenses.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(LicenseRegistry.reset);
  tearDown(LicenseRegistry.reset);

  Future<String> licenseTextOf(String package) async {
    final entries = await LicenseRegistry.licenses.toList();
    final entry = entries.singleWhere((e) => e.packages.contains(package));
    return entry.paragraphs.map((p) => p.text).join('\n');
  }

  test('deve registrar a licença da Inter', () async {
    registerFontLicenses();

    expect(
      await licenseTextOf('Inter'),
      contains('Copyright 2020 The Inter Project Authors'),
    );
  });

  test('deve registrar a licença da Playfair Display', () async {
    registerFontLicenses();

    expect(
      await licenseTextOf('Playfair Display'),
      contains('Copyright 2017 The Playfair Display Project Authors'),
    );
  });
}

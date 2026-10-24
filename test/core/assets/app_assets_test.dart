import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/core/assets/app_assets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // O logo é exigido pelos termos do TMDB: o asset precisa estar no
  // `pubspec.yaml`, e não só o caminho no código.
  test('deve empacotar o logo do TMDB', () async {
    final logo = await rootBundle.load(AppAssets.tmdbLogo);

    expect(logo.lengthInBytes, greaterThan(0));
  });
}

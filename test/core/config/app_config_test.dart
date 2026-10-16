import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/core/config/app_config.dart';

void main() {
  final validBaseUrl = Uri.parse('https://api.themoviedb.org/3');

  test('deve guardar o token e a base URL válidos', () {
    final config = AppConfig(tmdbReadToken: 'token', tmdbBaseUrl: validBaseUrl);

    expect(config.tmdbBaseUrl, validBaseUrl);
  });

  test('deve rejeitar token vazio', () {
    expect(
      () => AppConfig(tmdbReadToken: '', tmdbBaseUrl: validBaseUrl),
      throwsA(isA<ConfigException>()),
    );
  });

  test('deve rejeitar base URL sem HTTPS', () {
    expect(
      () => AppConfig(
        tmdbReadToken: 'token',
        tmdbBaseUrl: Uri.parse('http://api.themoviedb.org/3'),
      ),
      throwsA(isA<ConfigException>()),
    );
  });

  test('deve falhar ao ler o ambiente quando os defines não existem', () {
    expect(AppConfig.fromEnvironment, throwsA(isA<ConfigException>()));
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/core/config/app_config.dart';

void main() {
  final validBaseUrl = Uri.parse('https://api.themoviedb.org/3');

  test('deve guardar a base URL válida', () {
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

  for (final url in [
    'https:/3',
    'https://usuario:senha@api.themoviedb.org/3',
    'https://api.themoviedb.org/3?x=1',
    'https://api.themoviedb.org/3#a',
    'https://evil.example/3',
  ]) {
    test('deve rejeitar a base URL "$url"', () {
      expect(
        () => AppConfig(tmdbReadToken: 'token', tmdbBaseUrl: Uri.parse(url)),
        throwsA(isA<ConfigException>()),
      );
    });
  }

  group('AppConfig.parse', () {
    test('deve tirar espaços e quebras de linha do token', () {
      final config = AppConfig.parse(
        tmdbReadToken: ' token\n',
        tmdbBaseUrl: 'https://api.themoviedb.org/3',
      );

      expect(config.tmdbReadToken, 'token');
    });

    test('deve transformar URL malformada em ConfigException', () {
      expect(
        () => AppConfig.parse(
          tmdbReadToken: 'token',
          tmdbBaseUrl: 'https://[bad',
        ),
        throwsA(isA<ConfigException>()),
      );
    });
  });

  // Depende de rodar sem `--dart-define-from-file`, como o `flutter test` faz
  // por padrão. Com os defines, este teste passa a falhar.
  test('deve falhar ao ler o ambiente quando os defines não existem', () {
    expect(AppConfig.fromEnvironment, throwsA(isA<ConfigException>()));
  });
}

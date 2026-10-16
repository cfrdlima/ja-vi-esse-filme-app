import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ja_vi_esse_filme/core/config/app_config.dart';
import 'package:ja_vi_esse_filme/core/network/tmdb_client.dart';

import '../../helpers/fixtures.dart';

void main() {
  final config = AppConfig(
    tmdbReadToken: 'token-de-teste',
    tmdbBaseUrl: Uri.parse('https://api.themoviedb.org/3'),
  );

  late http.Request captured;

  TmdbClient clientRespondingWith(String body, int status) {
    return TmdbClient(
      httpClient: MockClient((request) async {
        captured = request;
        return http.Response(body, status);
      }),
      config: config,
    );
  }

  group('requisição', () {
    test('deve montar a URL com base, path, query e language=pt-BR', () async {
      final client = clientRespondingWith(
        readFixture('tmdb_authentication_ok.json'),
        200,
      );

      await client.get('search/movie', query: {'query': 'Matrix'});

      expect(
        captured.url,
        Uri.parse(
          'https://api.themoviedb.org/3/search/movie?query=Matrix&language=pt-BR',
        ),
      );
    });

    test('deve autenticar com o token de leitura no header Bearer', () async {
      final client = clientRespondingWith(
        readFixture('tmdb_authentication_ok.json'),
        200,
      );

      await client.get('authentication');

      expect(captured.headers['Authorization'], 'Bearer token-de-teste');
    });
  });
}

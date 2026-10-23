import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ja_vi_esse_filme/core/config/app_config.dart';
import 'package:ja_vi_esse_filme/core/error/failures.dart';
import 'package:ja_vi_esse_filme/core/network/tmdb_client.dart';
import 'package:ja_vi_esse_filme/features/movies/data/datasources/movie_remote_data_source.dart';

import '../../../../helpers/fixtures.dart';

void main() {
  late http.Request captured;

  MovieRemoteDataSource dataSourceRespondingWith(
    String body, [
    int status = 200,
  ]) {
    final client = TmdbClient(
      httpClient: MockClient((request) async {
        captured = request;
        // Como o TMDB, responde em UTF-8: a fixture tem acentos.
        return http.Response(
          body,
          status,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
      config: AppConfig(
        tmdbReadToken: 'token-de-teste',
        tmdbBaseUrl: Uri.parse('https://api.themoviedb.org/3'),
      ),
    );
    return MovieRemoteDataSource(client: client);
  }

  group('popular', () {
    test('deve pedir movie/popular com a página na query', () async {
      final dataSource = dataSourceRespondingWith(
        readFixture('movie_popular_page1.json'),
      );

      await dataSource.popular(page: 2);

      expect(captured.url.path, '/3/movie/popular');
      expect(captured.url.queryParameters['page'], '2');
    });

    test('deve devolver a página com os filmes e o total', () async {
      final dataSource = dataSourceRespondingWith(
        readFixture('movie_popular_page1.json'),
      );

      final page = await dataSource.popular(page: 1);

      expect((page.page, page.totalPages, page.movies.length), (1, 48213, 3));
    });

    test('deve descartar o item sem id e manter os outros', () async {
      final dataSource = dataSourceRespondingWith(
        '{"page":1,"total_pages":1,"results":[{"title":"Sem id"},{"id":7,"title":"Com id"}]}',
      );

      final page = await dataSource.popular(page: 1);

      expect(page.movies.map((m) => m.id), [7]);
    });

    test('deve tratar results ausente como página vazia', () async {
      final dataSource = dataSourceRespondingWith('{"page":1,"total_pages":0}');

      final page = await dataSource.popular(page: 1);

      expect(page.movies, isEmpty);
    });

    test('deve lançar UnexpectedFailure sem page ou total_pages', () async {
      final dataSource = dataSourceRespondingWith('{"results":[]}');

      await expectLater(
        () => dataSource.popular(page: 1),
        throwsA(isA<UnexpectedFailure>()),
      );
    });

    test('deve repassar a falha tipada do cliente', () async {
      final dataSource = dataSourceRespondingWith('{}', 429);

      await expectLater(
        () => dataSource.popular(page: 1),
        throwsA(isA<RateLimitFailure>()),
      );
    });
  });
}

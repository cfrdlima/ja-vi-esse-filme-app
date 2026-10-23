import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ja_vi_esse_filme/core/config/app_config.dart';
import 'package:ja_vi_esse_filme/core/error/failures.dart';
import 'package:ja_vi_esse_filme/core/network/tmdb_client.dart';
import 'package:ja_vi_esse_filme/features/movies/data/datasources/movie_remote_data_source.dart';
import 'package:ja_vi_esse_filme/features/movies/domain/entities/movie_category.dart';
import 'package:ja_vi_esse_filme/features/movies/domain/entities/search_query.dart';

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

      await dataSource.byCategory(MovieCategory.popular, page: 2);

      expect(captured.url.path, '/3/movie/popular');
      expect(captured.url.queryParameters['page'], '2');
    });

    test('deve devolver a página com os filmes e o total', () async {
      final dataSource = dataSourceRespondingWith(
        readFixture('movie_popular_page1.json'),
      );

      final page = await dataSource.byCategory(MovieCategory.popular, page: 1);

      expect((page.page, page.totalPages, page.movies.length), (1, 48213, 3));
    });

    test('deve descartar o item sem id e manter os outros', () async {
      final dataSource = dataSourceRespondingWith(
        '{"page":1,"total_pages":1,"results":[{"title":"Sem id"},{"id":7,"title":"Com id"}]}',
      );

      final page = await dataSource.byCategory(MovieCategory.popular, page: 1);

      expect(page.movies.map((m) => m.id), [7]);
    });

    test('deve tratar results ausente como página vazia', () async {
      final dataSource = dataSourceRespondingWith('{"page":1,"total_pages":0}');

      final page = await dataSource.byCategory(MovieCategory.popular, page: 1);

      expect(page.movies, isEmpty);
    });

    test('deve lançar UnexpectedFailure sem page ou total_pages', () async {
      final dataSource = dataSourceRespondingWith('{"results":[]}');

      await expectLater(
        () => dataSource.byCategory(MovieCategory.popular, page: 1),
        throwsA(isA<UnexpectedFailure>()),
      );
    });

    test('deve repassar a falha tipada do cliente', () async {
      final dataSource = dataSourceRespondingWith('{}', 429);

      await expectLater(
        () => dataSource.byCategory(MovieCategory.popular, page: 1),
        throwsA(isA<RateLimitFailure>()),
      );
    });
  });

  group('em cartaz', () {
    test('deve pedir movie/now_playing', () async {
      final dataSource = dataSourceRespondingWith(
        readFixture('movie_now_playing_page1.json'),
      );

      await dataSource.byCategory(MovieCategory.nowPlaying, page: 1);

      expect(captured.url.path, '/3/movie/now_playing');
    });

    test('deve pedir com a região do Brasil', () async {
      final dataSource = dataSourceRespondingWith(
        readFixture('movie_now_playing_page1.json'),
      );

      await dataSource.byCategory(MovieCategory.nowPlaying, page: 1);

      expect(captured.url.queryParameters['region'], 'BR');
    });

    test('deve pedir a página na query', () async {
      final dataSource = dataSourceRespondingWith(
        readFixture('movie_now_playing_page1.json'),
      );

      await dataSource.byCategory(MovieCategory.nowPlaying, page: 3);

      expect(captured.url.queryParameters['page'], '3');
    });

    test('deve ignorar o campo dates e devolver os filmes', () async {
      final dataSource = dataSourceRespondingWith(
        readFixture('movie_now_playing_page1.json'),
      );

      final page = await dataSource.byCategory(
        MovieCategory.nowPlaying,
        page: 1,
      );

      expect(page.movies.map((m) => m.id), [1220564, 1311031]);
    });
  });

  group('melhor avaliados', () {
    test('deve pedir movie/top_rated', () async {
      final dataSource = dataSourceRespondingWith(
        readFixture('movie_top_rated_page1.json'),
      );

      await dataSource.byCategory(MovieCategory.topRated, page: 1);

      expect(captured.url.path, '/3/movie/top_rated');
    });

    test('deve devolver os filmes da página', () async {
      final dataSource = dataSourceRespondingWith(
        readFixture('movie_top_rated_page1.json'),
      );

      final page = await dataSource.byCategory(MovieCategory.topRated, page: 1);

      expect(page.movies.map((m) => m.title), [
        'O Poderoso Chefão',
        'Cidade de Deus',
      ]);
    });
  });

  test('só o em cartaz deve mandar a região', () async {
    final dataSource = dataSourceRespondingWith(
      readFixture('movie_top_rated_page1.json'),
    );

    await dataSource.byCategory(MovieCategory.topRated, page: 1);
    final topRatedQuery = captured.url.queryParameters;
    await dataSource.byCategory(MovieCategory.popular, page: 1);
    final popularQuery = captured.url.queryParameters;

    expect([
      topRatedQuery,
      popularQuery,
    ], everyElement(isNot(contains('region'))));
  });

  group('busca', () {
    test('deve pedir search/movie', () async {
      final dataSource = dataSourceRespondingWith(
        readFixture('search_movie_page1.json'),
      );

      await dataSource.search(SearchQuery('matrix'), page: 1);

      expect(captured.url.path, '/3/search/movie');
    });

    test('deve mandar o termo normalizado na query', () async {
      final dataSource = dataSourceRespondingWith(
        readFixture('search_movie_page1.json'),
      );

      await dataSource.search(SearchQuery('  matrix  '), page: 1);

      expect(captured.url.queryParameters['query'], 'matrix');
    });

    test('deve pedir a página na query', () async {
      final dataSource = dataSourceRespondingWith(
        readFixture('search_movie_page1.json'),
      );

      await dataSource.search(SearchQuery('matrix'), page: 3);

      expect(captured.url.queryParameters['page'], '3');
    });

    test('deve pedir sem filmes adultos', () async {
      final dataSource = dataSourceRespondingWith(
        readFixture('search_movie_page1.json'),
      );

      await dataSource.search(SearchQuery('matrix'), page: 1);

      expect(captured.url.queryParameters['include_adult'], 'false');
    });

    test('deve codificar acento, espaço e & do termo na URL', () async {
      final dataSource = dataSourceRespondingWith(
        readFixture('search_movie_empty.json'),
      );

      await dataSource.search(SearchQuery('Amélie & cia'), page: 1);

      // Decodificado inteiro: o "&" do termo não virou um parâmetro novo.
      expect(captured.url.queryParameters['query'], 'Amélie & cia');
    });

    test('o termo não deve trocar o include_adult', () async {
      final dataSource = dataSourceRespondingWith(
        readFixture('search_movie_empty.json'),
      );

      await dataSource.search(SearchQuery('x&include_adult=true'), page: 1);

      expect(captured.url.queryParametersAll['include_adult'], ['false']);
    });

    test('deve devolver os filmes, inclusive o sem pôster', () async {
      final dataSource = dataSourceRespondingWith(
        readFixture('search_movie_page1.json'),
      );

      final page = await dataSource.search(SearchQuery('matrix'), page: 1);

      expect(page.movies.map((m) => m.id), [603, 1287536]);
    });

    test('deve devolver página vazia quando nada é encontrado', () async {
      final dataSource = dataSourceRespondingWith(
        readFixture('search_movie_empty.json'),
      );

      final page = await dataSource.search(SearchQuery('xyzxyz'), page: 1);

      expect(page.movies, isEmpty);
    });

    test('deve repassar a falha tipada do cliente', () async {
      final dataSource = dataSourceRespondingWith('{}', 429);

      await expectLater(
        () => dataSource.search(SearchQuery('matrix'), page: 1),
        throwsA(isA<RateLimitFailure>()),
      );
    });
  });

  group('detalhes', () {
    test('deve pedir movie/{id}', () async {
      final dataSource = dataSourceRespondingWith(
        readFixture('movie_details_full.json'),
      );

      await dataSource.details(693134);

      expect(captured.url.path, '/3/movie/693134');
    });

    test('deve anexar o elenco e as traduções no mesmo pedido', () async {
      final dataSource = dataSourceRespondingWith(
        readFixture('movie_details_full.json'),
      );

      await dataSource.details(693134);

      expect(
        captured.url.queryParameters['append_to_response'],
        'credits,translations',
      );
    });

    test('deve devolver os detalhes do filme', () async {
      final dataSource = dataSourceRespondingWith(
        readFixture('movie_details_full.json'),
      );

      final details = await dataSource.details(693134);

      expect((details.id, details.title), (693134, 'Duna: Parte Dois'));
    });

    test(
      'deve lançar UnexpectedFailure quando a resposta vem sem id',
      () async {
        final dataSource = dataSourceRespondingWith('{"title":"Sem id"}');

        await expectLater(
          () => dataSource.details(1),
          throwsA(isA<UnexpectedFailure>()),
        );
      },
    );

    test('deve repassar o 404 como NotFoundFailure', () async {
      final dataSource = dataSourceRespondingWith(
        readFixture('tmdb_error_404.json'),
        404,
      );

      await expectLater(
        () => dataSource.details(999999999),
        throwsA(isA<NotFoundFailure>()),
      );
    });
  });
}

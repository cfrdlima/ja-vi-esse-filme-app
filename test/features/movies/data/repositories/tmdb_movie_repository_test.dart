import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ja_vi_esse_filme/core/config/app_config.dart';
import 'package:ja_vi_esse_filme/core/network/tmdb_client.dart';
import 'package:ja_vi_esse_filme/features/movies/data/datasources/movie_remote_data_source.dart';
import 'package:ja_vi_esse_filme/features/movies/data/repositories/tmdb_movie_repository.dart';
import 'package:ja_vi_esse_filme/features/movies/domain/entities/movie_category.dart';
import 'package:ja_vi_esse_filme/features/movies/domain/repositories/movie_repository.dart';

void main() {
  var requests = 0;

  MovieRepository repositoryWith(String body) {
    final client = TmdbClient(
      httpClient: MockClient((request) async {
        requests++;
        return http.Response(body, 200);
      }),
      config: AppConfig(
        tmdbReadToken: 'token-de-teste',
        tmdbBaseUrl: Uri.parse('https://api.themoviedb.org/3'),
      ),
    );
    return TmdbMovieRepository(remote: MovieRemoteDataSource(client: client));
  }

  setUp(() => requests = 0);

  test('deve devolver a página pedida da categoria', () async {
    final repository = repositoryWith(
      '{"page":2,"total_pages":5,"results":[{"id":1,"title":"A"}]}',
    );

    final page = await repository.byCategory(MovieCategory.popular, page: 2);

    expect((page.page, page.hasMore), (2, true));
  });

  test('deve recusar página menor que 1 sem chamar o TMDB', () async {
    final repository = repositoryWith('{}');

    await expectLater(
      () => repository.byCategory(MovieCategory.topRated, page: 0),
      throwsA(isA<RangeError>()),
    );
    expect(requests, 0);
  });
}

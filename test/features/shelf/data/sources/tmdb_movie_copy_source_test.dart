import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/core/error/failures.dart';
import 'package:ja_vi_esse_filme/features/movies/domain/entities/movie_details.dart';
import 'package:ja_vi_esse_filme/features/shelf/data/sources/tmdb_movie_copy_source.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/movie_copy.dart';

import '../../../../helpers/stub_movie_repository.dart';

/// Responde os detalhes com [title] e [posterPath], ou falha com [failure].
class _DetailsRepository extends StubMovieRepository {
  String title = 'Clube da Luta';
  String? posterPath = '/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg';
  Failure? failure;
  final List<int> requestedIds = [];

  @override
  Future<MovieDetails> details(int id) async {
    requestedIds.add(id);
    if (failure case final Failure failure) throw failure;
    return MovieDetails(
      id: id,
      title: title,
      overview: '',
      posterPath: posterPath,
    );
  }
}

void main() {
  late _DetailsRepository movies;
  late TmdbMovieCopySource source;

  setUp(() {
    movies = _DetailsRepository();
    source = TmdbMovieCopySource(movies: movies);
  });

  group('TmdbMovieCopySource', () {
    test('deve buscar os detalhes do filme pedido', () async {
      await source.fetchCopy(550);

      expect(movies.requestedIds, [550]);
    });

    test('deve copiar o título e o pôster dos detalhes', () async {
      final copy = await source.fetchCopy(550);

      expect(
        copy,
        MovieCopy(
          movieId: 550,
          title: 'Clube da Luta',
          posterPath: '/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg',
        ),
      );
    });

    test('deve copiar sem pôster quando o TMDB não tem', () async {
      movies.posterPath = null;

      final copy = await source.fetchCopy(550);

      expect(copy.posterPath, isNull);
    });

    test('deve deixar a falha do TMDB subir', () async {
      movies.failure = const RateLimitFailure();

      await expectLater(
        source.fetchCopy(550),
        throwsA(isA<RateLimitFailure>()),
      );
    });

    test('deve falhar com UnexpectedFailure sem título', () async {
      movies.title = '  ';

      await expectLater(
        source.fetchCopy(550),
        throwsA(isA<UnexpectedFailure>()),
      );
    });
  });
}

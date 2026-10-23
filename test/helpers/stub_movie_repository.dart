import 'package:ja_vi_esse_filme/features/movies/domain/entities/movie_page.dart';
import 'package:ja_vi_esse_filme/features/movies/domain/repositories/movie_repository.dart';

/// Responde na hora com uma lista vazia, para os testes do app inteiro
/// (router, `MainApp`) não dependerem de rede nem ficarem com o skeleton
/// animando no `pumpAndSettle`.
class StubMovieRepository implements MovieRepository {
  @override
  Future<MoviePage> popular({required int page}) async =>
      const MoviePage(movies: [], page: 1, totalPages: 0);
}

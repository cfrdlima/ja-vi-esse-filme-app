import 'package:ja_vi_esse_filme/features/movies/domain/entities/movie_category.dart';
import 'package:ja_vi_esse_filme/features/movies/domain/entities/movie_details.dart';
import 'package:ja_vi_esse_filme/features/movies/domain/entities/movie_page.dart';
import 'package:ja_vi_esse_filme/features/movies/domain/entities/search_query.dart';
import 'package:ja_vi_esse_filme/features/movies/domain/repositories/movie_repository.dart';

/// Responde na hora com uma lista vazia, para os testes do app inteiro
/// (router, `MainApp`) não dependerem de rede nem ficarem com o skeleton
/// animando no `pumpAndSettle`.
class StubMovieRepository implements MovieRepository {
  @override
  Future<MoviePage> byCategory(
    MovieCategory category, {
    required int page,
  }) async => _empty;

  @override
  Future<MoviePage> search(SearchQuery query, {required int page}) async =>
      _empty;

  @override
  Future<MovieDetails> details(int id) async =>
      MovieDetails(id: id, title: 'Filme $id', overview: '');

  static const _empty = MoviePage(movies: [], page: 1, totalPages: 0);
}

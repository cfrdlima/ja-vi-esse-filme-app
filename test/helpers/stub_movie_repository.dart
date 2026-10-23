import 'package:ja_vi_esse_filme/features/movies/domain/entities/movie.dart';
import 'package:ja_vi_esse_filme/features/movies/domain/entities/movie_category.dart';
import 'package:ja_vi_esse_filme/features/movies/domain/entities/movie_details.dart';
import 'package:ja_vi_esse_filme/features/movies/domain/entities/movie_page.dart';
import 'package:ja_vi_esse_filme/features/movies/domain/entities/search_query.dart';
import 'package:ja_vi_esse_filme/features/movies/domain/repositories/movie_repository.dart';

/// Responde na hora com uma página única de [movies] (vazia por padrão), para os testes do app inteiro
/// (router, `MainApp`) não dependerem de rede nem ficarem com o skeleton
/// animando no `pumpAndSettle`.
class StubMovieRepository implements MovieRepository {
  StubMovieRepository({this.movies = const []});

  final List<Movie> movies;

  @override
  Future<MoviePage> byCategory(
    MovieCategory category, {
    required int page,
  }) async => _page;

  @override
  Future<MoviePage> search(SearchQuery query, {required int page}) async =>
      _page;

  @override
  Future<MovieDetails> details(int id) async =>
      MovieDetails(id: id, title: 'Filme $id', overview: '');

  MoviePage get _page => MoviePage(movies: movies, page: 1, totalPages: 1);
}

import '../entities/movie_page.dart';

/// Listas paginadas de filmes. As falhas são as de `core/error/failures.dart`.
abstract interface class MovieRepository {
  /// [page] começa em 1.
  Future<MoviePage> popular({required int page});
}

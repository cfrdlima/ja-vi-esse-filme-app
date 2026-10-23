import '../entities/movie_category.dart';
import '../entities/movie_page.dart';
import '../entities/search_query.dart';

/// Listas paginadas de filmes. As falhas são as de `core/error/failures.dart`.
abstract interface class MovieRepository {
  /// [page] começa em 1.
  Future<MoviePage> byCategory(MovieCategory category, {required int page});

  /// Filmes cujo título (traduzido, original ou alternativo) bate com
  /// [query], sem filmes adultos. [page] começa em 1.
  Future<MoviePage> search(SearchQuery query, {required int page});
}

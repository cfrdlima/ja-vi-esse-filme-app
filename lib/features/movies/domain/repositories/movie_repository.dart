import '../entities/movie_category.dart';
import '../entities/movie_details.dart';
import '../entities/movie_page.dart';
import '../entities/search_query.dart';

/// Filmes: listas paginadas e detalhes. As falhas são as de `core/error/failures.dart`.
abstract interface class MovieRepository {
  /// [page] começa em 1.
  Future<MoviePage> byCategory(MovieCategory category, {required int page});

  /// Filmes cujo título (traduzido, original ou alternativo) bate com
  /// [query], sem filmes adultos. [page] começa em 1.
  Future<MoviePage> search(SearchQuery query, {required int page});

  /// Detalhes do filme [id] (a partir de 1). Filme inexistente é
  /// `NotFoundFailure`.
  Future<MovieDetails> details(int id);
}

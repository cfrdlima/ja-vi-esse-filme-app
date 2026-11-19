import '../../../../core/error/failures.dart';
import '../entities/movie_copy.dart';
import '../entities/movie_list.dart';
import '../entities/shelf_entry.dart';
import '../repositories/movie_lists_repository.dart';

/// Põe um filme numa lista abaixo do teto de filmes (decisão 019).
class AddMovieToList {
  const AddMovieToList(this._lists);

  final MovieListsRepository _lists;

  /// Põe o filme da [copy] na [list]. O [current] é o que a Estante sabe do
  /// filme: se ele já está na lista, não grava nada, porque as regras
  /// recusam regravar a hora em que entrou. Falha com [ListFullFailure] na
  /// lista cheia, sem gravar nada; as outras falhas são as do `addToList`.
  Future<void> call(
    MovieCopy copy,
    MovieList list, {
    required ShelfEntry current,
  }) async {
    if (current case OnShelf(:final movie) when movie.isInList(list.id)) {
      return;
    }
    if (await _lists.countMovies(list) >= MovieList.maxMovies) {
      throw const ListFullFailure();
    }
    await _lists.addToList(copy, list);
  }
}

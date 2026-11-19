import '../../../../core/error/failures.dart';
import '../entities/movie_list.dart';
import '../repositories/movie_lists_repository.dart';

/// Cria uma lista abaixo do teto da conta (decisão 019). As regras do
/// Firestore não contam documentos, então o teto vale só aqui.
class CreateMovieList {
  const CreateMovieList(this._lists);

  final MovieListsRepository _lists;

  /// Grava a [list] do `MovieListsRepository.newList`. Falha com
  /// [ListLimitFailure] no teto, sem gravar nada; as outras falhas são as
  /// do `createList`. Offline, só completa quando o servidor confirma.
  Future<void> call(MovieList list) async {
    if (await _lists.countLists() >= MovieList.maxPerAccount) {
      throw const ListLimitFailure();
    }
    await _lists.createList(list);
  }
}

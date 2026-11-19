import '../../../../core/error/failures.dart';
import '../entities/movie_list.dart';
import '../repositories/movie_lists_repository.dart';

/// Cria uma lista abaixo do teto da conta (decisão 019). As regras do
/// Firestore não contam documentos, então o teto vale só aqui.
class CreateMovieList {
  const CreateMovieList(this._lists);

  final MovieListsRepository _lists;

  /// Grava a [list] do `MovieListsRepository.newList`. Falha com
  /// [ListLimitFailure] no teto, sem gravar nada. Passado o teto, completa
  /// com a escrita em [saved], que só completa quando o servidor confirma
  /// (offline, pode demorar horas) e traz as falhas do `createList`: quem
  /// chama pode pôr um filme na lista nova sem esperar por ela. O record
  /// impede que o `async` junte as duas esperas numa só.
  Future<({Future<void> saved})> call(MovieList list) async {
    if (await _lists.countLists() >= MovieList.maxPerAccount) {
      throw const ListLimitFailure();
    }
    return (saved: _lists.createList(list));
  }
}

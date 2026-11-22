import '../../../../core/error/failures.dart';
import '../../domain/entities/movie_list.dart';

/// Uma lista na aba Listas, com a exclusão em andamento.
final class MovieListItem {
  const MovieListItem(this.list, {this.deleting = false});

  final MovieList list;

  /// Apagar espera o servidor (decisão 019): a linha fica desabilitada.
  final bool deleting;
}

/// A aba Listas da Estante (decisão 019). A tela faz `switch` exaustivo.
sealed class MovieListsState {
  const MovieListsState();
}

/// Ainda sem a conta, ou logado e sem a primeira leitura.
final class MovieListsLoading extends MovieListsState {
  const MovieListsLoading();
}

/// Ninguém logado: a Estante inteira já é o convite.
final class MovieListsSignedOut extends MovieListsState {
  const MovieListsSignedOut();
}

final class MovieListsError extends MovieListsState {
  const MovieListsError(this.failure);

  final Failure failure;
}

/// Nenhuma lista ainda.
final class MovieListsEmpty extends MovieListsState {
  const MovieListsEmpty();
}

final class MovieListsReady extends MovieListsState {
  MovieListsReady(List<MovieListItem> lists) : lists = List.unmodifiable(lists);

  /// Em ordem alfabética.
  final List<MovieListItem> lists;

  /// A conta chegou ao teto: o "Nova lista" fica desabilitado.
  bool get atLimit => lists.length >= MovieList.maxPerAccount;
}

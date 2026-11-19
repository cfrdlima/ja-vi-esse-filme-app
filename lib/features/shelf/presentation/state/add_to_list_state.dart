import '../../../../core/error/failures.dart';
import '../../domain/entities/movie_list.dart';

/// Uma lista na folha Adicionar à lista, com o filme dentro ou não.
final class AddToListItem {
  const AddToListItem(this.list, {required this.checked});

  final MovieList list;
  final bool checked;
}

/// A folha Adicionar à lista dos Detalhes (decisão 019).
sealed class AddToListState {
  const AddToListState();
}

/// Sem as listas ou sem o filme da Estante.
final class AddToListLoading extends AddToListState {
  const AddToListLoading();
}

final class AddToListError extends AddToListState {
  const AddToListError(this.failure);

  final Failure failure;
}

final class AddToListReady extends AddToListState {
  AddToListReady(List<AddToListItem> items, {this.failure})
    : items = List.unmodifiable(items);

  /// Em ordem alfabética.
  final List<AddToListItem> items;

  /// A última escrita recusada (lista cheia, teto, servidor), abaixo das
  /// caixas.
  final Failure? failure;
}

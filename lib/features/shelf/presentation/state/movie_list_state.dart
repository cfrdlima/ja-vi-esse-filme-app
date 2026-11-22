import '../../../../core/error/failures.dart';
import '../../domain/entities/movie_list.dart';

/// A tela de uma lista (decisão 019). A tela faz `switch` exaustivo.
sealed class MovieListState {
  const MovieListState();
}

/// Sem a lista tocada na Estante (URL direta) e sem a primeira leitura.
final class MovieListLoading extends MovieListState {
  const MovieListLoading();
}

/// A conta saiu com a tela aberta.
final class MovieListSignedOut extends MovieListState {
  const MovieListSignedOut();
}

final class MovieListError extends MovieListState {
  const MovieListError(this.failure);

  final Failure failure;
}

/// A lista não existe mais (apagada aqui ou em outro aparelho).
final class MovieListGone extends MovieListState {
  const MovieListGone();
}

final class MovieListFound extends MovieListState {
  const MovieListFound(this.list, {this.deleting = false});

  final MovieList list;

  /// Apagar espera o servidor (decisão 019): o menu fica desabilitado.
  final bool deleting;

  @override
  bool operator ==(Object other) =>
      other is MovieListFound &&
      other.list == list &&
      other.deleting == deleting;

  @override
  int get hashCode => Object.hash(list, deleting);
}

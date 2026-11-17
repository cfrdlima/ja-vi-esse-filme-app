import '../../../../core/error/failures.dart';
import '../../domain/entities/shelf_movie.dart';

/// Uma aba da Estante. A tela faz `switch` exaustivo nele.
sealed class ShelfTabState {
  const ShelfTabState();
}

/// Ainda sem a conta, ou logado e sem a primeira página.
final class ShelfTabLoading extends ShelfTabState {
  const ShelfTabLoading();
}

/// Ninguém logado: a Estante convida a entrar.
final class ShelfTabSignedOut extends ShelfTabState {
  const ShelfTabSignedOut();
}

/// A primeira página não veio. Tentar de novo assina outra vez.
final class ShelfTabError extends ShelfTabState {
  const ShelfTabError(this.failure);

  final Failure failure;
}

/// Nenhum filme com a marca da aba.
final class ShelfTabEmpty extends ShelfTabState {
  const ShelfTabEmpty();
}

final class ShelfTabReady extends ShelfTabState {
  ShelfTabReady({
    required List<ShelfMovie> movies,
    required this.hasMore,
    this.loadingMore = false,
    this.failure,
  }) : movies = List.unmodifiable(movies);

  final List<ShelfMovie> movies;
  final bool hasMore;

  /// O limite maior foi pedido e ainda não chegou.
  final bool loadingMore;

  /// O erro que chegou com os filmes já na tela, para o rodapé. Os filmes
  /// ficam.
  final Failure? failure;
}

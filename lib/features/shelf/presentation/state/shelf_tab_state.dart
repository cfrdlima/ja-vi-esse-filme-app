import '../../../../core/error/failures.dart';
import '../../../movies/presentation/state/paged_movies_state.dart';
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
    this.nextPage = const NextPageIdle(),
    this.capped = false,
  }) : movies = List.unmodifiable(movies);

  final List<ShelfMovie> movies;
  final bool hasMore;

  /// O rodapé: o limite maior a caminho ou o erro que chegou com os filmes
  /// já na tela, que ficam.
  final NextPageStatus nextPage;

  /// Há mais filmes, mas a aba chegou ao `ShelfTabNotifier.maxLimit`.
  final bool capped;
}

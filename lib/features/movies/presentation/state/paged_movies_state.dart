import '../../../../core/error/failures.dart';
import '../../domain/entities/movie.dart';

/// Estado de uma lista paginada de filmes. A tela faz `switch` exaustivo nele.
sealed class PagedMoviesState {
  const PagedMoviesState();
}

final class PagedMoviesLoading extends PagedMoviesState {
  const PagedMoviesLoading();
}

final class PagedMoviesEmpty extends PagedMoviesState {
  const PagedMoviesEmpty();
}

/// A primeira página falhou; não há filmes para mostrar.
final class PagedMoviesError extends PagedMoviesState {
  const PagedMoviesError(this.failure);

  final Failure failure;
}

final class PagedMoviesLoaded extends PagedMoviesState {
  const PagedMoviesLoaded({
    required this.movies,
    required this.page,
    required this.hasMore,
    this.nextPage = const NextPageIdle(),
  });

  final List<Movie> movies;

  /// Última página já carregada.
  final int page;
  final bool hasMore;
  final NextPageStatus nextPage;

  PagedMoviesLoaded withNextPage(NextPageStatus status) => PagedMoviesLoaded(
    movies: movies,
    page: page,
    hasMore: hasMore,
    nextPage: status,
  );
}

/// Situação do pedido da próxima página, mostrada no rodapé da grade.
sealed class NextPageStatus {
  const NextPageStatus();
}

final class NextPageIdle extends NextPageStatus {
  const NextPageIdle();
}

final class NextPageLoading extends NextPageStatus {
  const NextPageLoading();
}

/// Guarda a falha para o rodapé respeitar o `retryAfter` de um 429.
final class NextPageFailed extends NextPageStatus {
  const NextPageFailed(this.failure);

  final Failure failure;
}

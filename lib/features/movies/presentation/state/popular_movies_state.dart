import '../../../../core/error/failures.dart';
import '../../domain/entities/movie.dart';

/// Estado da lista de populares. A tela faz `switch` exaustivo nele.
sealed class PopularMoviesState {
  const PopularMoviesState();
}

final class PopularMoviesLoading extends PopularMoviesState {
  const PopularMoviesLoading();
}

final class PopularMoviesEmpty extends PopularMoviesState {
  const PopularMoviesEmpty();
}

/// A primeira página falhou; não há filmes para mostrar.
final class PopularMoviesError extends PopularMoviesState {
  const PopularMoviesError(this.failure);

  final Failure failure;
}

final class PopularMoviesLoaded extends PopularMoviesState {
  const PopularMoviesLoaded({
    required this.movies,
    required this.page,
    required this.hasMore,
    this.nextPage = NextPageStatus.idle,
  });

  final List<Movie> movies;

  /// Última página já carregada.
  final int page;
  final bool hasMore;
  final NextPageStatus nextPage;

  PopularMoviesLoaded withNextPage(NextPageStatus status) =>
      PopularMoviesLoaded(
        movies: movies,
        page: page,
        hasMore: hasMore,
        nextPage: status,
      );
}

/// Situação do pedido da próxima página, mostrada no rodapé da grade.
enum NextPageStatus { idle, loading, failed }

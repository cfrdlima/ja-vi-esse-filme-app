import 'movie.dart';

/// Uma página de uma lista paginada de filmes.
final class MoviePage {
  const MoviePage({
    required this.movies,
    required this.page,
    required this.totalPages,
  });

  final List<Movie> movies;
  final int page;
  final int totalPages;

  bool get hasMore => page < totalPages;
}

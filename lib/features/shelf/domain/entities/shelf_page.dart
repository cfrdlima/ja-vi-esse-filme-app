import 'shelf_movie.dart';

/// Os filmes de uma aba da Estante até o limite pedido, a marca mais
/// recente primeiro.
final class ShelfPage {
  ShelfPage({required List<ShelfMovie> movies, required this.hasMore})
    : movies = List.unmodifiable(movies);

  final List<ShelfMovie> movies;

  /// Se um limite maior traria mais filmes.
  final bool hasMore;

  @override
  bool operator ==(Object other) =>
      other is ShelfPage &&
      other.hasMore == hasMore &&
      other.movies.length == movies.length &&
      movies.indexed.every((e) => other.movies[e.$1] == e.$2);

  @override
  int get hashCode => Object.hash(hasMore, Object.hashAll(movies));
}

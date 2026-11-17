import 'shelf_movie.dart';

/// Se um filme está na Estante. É estado explícito, e não `ShelfMovie?`,
/// para a UI tratar os dois casos com `switch` exaustivo (CLAUDE.md).
sealed class ShelfEntry {
  const ShelfEntry();
}

/// O filme não tem nenhuma marca: não há documento.
final class NotOnShelf extends ShelfEntry {
  const NotOnShelf();

  // Igual por tipo, para o `distinct()` do stream (como o `SignedOut`).
  @override
  bool operator ==(Object other) => other is NotOnShelf;

  @override
  int get hashCode => (NotOnShelf).hashCode;
}

final class OnShelf extends ShelfEntry {
  const OnShelf(this.movie);

  final ShelfMovie movie;

  @override
  bool operator ==(Object other) => other is OnShelf && other.movie == movie;

  @override
  int get hashCode => movie.hashCode;
}

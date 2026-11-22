import 'list_name.dart';

/// Uma lista personalizada do usuário (decisão 019). Os filmes dela ficam no
/// documento de cada filme, e não aqui.
final class MovieList {
  /// Recusa com [ArgumentError] o [id] vazio ou com barra, que mudaria o
  /// caminho do documento.
  MovieList({required this.id, required this.name}) {
    if (id.isEmpty || id.contains('/')) {
      throw ArgumentError.value(id, 'id', 'não é um id de documento');
    }
  }

  /// Teto de listas por conta. As regras não contam documentos, então ele
  /// vale só no app até o App Check (decisão 019).
  static const maxPerAccount = 50;

  /// Teto de filmes por lista, o mesmo das abas (decisão 014).
  static const maxMovies = 200;

  final String id;
  final ListName name;

  MovieList rename(ListName name) => MovieList(id: id, name: name);

  /// Em ordem alfabética, sem diferenciar maiúsculas e acentos: o `orderBy`
  /// do Firestore compara bytes, e "Ação" iria para depois de "Zebra".
  static List<MovieList> sortedByName(Iterable<MovieList> lists) {
    final sorted = [...lists];
    sorted.sort((a, b) {
      final byName = _fold(a.name.value).compareTo(_fold(b.name.value));
      return byName != 0 ? byName : a.id.compareTo(b.id);
    });
    return sorted;
  }

  static const _accents = {
    'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', //
    'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e', //
    'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i', //
    'ó': 'o', 'ò': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o', //
    'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u', //
    'ç': 'c', 'ñ': 'n',
  };

  static String _fold(String name) =>
      name.toLowerCase().split('').map((char) => _accents[char] ?? char).join();

  @override
  bool operator ==(Object other) =>
      other is MovieList && other.id == id && other.name == name;

  @override
  int get hashCode => Object.hash(id, name);
}

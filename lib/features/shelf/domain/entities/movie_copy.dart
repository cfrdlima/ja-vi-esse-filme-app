/// O que o documento do filme guarda do TMDB (decisão 013): o id, o título e
/// o caminho do pôster, nunca a imagem. Já sai no formato que as regras do
/// Firestore aceitam, para que a marca não seja recusada por um título longo
/// ou um pôster estranho.
final class MovieCopy {
  /// Recusa com [ArgumentError] o [movieId] menor que 1 e o [title] vazio.
  /// Corta o título em [maxTitleLength] e descarta o pôster fora do formato.
  factory MovieCopy({
    required int movieId,
    required String title,
    String? posterPath,
  }) {
    if (movieId < 1) throw ArgumentError('deve ser 1 ou mais', 'movieId');
    final trimmed = title.trim();
    if (trimmed.isEmpty) throw ArgumentError('não pode ser vazio', 'title');
    return MovieCopy._(
      movieId: movieId,
      title: _fitTitle(trimmed),
      posterPath: _isTmdbImagePath(posterPath) ? posterPath : null,
    );
  }

  const MovieCopy._({
    required this.movieId,
    required this.title,
    required this.posterPath,
  });

  /// O mesmo limite das regras, que contam unidades UTF-16 como o
  /// `String.length`.
  static const maxTitleLength = 300;

  final int movieId;
  final String title;

  /// Nulo sem pôster: a UI desenha o placeholder.
  final String? posterPath;

  // Igual à `isTmdbImagePath` do `firestore.rules`.
  static final _tmdbImagePath = RegExp(r'^/[A-Za-z0-9_-]{1,64}[.](jpg|png)$');

  static bool _isTmdbImagePath(String? path) =>
      path != null && _tmdbImagePath.hasMatch(path);

  /// Corta sem deixar meio emoji (um par substituto partido) no fim.
  static String _fitTitle(String title) {
    if (title.length <= maxTitleLength) return title;
    final lastKept = title.codeUnitAt(maxTitleLength - 1);
    final splitsPair = lastKept >= 0xD800 && lastKept <= 0xDBFF;
    return title.substring(0, maxTitleLength - (splitsPair ? 1 : 0));
  }

  @override
  bool operator ==(Object other) =>
      other is MovieCopy &&
      other.movieId == movieId &&
      other.title == title &&
      other.posterPath == posterPath;

  @override
  int get hashCode => Object.hash(movieId, title, posterPath);
}

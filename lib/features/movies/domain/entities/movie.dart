/// Filme como o app o mostra em listas. Não conhece o JSON do TMDB.
final class Movie {
  const Movie({
    required this.id,
    required this.title,
    this.posterPath,
    this.releaseDate,
    this.voteAverage = 0,
  });

  final int id;
  final String title;

  /// Caminho relativo do TMDB (ex.: `/abc.jpg`); nulo quando não há pôster.
  final String? posterPath;

  /// Nula quando o TMDB não informa a data.
  final DateTime? releaseDate;

  /// Nota média de 0 a 10.
  final double voteAverage;

  @override
  bool operator ==(Object other) =>
      other is Movie &&
      other.id == id &&
      other.title == title &&
      other.posterPath == posterPath &&
      other.releaseDate == releaseDate &&
      other.voteAverage == voteAverage;

  @override
  int get hashCode =>
      Object.hash(id, title, posterPath, releaseDate, voteAverage);
}

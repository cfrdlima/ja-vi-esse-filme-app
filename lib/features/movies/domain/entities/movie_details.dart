import 'cast_member.dart';

/// Detalhes de um filme, como a tela de detalhes os mostra.
final class MovieDetails {
  MovieDetails({
    required this.id,
    required this.title,
    required this.overview,
    this.posterPath,
    this.releaseDate,
    this.runtime,
    this.voteAverage = 0,
    List<String> genres = const [],
    List<CastMember> cast = const [],
  }) : genres = List.unmodifiable(genres),
       cast = List.unmodifiable(cast.take(maxCast));

  /// Teto do elenco mostrado, na ordem de crédito do filme.
  static const maxCast = 15;

  final int id;
  final String title;

  /// Vazio quando não há sinopse em nenhum idioma que o app mostra.
  final String overview;
  final String? posterPath;
  final DateTime? releaseDate;

  /// `null` quando o TMDB não informa a duração.
  final Duration? runtime;
  final double voteAverage;
  final List<String> genres;
  final List<CastMember> cast;
}

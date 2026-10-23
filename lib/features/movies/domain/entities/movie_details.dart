import 'cast_member.dart';
import 'trailer.dart';

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
    List<Trailer> trailers = const [],
  }) : genres = List.unmodifiable(genres),
       cast = List.unmodifiable(cast.take(maxCast)),
       trailers = List.unmodifiable(
         _distinctKeys(_byRelevance(trailers)).take(maxTrailers),
       );

  /// Teto do elenco mostrado, na ordem de crédito do filme.
  static const maxCast = 15;

  /// Teto dos trailers mostrados, já na ordem de relevância.
  static const maxTrailers = 5;

  static const _preferredLanguage = 'pt';
  static const _preferredCountry = 'BR';

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

  /// Oficiais primeiro, depois os em português, depois os do Brasil, depois
  /// trailer antes de teaser.
  final List<Trailer> trailers;

  // O TMDB pode cadastrar o mesmo vídeo em dois idiomas. Depois da ordem,
  // fica o primeiro, que é o mais relevante.
  static Iterable<Trailer> _distinctKeys(Iterable<Trailer> trailers) {
    final seen = <String>{};
    return trailers.where((trailer) => seen.add(trailer.key));
  }

  // O `sort` do Dart não é estável, por isso o índice original desempata.
  static Iterable<Trailer> _byRelevance(List<Trailer> trailers) {
    // Pesos em potência de 2: cada critério vale mais que os seguintes juntos.
    int rank(Trailer trailer) =>
        (trailer.official ? 0 : 8) +
        (trailer.language == _preferredLanguage ? 0 : 4) +
        (trailer.country == _preferredCountry ? 0 : 2) +
        (trailer.kind == TrailerKind.trailer ? 0 : 1);
    final entries = [...trailers.indexed]
      ..sort(
        (a, b) => switch (rank(a.$2).compareTo(rank(b.$2))) {
          0 => a.$1.compareTo(b.$1),
          final order => order,
        },
      );
    return entries.map((entry) => entry.$2);
  }
}

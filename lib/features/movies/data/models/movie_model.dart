import '../../../../core/network/tmdb_image_url.dart';
import '../../domain/entities/movie.dart';

/// Item de lista de filmes do TMDB (`results[]`). O parse é defensivo: o
/// TMDB manda `null`, string vazia e número inteiro onde se espera outro tipo.
final class MovieModel {
  const MovieModel._({
    required this.id,
    required this.title,
    required this.posterPath,
    required this.releaseDate,
    required this.voteAverage,
  });

  /// Lança [FormatException] sem `id`, porque o filme não teria como ser
  /// aberto nem identificado.
  factory MovieModel.fromJson(Map<String, Object?> json) {
    final id = json['id'];
    if (id is! int) throw const FormatException('filme sem id');
    return MovieModel._(
      id: id,
      title:
          _nonEmpty(json['title']) ?? _nonEmpty(json['original_title']) ?? '',
      posterPath: _posterPath(json['poster_path']),
      releaseDate: _parseDate(json['release_date']),
      voteAverage: switch (json['vote_average']) {
        final num value => value.toDouble(),
        _ => 0,
      },
    );
  }

  final int id;
  final String title;
  final String? posterPath;
  final DateTime? releaseDate;
  final double voteAverage;

  Movie toEntity() => Movie(
    id: id,
    title: title,
    posterPath: posterPath,
    releaseDate: releaseDate,
    voteAverage: voteAverage,
  );

  static String? _nonEmpty(Object? value) =>
      value is String && value.isNotEmpty ? value : null;

  // Caminho fora do formato do TMDB vira "sem pôster", e não exceção na
  // hora de montar a URL.
  static String? _posterPath(Object? value) => switch (_nonEmpty(value)) {
    final path? when TmdbImageUrl.isValidPath(path) => path,
    _ => null,
  };

  // `DateTime.tryParse` aceita "2023-13-45" e rola para outra data; só vale
  // a data que volta igual ao texto.
  static DateTime? _parseDate(Object? value) {
    if (value is! String) return null;
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
    if (match == null) return null;
    final [year, month, day] = [
      1,
      2,
      3,
    ].map((group) => int.parse(match.group(group)!)).toList();
    final date = DateTime(year, month, day);
    final valid = date.year == year && date.month == month && date.day == day;
    return valid ? date : null;
  }
}

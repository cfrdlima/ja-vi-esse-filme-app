import '../../domain/entities/movie.dart';
import 'tmdb_json.dart';

/// Item de lista de filmes do TMDB (`results[]`), com parse defensivo
/// ([TmdbJson]).
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
          TmdbJson.nonEmpty(json['title']) ??
          TmdbJson.nonEmpty(json['original_title']) ??
          '',
      posterPath: TmdbJson.imagePath(json['poster_path']),
      releaseDate: TmdbJson.date(json['release_date']),
      voteAverage: TmdbJson.voteAverage(json['vote_average']),
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
}

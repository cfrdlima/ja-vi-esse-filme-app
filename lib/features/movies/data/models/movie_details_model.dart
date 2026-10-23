import '../../domain/entities/cast_member.dart';
import '../../domain/entities/movie_details.dart';
import '../../domain/entities/trailer.dart';
import 'tmdb_json.dart';

/// Resposta de `/movie/{id}` com
/// `append_to_response=credits,translations,videos`, com parse defensivo
/// ([TmdbJson]).
final class MovieDetailsModel {
  const MovieDetailsModel._(this._json, this._id);

  /// Lança [FormatException] sem `id`, porque a resposta não seria de filme.
  factory MovieDetailsModel.fromJson(Map<String, Object?> json) {
    final id = json['id'];
    if (id is! int) throw const FormatException('detalhes sem id');
    return MovieDetailsModel._(json, id);
  }

  final Map<String, Object?> _json;
  final int _id;

  MovieDetails toEntity() => MovieDetails(
    id: _id,
    title:
        TmdbJson.nonEmpty(_json['title']) ??
        TmdbJson.nonEmpty(_json['original_title']) ??
        '',
    overview: TmdbJson.nonEmpty(_json['overview']) ?? _originalOverview() ?? '',
    posterPath: TmdbJson.imagePath(_json['poster_path']),
    releaseDate: TmdbJson.date(_json['release_date']),
    runtime: switch (_json['runtime']) {
      final int minutes when minutes > 0 => Duration(minutes: minutes),
      _ => null,
    },
    voteAverage: TmdbJson.voteAverage(_json['vote_average']),
    genres: [
      for (final genre in _objects(_json['genres']))
        ?TmdbJson.nonEmpty(genre['name']),
    ],
    cast: _cast(),
    trailers: [
      for (final video in _objects(_field(_json['videos'], 'results')))
        ?_trailer(video),
    ],
  );

  // Sem tradução em pt-BR, o `overview` vem vazio; a do idioma original vem
  // nas traduções anexadas (decisão 008).
  String? _originalOverview() {
    final language = TmdbJson.nonEmpty(_json['original_language']);
    if (language == null) return null;
    final translations = _objects(
      _field(_json['translations'], 'translations'),
    );
    for (final translation in translations) {
      if (translation['iso_639_1'] != language) continue;
      final overview = TmdbJson.nonEmpty(
        _field(translation['data'], 'overview'),
      );
      if (overview != null) return overview;
    }
    return null;
  }

  // A `order` é a ordem de crédito; quem vem sem ela fica no fim. O `sort`
  // do Dart não é estável, por isso o índice original desempata.
  List<CastMember> _cast() {
    final items = _objects(_field(_json['credits'], 'cast'));
    final entries = [
      for (final (index, item) in items.indexed)
        if (_castMember(item) case final member?)
          (
            order: switch (item['order']) {
              final int value => value,
              _ => null,
            },
            index: index,
            member: member,
          ),
    ];
    entries.sort(
      (a, b) => switch ((a.order, b.order)) {
        (final x?, final y?) when x != y => x.compareTo(y),
        (_?, null) => -1,
        (null, _?) => 1,
        _ => a.index.compareTo(b.index),
      },
    );
    return [for (final entry in entries) entry.member];
  }

  // Pessoa sem id ou sem nome não tem como ser mostrada nem identificada.
  static CastMember? _castMember(Map<String, Object?> json) {
    final id = json['id'];
    final name = TmdbJson.nonEmpty(json['name']);
    if (id is! int || name == null) return null;
    return CastMember(
      id: id,
      name: name,
      character: TmdbJson.nonEmpty(json['character']) ?? '',
      profilePath: TmdbJson.imagePath(json['profile_path']),
    );
  }

  // Só o YouTube tem URL montada e validada (decisão 009); bastidores,
  // clipes e afins não são trailer.
  static Trailer? _trailer(Map<String, Object?> json) {
    if (json['site'] != 'YouTube') return null;
    final kind = switch (json['type']) {
      'Trailer' => TrailerKind.trailer,
      'Teaser' => TrailerKind.teaser,
      _ => null,
    };
    final key = json['key'];
    if (kind == null || key is! String) return null;
    try {
      return Trailer(
        key: key,
        name: TmdbJson.nonEmpty(json['name']) ?? '',
        kind: kind,
        official: json['official'] == true,
        language: TmdbJson.nonEmpty(json['iso_639_1']) ?? '',
      );
    } on FormatException {
      return null;
    }
  }

  static Object? _field(Object? json, String key) =>
      json is Map<String, Object?> ? json[key] : null;

  static Iterable<Map<String, Object?>> _objects(Object? list) =>
      list is List<Object?> ? list.whereType<Map<String, Object?>>() : const [];
}

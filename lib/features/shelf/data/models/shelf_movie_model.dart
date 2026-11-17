import '../../domain/entities/movie_copy.dart';
import '../../domain/entities/shelf_entry.dart';
import '../../domain/entities/shelf_mark.dart';
import '../../domain/entities/shelf_movie.dart';

/// Converte o documento `users/{uid}/movies/{movieId}` (decisão 013), já com
/// as datas em `DateTime`, na entidade do domínio.
abstract final class ShelfMovieModel {
  static const _markFields = {
    ShelfMark.watched: 'watchedAt',
    ShelfMark.watchlist: 'watchlistAt',
    ShelfMark.favorite: 'favoriteAt',
  };

  /// Sem cachedAt legível, a cópia conta como vencida e é renovada.
  static final _expiredCopy = DateTime.utc(1970);

  /// Parse defensivo: uma marca que não é data é ignorada, e o documento sem
  /// nenhuma marca é [NotOnShelf]. Lança [FormatException] sem `title`
  /// legível, porque sem ele o filme não aparece na Estante.
  static ShelfEntry fromDocument(int movieId, Map<String, Object?> data) {
    final marks = {
      for (final MapEntry(key: mark, value: field) in _markFields.entries)
        if (data[field] case final DateTime at) mark: at,
    };
    if (marks.isEmpty) return const NotOnShelf();
    return OnShelf(
      ShelfMovie(
        copy: _copyOf(movieId, data),
        cachedAt: switch (data['cachedAt']) {
          final DateTime at => at,
          _ => _expiredCopy,
        },
        marks: marks,
      ),
    );
  }

  static MovieCopy _copyOf(int movieId, Map<String, Object?> data) {
    final title = data['title'];
    if (title is! String || title.trim().isEmpty) {
      // Sem o valor na mensagem: ela pode ir para o log.
      throw const FormatException('documento do filme sem title');
    }
    return MovieCopy(
      movieId: movieId,
      title: title,
      posterPath: switch (data['posterPath']) {
        final String path => path,
        _ => null,
      },
    );
  }
}

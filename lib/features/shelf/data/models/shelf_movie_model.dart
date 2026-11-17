import '../../domain/entities/movie_copy.dart';
import '../../domain/entities/shelf_entry.dart';
import '../../domain/entities/shelf_mark.dart';
import '../../domain/entities/shelf_movie.dart';
import '../gateways/shelf_gateway.dart';

/// Converte o documento `users/{uid}/movies/{movieId}` (decisão 013), já com
/// as datas em `DateTime`, na entidade do domínio.
abstract final class ShelfMovieModel {
  /// O campo de data de cada marca, com o nome usado no `firestore.rules`.
  static String _fieldOf(ShelfMark mark) => switch (mark) {
    ShelfMark.watched => 'watchedAt',
    ShelfMark.watchlist => 'watchlistAt',
    ShelfMark.favorite => 'favoriteAt',
  };

  /// Sem cachedAt legível, a cópia conta como vencida e é renovada.
  static final _expiredCopy = DateTime.utc(1970);

  /// Parse defensivo: uma marca que não é data é ignorada, e o documento sem
  /// nenhuma marca é [NotOnShelf]. Lança [FormatException] sem `title`
  /// legível, porque sem ele o filme não aparece na Estante.
  static ShelfEntry fromDocument(int movieId, Map<String, Object?> data) {
    final marks = {
      for (final mark in ShelfMark.values)
        if (data[_fieldOf(mark)] case final DateTime at) mark: at,
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

  /// Escrita com `merge` que põe a [mark] e regrava a [copy] com o
  /// `cachedAt` do servidor. Sem pôster, apaga o que estava salvo, para a
  /// cópia não misturar o título novo com o pôster antigo.
  static Map<String, FieldWrite> markFields(MovieCopy copy, ShelfMark mark) => {
    _fieldOf(mark): const ServerTime(),
    ...copyFields(copy),
  };

  /// Atualização que regrava só a [copy] com o `cachedAt` do servidor, para
  /// renovar o prazo dela sem mexer nas marcas (decisão 013).
  static Map<String, FieldWrite> copyFields(MovieCopy copy) => {
    'title': SetField(copy.title),
    'posterPath': switch (copy.posterPath) {
      final String path => SetField(path),
      null => const DeleteField(),
    },
    'cachedAt': const ServerTime(),
  };

  /// Atualização que tira a [mark] quando sobra outra. Sem nenhuma, o
  /// documento é apagado, e não atualizado (decisão 013).
  static Map<String, FieldWrite> unmarkFields(ShelfMark mark) => {
    _fieldOf(mark): const DeleteField(),
  };

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

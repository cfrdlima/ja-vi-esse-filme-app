import '../../domain/entities/movie_copy.dart';
import '../../domain/entities/rating.dart';
import '../../domain/entities/shelf_entry.dart';
import '../../domain/entities/shelf_mark.dart';
import '../../domain/entities/shelf_movie.dart';
import '../../domain/entities/shelf_page.dart';
import '../../domain/entities/watched_on.dart';
import '../gateways/shelf_gateway.dart';

/// Converte o documento `users/{uid}/movies/{movieId}` (decisões 013, 018
/// e 019), já com as datas em `DateTime`, na entidade do domínio.
abstract final class ShelfMovieModel {
  /// O campo de data de cada marca, com o nome usado no `firestore.rules`.
  static String fieldOf(ShelfMark mark) => switch (mark) {
    ShelfMark.watched => 'watchedAt',
    ShelfMark.watchlist => 'watchlistAt',
    ShelfMark.favorite => 'favoriteAt',
  };

  /// Sem cachedAt legível, a cópia conta como vencida e é renovada.
  static final _expiredCopy = DateTime.utc(1970);

  static const _rating = 'rating';
  static const _watchedOn = 'watchedOn';
  static const _lists = 'lists';

  // Igual à `isListId` do `firestore.rules`: o id automático do Firestore.
  static final _listId = RegExp(r'^[A-Za-z0-9]{20}$');

  /// Parse defensivo: uma marca que não é data é ignorada, e o documento sem
  /// nenhuma marca nem lista é [NotOnShelf]. A nota ou o dia ilegível, ou
  /// sem a marca Assistido, é ignorado, e também a lista com a chave fora do
  /// formato ou o valor que não é data. Lança [FormatException] sem `title`
  /// legível, porque sem ele o filme não aparece na Estante.
  static ShelfEntry fromDocument(int movieId, Map<String, Object?> data) {
    final marks = {
      for (final mark in ShelfMark.values)
        if (data[fieldOf(mark)] case final DateTime at) mark: at,
    };
    final lists = _listsOf(data[_lists]);
    if (marks.isEmpty && lists.isEmpty) return const NotOnShelf();
    final watched = marks.containsKey(ShelfMark.watched);
    return OnShelf(
      ShelfMovie(
        copy: _copyOf(movieId, data),
        cachedAt: switch (data['cachedAt']) {
          final DateTime at => at,
          _ => _expiredCopy,
        },
        marks: marks,
        rating: watched ? _ratingOf(data[_rating]) : null,
        watchedOn: watched ? _watchedOnOf(data[_watchedOn]) : null,
        lists: lists,
      ),
    );
  }

  static Map<String, DateTime> _listsOf(Object? value) => switch (value) {
    final Map<String, Object?> lists => {
      for (final MapEntry(:key, :value) in lists.entries)
        if (_listId.hasMatch(key) && value is DateTime) key: value,
    },
    _ => const {},
  };

  /// O campo que ordena os filmes da lista [listId], o mais recente
  /// primeiro. Lança [ArgumentError] com o id fora do formato: ele vira
  /// caminho de campo, e um ponto apontaria para outro campo.
  static String listOrderField(String listId) =>
      '$_lists.${_checkedListId(listId)}';

  static String _checkedListId(String listId) {
    if (!_listId.hasMatch(listId)) {
      throw ArgumentError.value(listId, 'listId', 'fora do formato do id');
    }
    return listId;
  }

  /// Escrita com `merge` que põe o filme na lista [listId] com a hora do
  /// servidor e regrava a [copy], como o [markFields]. O `merge` mantém as
  /// outras listas.
  static Map<String, FieldWrite> addToListFields(
    MovieCopy copy,
    String listId,
  ) => {
    _lists: MapFields({_checkedListId(listId): const ServerTime()}),
    ...copyFields(copy),
  };

  /// Atualização que tira o [movie] da lista [listId] quando ele continua no
  /// documento ([ShelfMovie.staysWithoutList]). Com a última lista, sai o
  /// mapa inteiro, porque as regras recusam o mapa vazio.
  static Map<String, FieldWrite> removeFromListFields(
    ShelfMovie movie,
    String listId,
  ) {
    final field = listOrderField(listId);
    if (movie.listIds.every((id) => id == listId)) {
      return {_lists: const DeleteField()};
    }
    return {field: const DeleteField()};
  }

  static Rating? _ratingOf(Object? value) => switch (value) {
    final int halfStars
        when halfStars >= 1 && halfStars <= Rating.maxHalfStars =>
      Rating(halfStars),
    _ => null,
  };

  // Só o formato; o intervalo e o dia do calendário vêm do `WatchedOn`, mais
  // estrito que a `isWatchedOn` do `firestore.rules`.
  static final _isoDay = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

  static WatchedOn? _watchedOnOf(Object? value) {
    if (value is! String) return null;
    final match = _isoDay.firstMatch(value);
    if (match == null) return null;
    try {
      return WatchedOn(
        year: int.parse(match[1]!),
        month: int.parse(match[2]!),
        day: int.parse(match[3]!),
      );
    } on ArgumentError {
      return null;
    }
  }

  /// A página de uma aba a partir da consulta com [limit]. Um documento
  /// ilegível é pulado, para um filme estragado não derrubar a aba, mas
  /// conta para saber se há mais.
  static ShelfPage pageFrom(
    List<ShelfDocument> documents, {
    required int limit,
  }) => ShelfPage(
    movies: [
      for (final (:id, :fields) in documents)
        if (_movieOf(id, fields) case final ShelfMovie movie) movie,
    ],
    hasMore: documents.length >= limit,
  );

  // Igual à `isTmdbId` do `firestore.rules`.
  static final _tmdbId = RegExp(r'^[1-9][0-9]{0,9}$');

  static ShelfMovie? _movieOf(String id, Map<String, Object?> fields) {
    if (!_tmdbId.hasMatch(id)) return null;
    try {
      return switch (fromDocument(int.parse(id), fields)) {
        OnShelf(:final movie) => movie,
        NotOnShelf() => null,
      };
    } on FormatException {
      return null;
    }
  }

  /// Escrita com `merge` que põe a [mark] e regrava a [copy] com o
  /// `cachedAt` do servidor. Sem pôster, apaga o que estava salvo, para a
  /// cópia não misturar o título novo com o pôster antigo.
  static Map<String, FieldWrite> markFields(MovieCopy copy, ShelfMark mark) => {
    fieldOf(mark): const ServerTime(),
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
  /// documento é apagado, e não atualizado (decisão 013). Sem o Assistido,
  /// a nota e o dia saem juntos, mesmo que o aparelho não os veja: eles
  /// podem ter vindo de outro aparelho, e as regras os recusam sem o
  /// `watchedAt` (decisão 018).
  static Map<String, FieldWrite> unmarkFields(ShelfMark mark) => {
    fieldOf(mark): const DeleteField(),
    if (mark == ShelfMark.watched) ...{
      ...noRatingFields(),
      ...noWatchedOnFields(),
    },
  };

  static Map<String, FieldWrite> ratingFields(Rating rating) => {
    _rating: SetField(rating.halfStars),
  };

  static Map<String, FieldWrite> noRatingFields() => {
    _rating: const DeleteField(),
  };

  /// No formato `AAAA-MM-DD` das regras.
  static Map<String, FieldWrite> watchedOnFields(WatchedOn day) => {
    _watchedOn: SetField(
      '${_digits(day.year, 4)}-${_digits(day.month, 2)}-${_digits(day.day, 2)}',
    ),
  };

  static Map<String, FieldWrite> noWatchedOnFields() => {
    _watchedOn: const DeleteField(),
  };

  static String _digits(int value, int width) =>
      value.toString().padLeft(width, '0');

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

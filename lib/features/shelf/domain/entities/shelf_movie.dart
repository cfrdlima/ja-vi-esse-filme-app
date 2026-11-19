import 'movie_copy.dart';
import 'rating.dart';
import 'shelf_mark.dart';
import 'watched_on.dart';

/// Um filme na Estante do usuário (decisão 013): a cópia do TMDB e quando
/// cada marca entrou, pela hora do servidor. O filme assistido também pode
/// ter a nota e o dia em que foi assistido (decisão 018), e o filme pode
/// estar em listas personalizadas, com ou sem marca (decisão 019).
final class ShelfMovie {
  /// Recusa com [ArgumentError] um filme sem marca e fora de qualquer lista
  /// (sem motivo, o documento é apagado, e o filme sai da Estante) e a
  /// [rating] ou o [watchedOn] sem a marca Assistido.
  ShelfMovie({
    required this.copy,
    required this.cachedAt,
    required Map<ShelfMark, DateTime> marks,
    this.rating,
    this.watchedOn,
    Map<String, DateTime> lists = const {},
  }) : _marks = Map.unmodifiable(marks),
       _lists = Map.unmodifiable(lists) {
    if (marks.isEmpty && lists.isEmpty) {
      throw ArgumentError('precisa de uma marca ou de uma lista', 'marks');
    }
    if (_hasPersonalData && !isMarked(ShelfMark.watched)) {
      throw ArgumentError('nota e dia só no filme assistido');
    }
  }

  /// Os termos do TMDB (§1.C) limitam o cache a 6 meses. 180 dias ficam
  /// sempre abaixo disso, sem conta de calendário.
  static const copyMaxAge = Duration(days: 180);

  final MovieCopy copy;

  /// Quando a [copy] foi escrita, para contar o [copyMaxAge].
  final DateTime cachedAt;

  final Map<ShelfMark, DateTime> _marks;

  /// Id da lista para quando o filme entrou nela, pela hora do servidor.
  final Map<String, DateTime> _lists;

  /// Nula sem nota.
  final Rating? rating;

  /// Nulo quando o usuário não escolheu o dia.
  final WatchedOn? watchedOn;

  bool get _hasPersonalData => rating != null || watchedOn != null;

  bool isMarked(ShelfMark mark) => _marks.containsKey(mark);

  /// Nulo quando o filme não tem a [mark].
  DateTime? markedAt(ShelfMark mark) => _marks[mark];

  /// Vazio quando a [mark] é a única: o filme sai da Estante.
  Set<ShelfMark> marksWithout(ShelfMark mark) =>
      _marks.keys.where((m) => m != mark).toSet();

  /// Se o documento continua sem a [mark]: com outra marca ou numa lista.
  /// Senão, tirar a [mark] apaga o documento.
  bool staysWithoutMark(ShelfMark mark) =>
      marksWithout(mark).isNotEmpty || _lists.isNotEmpty;

  bool isInList(String listId) => _lists.containsKey(listId);

  Set<String> get listIds => _lists.keys.toSet();

  /// Nulo quando o filme não está na lista [listId].
  DateTime? addedToListAt(String listId) => _lists[listId];

  /// Se o documento continua fora da lista [listId]: com uma marca ou em
  /// outra lista. Senão, tirar o filme da lista apaga o documento.
  bool staysWithoutList(String listId) =>
      _marks.isNotEmpty || _lists.keys.any((id) => id != listId);

  /// Se tirar a [mark] apaga a nota ou o dia: a UI avisa antes.
  bool losesPersonalDataWithout(ShelfMark mark) =>
      mark == ShelfMark.watched && _hasPersonalData;

  /// Vencida, a cópia é renovada com o TMDB antes de aparecer como atual.
  bool isCopyExpired(DateTime now) => !now.isBefore(cachedAt.add(copyMaxAge));

  @override
  bool operator ==(Object other) =>
      other is ShelfMovie &&
      other.copy == copy &&
      other.cachedAt == cachedAt &&
      other.rating == rating &&
      other.watchedOn == watchedOn &&
      other._marks.length == _marks.length &&
      _marks.entries.every((e) => other._marks[e.key] == e.value) &&
      other._lists.length == _lists.length &&
      _lists.entries.every((e) => other._lists[e.key] == e.value);

  @override
  int get hashCode => Object.hash(
    copy,
    cachedAt,
    rating,
    watchedOn,
    Object.hashAllUnordered(_marks.entries.map((e) => (e.key, e.value))),
    Object.hashAllUnordered(_lists.entries.map((e) => (e.key, e.value))),
  );
}

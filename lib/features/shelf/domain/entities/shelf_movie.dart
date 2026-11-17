import 'movie_copy.dart';
import 'shelf_mark.dart';

/// Um filme na Estante do usuário (decisão 013): a cópia do TMDB e quando
/// cada marca entrou, pela hora do servidor.
final class ShelfMovie {
  /// Recusa com [ArgumentError] um filme sem nenhuma marca: sem marcas, o
  /// documento é apagado, e o filme sai da Estante.
  ShelfMovie({
    required this.copy,
    required this.cachedAt,
    required Map<ShelfMark, DateTime> marks,
  }) : _marks = Map.unmodifiable(marks) {
    if (marks.isEmpty) throw ArgumentError('precisa de uma marca', 'marks');
  }

  /// Os termos do TMDB (§1.C) limitam o cache a 6 meses. 180 dias ficam
  /// sempre abaixo disso, sem conta de calendário.
  static const copyMaxAge = Duration(days: 180);

  final MovieCopy copy;

  /// Quando a [copy] foi escrita, para contar o [copyMaxAge].
  final DateTime cachedAt;

  final Map<ShelfMark, DateTime> _marks;

  bool isMarked(ShelfMark mark) => _marks.containsKey(mark);

  /// Nulo quando o filme não tem a [mark].
  DateTime? markedAt(ShelfMark mark) => _marks[mark];

  /// Vazio quando a [mark] é a única: o filme sai da Estante.
  Set<ShelfMark> marksWithout(ShelfMark mark) =>
      _marks.keys.where((m) => m != mark).toSet();

  /// Vencida, a cópia é renovada com o TMDB antes de aparecer como atual.
  bool isCopyExpired(DateTime now) => !now.isBefore(cachedAt.add(copyMaxAge));

  @override
  bool operator ==(Object other) =>
      other is ShelfMovie &&
      other.copy == copy &&
      other.cachedAt == cachedAt &&
      other._marks.length == _marks.length &&
      _marks.entries.every((e) => other._marks[e.key] == e.value);

  @override
  int get hashCode => Object.hash(
    copy,
    cachedAt,
    Object.hashAllUnordered(_marks.entries.map((e) => (e.key, e.value))),
  );
}

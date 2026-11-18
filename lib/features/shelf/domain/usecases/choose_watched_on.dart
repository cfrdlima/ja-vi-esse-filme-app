import '../entities/shelf_movie.dart';
import '../entities/watched_on.dart';
import '../repositories/shelf_repository.dart';

/// O usuário escolhe o dia em que assistiu (decisão 018). As regras do
/// Firestore não sabem qual é "hoje" no fuso dele; por isso o dia no futuro
/// é recusado aqui, pelo relógio do aparelho.
class ChooseWatchedOn {
  ChooseWatchedOn({required this._shelf, required this._now});

  final ShelfRepository _shelf;
  final DateTime Function() _now;

  /// Grava o [day] no [movie] assistido. Lança [ArgumentError] com o [day]
  /// depois de [today], sem gravar; as falhas são as do
  /// [ShelfRepository.setWatchedOn].
  Future<void> call(ShelfMovie movie, WatchedOn day) {
    if (day.isAfter(today())) {
      throw ArgumentError.value(day, 'day', 'não pode ser no futuro');
    }
    return _shelf.setWatchedOn(movie, day);
  }

  /// O último dia que o seletor deixa escolher.
  WatchedOn today() => WatchedOn.fromLocal(_now());
}

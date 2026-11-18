import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/rating.dart';
import '../../domain/entities/shelf_mark.dart';
import '../../domain/entities/shelf_movie.dart';
import '../../domain/entities/watched_on.dart';
import '../../domain/repositories/shelf_repository.dart';
import '../../domain/usecases/choose_watched_on.dart';
import 'watched_diary_state.dart';

/// Um valor pedido cuja escrita ainda não terminou. O registro separa
/// "tirar" (valor nulo) de "nada pedido" (registro nulo).
typedef _Pending<T> = ({T? value, int id});

/// A nota e o dia em que assistiu (decisão 018), sobre o filme assistido que
/// o `ShelfMarksNotifier` confirma. As escritas são otimistas: o valor
/// pedido fica na tela até a escrita dele terminar, e só a recusa do
/// servidor o volta. Não sai com o snapshot que já traz o valor, porque o
/// Firestore mostra a escrita no aparelho antes de o servidor responder, e
/// a recusa chegaria depois sem ter onde aparecer (`/revisar` da 028).
class WatchedDiaryNotifier extends ChangeNotifier {
  WatchedDiaryNotifier({
    required this._shelf,
    required this._chooseWatchedOn,
    required this._watchedMovie,
  }) {
    _watchedMovie.addListener(_onMovie);
    _onMovie();
  }

  final ShelfRepository _shelf;
  final ChooseWatchedOn _chooseWatchedOn;
  final ValueListenable<ShelfMovie?> _watchedMovie;

  ShelfMovie? _movie;
  _Pending<Rating>? _rating;
  _Pending<WatchedOn>? _watchedOn;
  int _writeCount = 0;

  /// Muda quando o filme sai: a recusa de uma escrita de antes não aparece.
  int _generation = 0;

  ({Failure failure, VoidCallback retry})? _failed;
  bool _disposed = false;

  WatchedDiaryState _state = const DiaryHidden();
  WatchedDiaryState get state => _state;

  /// Na estrela [star] (1 a 5): a nota vira [star] estrelas; com elas já
  /// cheias, meia a menos.
  void tapStar(int star) {
    final full = star * 2;
    _writeRating(Rating(_shownRating()?.halfStars == full ? full - 1 : full));
  }

  /// Meia estrela a mais, para o leitor de tela.
  void increase() {
    if (_state case DiaryReady(
      :final rating,
      :final increasedRating,
    ) when rating != increasedRating) {
      _writeRating(increasedRating);
    }
  }

  /// Meia estrela a menos; de meia estrela, tira a nota.
  void decrease() {
    if (_state case DiaryReady(rating: Rating(), :final decreasedRating)) {
      _writeRating(decreasedRating);
    }
  }

  void clearRating() => _writeRating(null);

  /// O último dia que o seletor deixa escolher, pelo relógio da hora em que
  /// é pedido: a tela pode ficar aberta de um dia para o outro.
  WatchedOn today() => _chooseWatchedOn.today();

  /// Lança [ArgumentError] com o [day] no futuro, sem gravar.
  void chooseWatchedOn(WatchedOn day) {
    final movie = _writableMovie();
    if (movie == null) return;
    final write = _chooseWatchedOn(movie, day);
    _track(write, _setWatchedOn(day), () => chooseWatchedOn(day));
  }

  void clearWatchedOn() {
    final movie = _writableMovie();
    if (movie == null) return;
    _track(_shelf.clearWatchedOn(movie), _setWatchedOn(null), clearWatchedOn);
  }

  /// Repete a última escrita recusada.
  void retryWrite() => _failed?.retry();

  /// Nulo depois do dispose ou sem o filme assistido: não há o que gravar.
  ShelfMovie? _writableMovie() => _disposed ? null : _movie;

  void _writeRating(Rating? rating) {
    final movie = _writableMovie();
    if (movie == null) return;
    final write = rating == null
        ? _shelf.clearRating(movie)
        : _shelf.rate(movie, rating);
    final id = ++_writeCount;
    _rating = (value: rating, id: id);
    _track(write, id, () => _writeRating(rating));
  }

  int _setWatchedOn(WatchedOn? day) {
    final id = ++_writeCount;
    _watchedOn = (value: day, id: id);
    return id;
  }

  void _track(Future<void> write, int id, VoidCallback retry) {
    _failed = null;
    _emitReady();
    unawaited(_watchWrite(write, id, _generation, retry));
  }

  Future<void> _watchWrite(
    Future<void> write,
    int id,
    int generation,
    VoidCallback retry,
  ) async {
    try {
      await write;
      if (_disposed || generation != _generation) return;
      // Confirmada: a tela volta a seguir a Estante.
      if (_clearPending(id)) _emitReady();
    } on Exception catch (error) {
      if (_disposed || generation != _generation) return;
      // Uma escrita nova no mesmo campo já substituiu esta.
      if (!_clearPending(id)) return;
      _failed = (
        failure: error is Failure
            ? error
            : const UnexpectedFailure('exceção fora das falhas na Estante'),
        retry: retry,
      );
      _emitReady();
    }
  }

  /// Tira o pendente da escrita [id], se ela ainda for a última do campo.
  bool _clearPending(int id) {
    if (_rating?.id == id) {
      _rating = null;
      return true;
    }
    if (_watchedOn?.id == id) {
      _watchedOn = null;
      return true;
    }
    return false;
  }

  void _onMovie() {
    final movie = _watchedMovie.value;
    _movie = movie;
    if (movie == null) {
      _generation++;
      _rating = null;
      _watchedOn = null;
      _failed = null;
      return _emit(const DiaryHidden());
    }
    _emitReady();
  }

  Rating? _shownRating() {
    if (_rating case (:final value, id: _)) return value;
    return _movie?.rating;
  }

  WatchedOn? _shownWatchedOn() {
    if (_watchedOn case (:final value, id: _)) return value;
    return _movie?.watchedOn;
  }

  void _emitReady() {
    final movie = _movie;
    if (movie == null) return;
    _emit(
      DiaryReady(
        rating: _shownRating(),
        watchedOn: _shownWatchedOn(),
        markedOn: WatchedOn.fromLocal(movie.markedAt(ShelfMark.watched)!),
        failure: _failed?.failure,
      ),
    );
  }

  void _emit(WatchedDiaryState state) {
    if (_disposed) return;
    _state = state;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _watchedMovie.removeListener(_onMovie);
    super.dispose();
  }
}

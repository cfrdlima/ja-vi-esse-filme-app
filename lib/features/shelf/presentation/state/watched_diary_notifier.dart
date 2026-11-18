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

/// Um valor pedido e ainda não confirmado pela Estante. O registro separa
/// "tirar" (valor nulo) de "nada pedido" (registro nulo).
typedef _Pending<T> = ({T? value, int id});

/// A nota e o dia em que assistiu (decisão 018), sobre o filme assistido que
/// o `ShelfMarksNotifier` confirma. As escritas são otimistas como as das
/// marcas: o valor aparece na hora, e só a recusa do servidor o volta.
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
    _rate(Rating(_shownRating()?.halfStars == full ? full - 1 : full));
  }

  /// Meia estrela a mais, para o leitor de tela.
  void increase() {
    final halfStars = _shownRating()?.halfStars ?? 0;
    if (halfStars < Rating.maxHalfStars) _rate(Rating(halfStars + 1));
  }

  /// Meia estrela a menos; de meia estrela, tira a nota.
  void decrease() {
    final halfStars = _shownRating()?.halfStars;
    if (halfStars == null) return;
    if (halfStars == 1) return clearRating();
    _rate(Rating(halfStars - 1));
  }

  void clearRating() => _writeRating(null);

  /// Lança [ArgumentError] com o [day] no futuro, sem gravar.
  void chooseWatchedOn(WatchedOn day) {
    final movie = _movie;
    if (movie == null) return;
    final write = _chooseWatchedOn(movie, day);
    _track(write, _setWatchedOn(day), () => chooseWatchedOn(day));
  }

  void clearWatchedOn() {
    final movie = _movie;
    if (movie == null) return;
    _track(_shelf.clearWatchedOn(movie), _setWatchedOn(null), clearWatchedOn);
  }

  /// Repete a última escrita recusada.
  void retryWrite() => _failed?.retry();

  void _rate(Rating rating) => _writeRating(rating);

  void _writeRating(Rating? rating) {
    final movie = _movie;
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
    } on Exception catch (error) {
      if (_disposed || generation != _generation) return;
      // Uma escrita nova no mesmo campo já substituiu esta.
      if (_rating?.id == id) {
        _rating = null;
      } else if (_watchedOn?.id == id) {
        _watchedOn = null;
      } else {
        return;
      }
      _failed = (
        failure: error is Failure
            ? error
            : const UnexpectedFailure('exceção fora das falhas na Estante'),
        retry: retry,
      );
      _emitReady();
    }
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
    // A Estante já tem o que foi pedido: o otimista não é mais preciso.
    if (_rating case (:final value, id: _) when value == movie.rating) {
      _rating = null;
    }
    if (_watchedOn case (:final value, id: _) when value == movie.watchedOn) {
      _watchedOn = null;
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
        today: _chooseWatchedOn.today(),
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

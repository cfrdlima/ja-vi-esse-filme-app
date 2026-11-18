import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/firestore/user_data_write_lock.dart';
import '../../domain/entities/movie_copy.dart';
import '../../domain/entities/rating.dart';
import '../../domain/entities/shelf_entry.dart';
import '../../domain/entities/shelf_mark.dart';
import '../../domain/entities/shelf_movie.dart';
import '../../domain/entities/shelf_page.dart';
import '../../domain/entities/watched_on.dart';
import '../../domain/repositories/shelf_repository.dart';
import '../gateways/shelf_gateway.dart';
import '../models/shelf_movie_model.dart';

/// A Estante no Firestore, sempre no `uid` de quem está logado na hora da
/// chamada (decisão 013).
class FirestoreShelfRepository implements ShelfRepository {
  FirestoreShelfRepository({
    required this._gateway,
    required this._currentUid,
    required this._writeLock,
  });

  final ShelfGateway _gateway;

  /// Ligada pela exclusão da conta enquanto ela apaga os documentos.
  final UserDataWriteLock _writeLock;

  /// Nulo sem ninguém logado.
  final String? Function() _currentUid;

  @override
  Stream<ShelfEntry> watchMovie(int movieId) {
    final uid = _currentUid();
    if (uid == null) return Stream.error(const SignInRequiredFailure());
    // O model monta um `MovieCopy`, que lançaria `ArgumentError` cru no
    // stream; um id fora das regras nunca tem documento.
    if (movieId < 1 || movieId > MovieCopy.maxMovieId) {
      return Stream.error(const UnexpectedFailure('movieId fora das regras'));
    }
    return _track(
      _gateway
          .watchMovie(uid, movieId)
          .transform(
            StreamTransformer<Map<String, Object?>, ShelfEntry>.fromHandlers(
              handleData: (data, sink) {
                try {
                  sink.add(ShelfMovieModel.fromDocument(movieId, data));
                } on FormatException {
                  sink.addError(
                    const UnexpectedFailure('documento do filme ilegível'),
                  );
                }
              },
              handleError: _translateError,
            ),
          ),
    );
  }

  @override
  Stream<ShelfPage> watchShelf(ShelfMark mark, {required int limit}) {
    if (limit < 1) throw ArgumentError.value(limit, 'limit', 'menor que 1');
    final uid = _currentUid();
    if (uid == null) return Stream.error(const SignInRequiredFailure());
    return _track(
      _gateway
          .watchShelf(uid, ShelfMovieModel.fieldOf(mark), limit)
          .transform(
            StreamTransformer<List<ShelfDocument>, ShelfPage>.fromHandlers(
              handleData: (documents, sink) =>
                  sink.add(ShelfMovieModel.pageFrom(documents, limit: limit)),
              handleError: _translateError,
            ),
          ),
    );
  }

  static void _translateError<T>(
    Object error,
    StackTrace stackTrace,
    EventSink<T> sink,
  ) => sink.addError(_toFailure(error), stackTrace);

  /// Contado só com alguém ouvindo: antes disso, o Firestore nem foi
  /// assinado, e não há o que fechar.
  Stream<T> _track<T>(Stream<T> source) {
    late final _OpenWatch<T> watch;
    watch = _OpenWatch(
      source,
      onStart: () => _openWatches.add(watch),
      onEnd: () => _openWatches.remove(watch),
    );
    return watch.stream;
  }

  final Set<_OpenWatch<Object?>> _openWatches = {};

  @visibleForTesting
  int get openStreamCount => _openWatches.length;

  /// Além do contrato, o Firestore deixa de ser ouvido antes do
  /// `terminate()`.
  @override
  Future<void> closeStreams() async {
    final open = [..._openWatches];
    _openWatches.clear();
    for (final watch in open) {
      await watch.close();
    }
  }

  @override
  Future<void> addMark(MovieCopy copy, ShelfMark mark) => _write(
    (uid) => _gateway.mergeMovie(
      uid,
      copy.movieId,
      ShelfMovieModel.markFields(copy, mark),
    ),
  );

  @override
  Future<void> removeMark(ShelfMovie movie, ShelfMark mark) => _write((uid) {
    final movieId = movie.copy.movieId;
    if (movie.marksWithout(mark).isEmpty) return _delete(uid, movieId);
    return _unmark(uid, movieId, mark);
  });

  /// O [movie] do aparelho pode estar velho (decisão 013, corrida aceita).
  /// Se no servidor a [mark] já era a única, as regras negam o documento sem
  /// marcas, e o delete termina o que o desmarcar queria.
  Future<void> _unmark(String uid, int movieId, ShelfMark mark) async {
    try {
      await _gateway.updateMovie(
        uid,
        movieId,
        ShelfMovieModel.unmarkFields(mark),
      );
    } on FirebaseException catch (e) {
      switch (e.code) {
        case 'not-found':
          return;
        case 'permission-denied':
          return _delete(uid, movieId);
        default:
          rethrow;
      }
    }
  }

  /// Um documento que já sumiu (outro aparelho tirou a última marca) é o
  /// que o desmarcar queria.
  Future<void> _delete(String uid, int movieId) async {
    try {
      await _gateway.deleteMovie(uid, movieId);
    } on FirebaseException catch (e) {
      if (e.code != 'not-found') rethrow;
    }
  }

  @override
  Future<void> renewCopy(MovieCopy copy) => _write(
    // O filme saiu da Estante enquanto a cópia nova vinha do TMDB.
    (uid) =>
        _updateIfPresent(uid, copy.movieId, ShelfMovieModel.copyFields(copy)),
  );

  @override
  Future<void> rate(ShelfMovie movie, Rating rating) =>
      _writePersonal(movie, ShelfMovieModel.ratingFields(rating));

  @override
  Future<void> clearRating(ShelfMovie movie) =>
      _writePersonal(movie, ShelfMovieModel.noRatingFields());

  @override
  Future<void> setWatchedOn(ShelfMovie movie, WatchedOn day) =>
      _writePersonal(movie, ShelfMovieModel.watchedOnFields(day));

  @override
  Future<void> clearWatchedOn(ShelfMovie movie) =>
      _writePersonal(movie, ShelfMovieModel.noWatchedOnFields());

  /// A nota e o dia só existem com o Assistido (decisão 018). O `update`
  /// não recria o documento de um filme que saiu da Estante.
  Future<void> _writePersonal(
    ShelfMovie movie,
    Map<String, FieldWrite> fields,
  ) async {
    if (!movie.isMarked(ShelfMark.watched)) {
      throw ArgumentError('nota e dia só no filme assistido', 'movie');
    }
    return _write((uid) => _updateIfPresent(uid, movie.copy.movieId, fields));
  }

  Future<void> _updateIfPresent(
    String uid,
    int movieId,
    Map<String, FieldWrite> fields,
  ) async {
    try {
      await _gateway.updateMovie(uid, movieId, fields);
    } on FirebaseException catch (e) {
      if (e.code != 'not-found') rethrow;
    }
  }

  /// Um `Error` é bug e sobe como está, para o relatório de erros.
  Future<void> _write(Future<void> Function(String uid) write) async {
    final uid = _currentUid();
    if (uid == null) throw const SignInRequiredFailure();
    if (_writeLock.isLocked) {
      throw const UnexpectedFailure('shelf: exclusão da conta em andamento');
    }
    try {
      await write(uid);
    } on Exception catch (error) {
      throw _toFailure(error);
    }
  }
}

// Só o `code` vai para a falha: a `message` da `FirebaseException` pode
// trazer o caminho do documento, com o `uid`.
Failure _toFailure(Object error) => switch (error) {
  FirebaseException(code: 'unavailable' || 'deadline-exceeded') =>
    const NetworkFailure(),
  FirebaseException(code: 'resource-exhausted') => const RateLimitFailure(),
  FirebaseException(code: 'unauthenticated') => const SignInRequiredFailure(),
  FirebaseException(:final code) => UnexpectedFailure('cloud_firestore: $code'),
  _ => const UnexpectedFailure('erro fora do Firestore na Estante'),
};

/// Um stream do `watchMovie` ou do `watchShelf` que o
/// [FirestoreShelfRepository.closeStreams] consegue encerrar por fora.
final class _OpenWatch<T> {
  _OpenWatch(
    Stream<T> source, {
    required void Function() onStart,
    required this._onEnd,
  }) {
    _controller = StreamController<T>(
      onListen: () {
        onStart();
        _subscription = source.listen(
          _controller.add,
          onError: _controller.addError,
          onDone: _end,
        );
      },
      onCancel: () {
        _onEnd();
        return _subscription?.cancel();
      },
    );
  }

  late final StreamController<T> _controller;
  StreamSubscription<T>? _subscription;
  final void Function() _onEnd;

  Stream<T> get stream => _controller.stream;

  void _end() {
    _onEnd();
    unawaited(_controller.close());
  }

  /// Para de ouvir o Firestore, que é o que o `terminate()` precisa. O fim
  /// do stream não é esperado: com quem ouve pausado, ele só chegaria na
  /// retomada, e o logout ficaria preso.
  Future<void> close() async {
    final subscription = _subscription;
    _subscription = null;
    await subscription?.cancel();
    unawaited(_controller.close());
  }
}

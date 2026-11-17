import 'dart:async';

import 'package:firebase_core/firebase_core.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/movie_copy.dart';
import '../../domain/entities/shelf_entry.dart';
import '../../domain/entities/shelf_mark.dart';
import '../../domain/entities/shelf_movie.dart';
import '../../domain/repositories/shelf_repository.dart';
import '../gateways/shelf_gateway.dart';
import '../models/shelf_movie_model.dart';

/// A Estante no Firestore, sempre no `uid` de quem está logado na hora da
/// chamada (decisão 013).
class FirestoreShelfRepository implements ShelfRepository {
  FirestoreShelfRepository({required this._gateway, required this._currentUid});

  final ShelfGateway _gateway;

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
    final source = _gateway
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
            handleError: (error, stackTrace, sink) =>
                sink.addError(_toFailure(error), stackTrace),
          ),
        );
    final watch = _OpenWatch(source);
    _openWatches.add(watch);
    watch.onEnd = () => _openWatches.remove(watch);
    return watch.stream;
  }

  final Set<_OpenWatch> _openWatches = {};

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

  /// Um `Error` é bug e sobe como está, para o relatório de erros.
  Future<void> _write(Future<void> Function(String uid) write) async {
    final uid = _currentUid();
    if (uid == null) throw const SignInRequiredFailure();
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

/// Um stream do `watchMovie` que o [FirestoreShelfRepository.closeStreams]
/// consegue encerrar por fora.
final class _OpenWatch {
  _OpenWatch(Stream<ShelfEntry> source) {
    _controller = StreamController<ShelfEntry>(
      onListen: () => _subscription = source.listen(
        _controller.add,
        onError: _controller.addError,
        onDone: _end,
      ),
      onCancel: () {
        onEnd?.call();
        return _subscription?.cancel();
      },
    );
  }

  late final StreamController<ShelfEntry> _controller;
  StreamSubscription<ShelfEntry>? _subscription;
  void Function()? onEnd;

  Stream<ShelfEntry> get stream => _controller.stream;

  void _end() {
    onEnd?.call();
    unawaited(_controller.close());
  }

  Future<void> close() async {
    await _subscription?.cancel();
    _subscription = null;
    // Sem ouvinte, o `close()` nunca completaria.
    if (_controller.hasListener) {
      await _controller.close();
    } else {
      unawaited(_controller.close());
    }
  }
}

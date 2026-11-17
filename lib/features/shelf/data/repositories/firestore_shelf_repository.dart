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
    return _gateway
        .watchMovie(uid, movieId)
        .transform(
          StreamTransformer.fromHandlers(
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
    if (movie.marksWithout(mark).isEmpty) {
      return _gateway.deleteMovie(uid, movieId);
    }
    return _gateway.updateMovie(
      uid,
      movieId,
      ShelfMovieModel.unmarkFields(mark),
    );
  });

  Future<void> _write(Future<void> Function(String uid) write) async {
    final uid = _currentUid();
    if (uid == null) throw const SignInRequiredFailure();
    try {
      await write(uid);
    } on FirebaseException catch (e) {
      // O documento já sumiu (outro aparelho tirou a última marca): o filme
      // já está fora da Estante, que é o que o desmarcar queria.
      if (e.code == 'not-found') return;
      throw _toFailure(e);
    } on Object catch (error) {
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

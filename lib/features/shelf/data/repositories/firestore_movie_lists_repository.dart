import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/firestore/user_data_write_lock.dart';
import '../../domain/entities/list_name.dart';
import '../../domain/entities/movie_copy.dart';
import '../../domain/entities/movie_list.dart';
import '../../domain/entities/shelf_entry.dart';
import '../../domain/entities/shelf_movie.dart';
import '../../domain/entities/shelf_page.dart';
import '../../domain/repositories/movie_lists_repository.dart';
import '../gateways/movie_lists_gateway.dart';
import '../gateways/shelf_gateway.dart';
import '../models/movie_list_model.dart';
import '../models/shelf_movie_model.dart';
import 'firestore_support.dart';

/// As listas no Firestore (decisão 019), sempre no `uid` de quem está logado
/// na hora da chamada. As escritas num filme vão pelo mesmo [ShelfGateway]
/// da Estante, porque o vínculo é um campo do documento do filme.
class FirestoreMovieListsRepository implements MovieListsRepository {
  FirestoreMovieListsRepository({
    required this._lists,
    required this._movies,
    required this._currentUid,
    required this._writeLock,
  });

  final MovieListsGateway _lists;
  final ShelfGateway _movies;

  /// Nulo sem ninguém logado.
  final String? Function() _currentUid;

  /// Ligada pela exclusão da conta enquanto ela apaga os documentos.
  final UserDataWriteLock _writeLock;

  /// O mesmo `syncTimeout` do logout (sessão 022): depois disso, a contagem
  /// sai do aparelho.
  static const countTimeout = Duration(seconds: 5);

  /// O prazo de cada passo da exclusão da conta (decisão 015).
  static const stepTimeout = Duration(seconds: 15);

  /// O máximo de escritas num `WriteBatch`.
  static const batchSize = 500;

  final _watches = OpenWatches();

  @visibleForTesting
  int get openStreamCount => _watches.count;

  @override
  Stream<List<MovieList>> watchLists() {
    final uid = _currentUid();
    if (uid == null) return Stream.error(const SignInRequiredFailure());
    return _watches.track(
      _lists
          .watchLists(uid, MovieList.maxPerAccount + 1)
          .transform(
            StreamTransformer<
              List<ShelfDocument>,
              List<MovieList>
            >.fromHandlers(
              handleData: (documents, sink) =>
                  sink.add(MovieListModel.listsFrom(documents)),
              handleError: _translateError,
            ),
          ),
    );
  }

  @override
  Stream<ShelfPage> watchList(MovieList list, {required int limit}) {
    if (limit < 1) throw ArgumentError.value(limit, 'limit', 'menor que 1');
    final uid = _currentUid();
    if (uid == null) return Stream.error(const SignInRequiredFailure());
    return _watches.track(
      _movies
          .watchShelf(uid, ShelfMovieModel.listOrderField(list.id), limit)
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
  ) => sink.addError(firestoreFailure(error), stackTrace);

  @override
  Future<void> closeStreams() => _watches.closeAll();

  @override
  MovieList newList(ListName name) {
    final uid = _currentUid();
    if (uid == null) throw const SignInRequiredFailure();
    return MovieList(id: _lists.newListId(uid), name: name);
  }

  @override
  Future<int> countLists() =>
      _count(_lists.countListsOnServer, _lists.countListsInCache);

  @override
  Future<int> countMovies(MovieList list) {
    final field = ShelfMovieModel.listOrderField(list.id);
    return _count(
      (uid) => _lists.countMoviesOnServer(uid, field),
      (uid) => _lists.countMoviesInCache(uid, field),
    );
  }

  /// O `count()` só existe no servidor. Sem rede ou com o servidor lento, a
  /// conta sai do cache do aparelho, que é o que a pessoa vê.
  Future<int> _count(
    Future<int> Function(String uid) onServer,
    Future<int> Function(String uid) inCache,
  ) async {
    final uid = _currentUid();
    if (uid == null) throw const SignInRequiredFailure();
    try {
      try {
        return await onServer(uid).timeout(countTimeout);
      } on TimeoutException {
        return await inCache(uid);
      } on FirebaseException catch (e) {
        if (firestoreFailure(e) is! NetworkFailure) rethrow;
        return await inCache(uid);
      }
    } on Exception catch (error) {
      throw firestoreFailure(error);
    }
  }

  @override
  Future<void> createList(MovieList list) => _write(
    (uid) => _lists.setList(uid, list.id, MovieListModel.nameFields(list.name)),
  );

  @override
  Future<void> renameList(MovieList list, ListName name) => _write((uid) async {
    try {
      await _lists.updateList(uid, list.id, MovieListModel.nameFields(name));
    } on FirebaseException catch (e) {
      // A lista foi apagada em outro aparelho.
      if (e.code != 'not-found') rethrow;
    }
  });

  @override
  Future<void> addToList(MovieCopy copy, MovieList list) => _write(
    (uid) => _movies.mergeMovie(
      uid,
      copy.movieId,
      ShelfMovieModel.addToListFields(copy, list.id),
    ),
  );

  @override
  Future<void> removeFromList(ShelfMovie movie, MovieList list) =>
      _write((uid) {
        final movieId = movie.copy.movieId;
        if (!movie.staysWithoutList(list.id)) return _delete(uid, movieId);
        return _removeKey(uid, movie, list.id);
      });

  /// O [movie] do aparelho pode estar velho. Se as regras recusam, a escrita
  /// foi montada com listas que o servidor já não tem (o mapa ficaria vazio,
  /// ou mudariam duas chaves): apagar levaria as marcas, a nota e o dia. O
  /// filme é relido do servidor, e a escrita, refeita com ele (`/revisar` da
  /// sessão 029).
  Future<void> _removeKey(String uid, ShelfMovie movie, String listId) async {
    final movieId = movie.copy.movieId;
    try {
      await _movies.updateMovie(
        uid,
        movieId,
        ShelfMovieModel.removeFromListFields(movie, listId),
      );
    } on FirebaseException catch (e) {
      switch (e.code) {
        case 'not-found':
          return;
        case 'permission-denied':
          return _removeKeyFromServer(uid, movieId, listId);
        default:
          rethrow;
      }
    }
  }

  Future<void> _removeKeyFromServer(
    String uid,
    int movieId,
    String listId,
  ) async {
    final fields = await _step(_lists.fetchMovieFromServer(uid, movieId));
    final ShelfMovie fresh;
    try {
      switch (ShelfMovieModel.fromDocument(movieId, fields)) {
        case OnShelf(:final movie) when movie.isInList(listId):
          fresh = movie;
        case _:
          // O filme já saiu da lista, ou do servidor.
          return;
      }
    } on FormatException {
      // Sem título legível, o update seria recusado de novo.
      return _delete(uid, movieId);
    }
    if (!fresh.staysWithoutList(listId)) return _delete(uid, movieId);
    await _movies.updateMovie(
      uid,
      movieId,
      ShelfMovieModel.removeFromListFields(fresh, listId),
    );
  }

  Future<void> _delete(String uid, int movieId) async {
    try {
      await _movies.deleteMovie(uid, movieId);
    } on FirebaseException catch (e) {
      if (e.code != 'not-found') rethrow;
    }
  }

  /// Tira a lista dos filmes lidos do servidor, em lotes, até a leitura
  /// voltar vazia, e só então apaga a lista (decisão 019).
  @override
  Future<void> deleteList(MovieList list) => _write((uid) async {
    final field = ShelfMovieModel.listOrderField(list.id);
    while (true) {
      final documents = await _step(
        _lists.fetchMoviesFromServer(uid, field, batchSize),
      );
      if (documents.isEmpty) break;
      await _step(
        _lists.commitMovies(uid, [
          for (final document in documents) _removal(document, list.id),
        ]),
      );
    }
    await _step(_lists.deleteList(uid, list.id));
  });

  static Future<T> _step<T>(Future<T> step) =>
      step.timeout(stepTimeout, onTimeout: () => throw const NetworkFailure());

  /// Um documento sem marca nem outra lista, ou ilegível (as regras o
  /// recusariam num update), é apagado; senão, só a lista sai.
  static MovieBatchWrite _removal(ShelfDocument document, String listId) {
    final movieId = int.tryParse(document.id);
    if (movieId == null) {
      throw const UnexpectedFailure('lista: id de filme fora das regras');
    }
    try {
      if (ShelfMovieModel.fromDocument(movieId, document.fields) case OnShelf(
        :final movie,
      ) when movie.staysWithoutList(listId)) {
        return UpdateMovieInBatch(
          movieId,
          ShelfMovieModel.removeFromListFields(movie, listId),
        );
      }
    } on FormatException {
      // Sem título legível: cai no delete.
    }
    return DeleteMovieInBatch(movieId);
  }

  /// Um `Error` é bug e sobe como está, para o relatório de erros.
  Future<void> _write(Future<void> Function(String uid) write) async {
    final uid = _currentUid();
    if (uid == null) throw const SignInRequiredFailure();
    if (_writeLock.isLocked) {
      throw const UnexpectedFailure('lists: exclusão da conta em andamento');
    }
    try {
      await write(uid);
    } on Failure {
      rethrow;
    } on Exception catch (error) {
      throw firestoreFailure(error);
    }
  }
}

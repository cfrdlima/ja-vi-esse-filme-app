import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/firestore/user_collections.dart';
import 'firestore_fields.dart';
import 'movie_lists_gateway.dart';
import 'shelf_gateway.dart';

/// O [MovieListsGateway] sobre o `cloud_firestore`. Fino de propósito: a
/// regra fica no model e no repositório, testados com fakes (decisão 019).
class CloudFirestoreMovieListsGateway implements MovieListsGateway {
  CloudFirestoreMovieListsGateway({required this._firestore});

  final FirebaseFirestore _firestore;

  // Pelo `doc(uid)`, e não por um caminho montado em texto, como na
  // Estante.
  DocumentReference<Map<String, dynamic>> _user(String uid) =>
      _firestore.collection(UserCollections.users).doc(uid);

  CollectionReference<Map<String, dynamic>> _lists(String uid) =>
      _user(uid).collection(UserCollections.lists);

  CollectionReference<Map<String, dynamic>> _movies(String uid) =>
      _user(uid).collection(UserCollections.movies);

  /// O `orderBy` deixa de fora os filmes sem o campo, como nas abas.
  Query<Map<String, dynamic>> _inList(String uid, String orderField) =>
      _movies(uid).orderBy(orderField, descending: true);

  @override
  Stream<List<ShelfDocument>> watchLists(String uid, int limit) =>
      _lists(uid).limit(limit).snapshots().map(_documentsOf);

  @override
  String newListId(String uid) => _lists(uid).doc().id;

  @override
  Future<int> countListsOnServer(String uid) async =>
      (await _lists(uid).count().get()).count ?? 0;

  @override
  Future<int> countListsInCache(String uid) async =>
      (await _lists(uid).get(const GetOptions(source: Source.cache))).size;

  @override
  Future<int> countMoviesOnServer(String uid, String orderField) async =>
      (await _inList(uid, orderField).count().get()).count ?? 0;

  @override
  Future<int> countMoviesInCache(String uid, String orderField) async =>
      (await _inList(
        uid,
        orderField,
      ).get(const GetOptions(source: Source.cache))).size;

  @override
  Future<void> setList(
    String uid,
    String listId,
    Map<String, FieldWrite> fields,
  ) => _lists(uid).doc(listId).set(FirestoreFields.write(fields));

  @override
  Future<void> updateList(
    String uid,
    String listId,
    Map<String, FieldWrite> fields,
  ) => _lists(uid).doc(listId).update(FirestoreFields.write(fields));

  @override
  Future<void> deleteList(String uid, String listId) =>
      _lists(uid).doc(listId).delete();

  /// Do servidor, nunca do cache: um filme que só o servidor tem ficaria
  /// com a chave da lista apagada.
  @override
  Future<List<ShelfDocument>> fetchMoviesFromServer(
    String uid,
    String orderField,
    int limit,
  ) async {
    final query = await _inList(
      uid,
      orderField,
    ).limit(limit).get(const GetOptions(source: Source.server));
    return _documentsOf(query);
  }

  /// O `commit()` só completa quando o servidor confirma.
  @override
  Future<void> commitMovies(String uid, List<MovieBatchWrite> writes) {
    final batch = _firestore.batch();
    for (final write in writes) {
      final movie = _movies(uid).doc('${write.movieId}');
      switch (write) {
        case UpdateMovieInBatch(:final fields):
          batch.update(movie, FirestoreFields.write(fields));
        case DeleteMovieInBatch():
          batch.delete(movie);
      }
    }
    return batch.commit();
  }

  static List<ShelfDocument> _documentsOf(
    QuerySnapshot<Map<String, dynamic>> query,
  ) => [
    for (final document in query.docs)
      (
        id: document.id,
        fields: FirestoreFields.read(
          document.data(),
          pendingAt: document.metadata.hasPendingWrites
              ? DateTime.now().toUtc()
              : null,
        ),
      ),
  ];
}

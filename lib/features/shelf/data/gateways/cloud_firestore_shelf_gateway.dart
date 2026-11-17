import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_fields.dart';
import 'shelf_gateway.dart';

/// O [ShelfGateway] sobre o `cloud_firestore`. Fino de propósito: a regra
/// fica no model e no repositório, que são testados com fakes (decisão 013).
class CloudFirestoreShelfGateway implements ShelfGateway {
  CloudFirestoreShelfGateway({required this._firestore});

  final FirebaseFirestore _firestore;

  // Pelo `doc(uid)`, e não por um caminho montado em texto: o `AppUser` já
  // recusa `uid` com barra (sessão 019).
  CollectionReference<Map<String, dynamic>> _movies(String uid) =>
      _firestore.collection('users').doc(uid).collection('movies');

  DocumentReference<Map<String, dynamic>> _movie(String uid, int movieId) =>
      _movies(uid).doc('$movieId');

  /// Só o `orderBy`, sem `where`: o Firestore deixa de fora o documento sem
  /// o campo ordenado, e o `isNotEqualTo: null` da 7.1.0 é ignorado em
  /// silêncio (sessão 023).
  @override
  Stream<List<ShelfDocument>> watchShelf(
    String uid,
    String orderField,
    int limit,
  ) => _movies(uid)
      .orderBy(orderField, descending: true)
      .limit(limit)
      .snapshots()
      .map(
        (query) => [
          for (final document in query.docs)
            (id: document.id, fields: _fieldsOf(document)),
        ],
      );

  @override
  Stream<Map<String, Object?>> watchMovie(String uid, int movieId) =>
      _movie(uid, movieId).snapshots().map(_fieldsOf);

  @override
  Future<void> mergeMovie(
    String uid,
    int movieId,
    Map<String, FieldWrite> fields,
  ) => _movie(
    uid,
    movieId,
  ).set(FirestoreFields.write(fields), SetOptions(merge: true));

  @override
  Future<void> updateMovie(
    String uid,
    int movieId,
    Map<String, FieldWrite> fields,
  ) => _movie(uid, movieId).update(FirestoreFields.write(fields));

  @override
  Future<void> deleteMovie(String uid, int movieId) =>
      _movie(uid, movieId).delete();

  static Map<String, Object?> _fieldsOf(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) => FirestoreFields.read(
    snapshot.data(),
    pendingAt: snapshot.metadata.hasPendingWrites
        ? DateTime.now().toUtc()
        : null,
  );
}

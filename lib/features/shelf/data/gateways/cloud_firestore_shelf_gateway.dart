import 'package:cloud_firestore/cloud_firestore.dart';

import 'shelf_gateway.dart';

/// O [ShelfGateway] sobre o `cloud_firestore`. Fino de propósito: a regra
/// fica no model e no repositório, que são testados com fakes (decisão 013).
class CloudFirestoreShelfGateway implements ShelfGateway {
  CloudFirestoreShelfGateway({required this._firestore});

  final FirebaseFirestore _firestore;

  // Pelo `doc(uid)`, e não por um caminho montado em texto: o `AppUser` já
  // recusa `uid` com barra (sessão 019).
  DocumentReference<Map<String, dynamic>> _movie(String uid, int movieId) =>
      _firestore
          .collection('users')
          .doc(uid)
          .collection('movies')
          .doc('$movieId');

  @override
  Stream<Map<String, Object?>> watchMovie(String uid, int movieId) =>
      _movie(uid, movieId).snapshots().map(_fieldsOf);

  @override
  Future<void> mergeMovie(
    String uid,
    int movieId,
    Map<String, FieldWrite> fields,
  ) => _movie(uid, movieId).set(_toSdk(fields), SetOptions(merge: true));

  @override
  Future<void> updateMovie(
    String uid,
    int movieId,
    Map<String, FieldWrite> fields,
  ) => _movie(uid, movieId).update(_toSdk(fields));

  @override
  Future<void> deleteMovie(String uid, int movieId) =>
      _movie(uid, movieId).delete();

  /// Uma data do servidor ainda pendente chega como `null`, e o `snapshots()`
  /// público não aceita o `ServerTimestampBehavior.estimate`. Com escrita
  /// pendente, o `null` vira a hora local; as regras nunca deixam um `null`
  /// gravado de verdade.
  static Map<String, Object?> _fieldsOf(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final pending = snapshot.metadata.hasPendingWrites;
    return {
      for (final MapEntry(:key, :value) in (snapshot.data() ?? {}).entries)
        key: switch (value) {
          final Timestamp at => at.toDate().toUtc(),
          null when pending => DateTime.now().toUtc(),
          _ => value,
        },
    };
  }

  static Map<String, Object> _toSdk(Map<String, FieldWrite> fields) => {
    for (final MapEntry(:key, :value) in fields.entries)
      key: switch (value) {
        SetField(:final value) => value,
        ServerTime() => FieldValue.serverTimestamp(),
        DeleteField() => FieldValue.delete(),
      },
  };
}

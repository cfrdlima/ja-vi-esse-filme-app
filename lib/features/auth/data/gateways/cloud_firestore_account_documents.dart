import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/firestore/user_collections.dart';
import 'firestore_account_documents.dart';

/// As chamadas do `cloud_firestore` para o [FirestoreAccountDocuments], sem
/// regra: o laço e o prazo ficam nele, testados com fakes.
FirestoreAccountDocuments cloudFirestoreAccountDocuments(
  FirebaseFirestore firestore,
) {
  // Pelo `doc(uid)`, e não por um caminho montado em texto: o `AppUser` já
  // recusa `uid` com barra (sessão 019).
  CollectionReference<Map<String, dynamic>> subcollection(
    String uid,
    String collection,
  ) => firestore
      .collection(UserCollections.users)
      .doc(uid)
      .collection(collection);

  return FirestoreAccountDocuments(
    collections: UserCollections.all,
    // Do servidor, nunca do cache: um documento que só o servidor tem
    // sobraria depois da exclusão. Offline, falha com `unavailable`.
    fetchIds: (uid, collection, limit) async {
      final query = await subcollection(
        uid,
        collection,
      ).limit(limit).get(const GetOptions(source: Source.server));
      return [for (final document in query.docs) document.id];
    },
    // O `commit()` só completa quando o servidor confirma.
    delete: (uid, collection, ids) {
      final documents = subcollection(uid, collection);
      final batch = firestore.batch();
      for (final id in ids) {
        batch.delete(documents.doc(id));
      }
      return batch.commit();
    },
  );
}

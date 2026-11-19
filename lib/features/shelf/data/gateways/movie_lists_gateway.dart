import 'shelf_gateway.dart';

/// Uma escrita no lote que tira uma lista dos filmes (decisão 019).
sealed class MovieBatchWrite {
  const MovieBatchWrite(this.movieId);

  final int movieId;
}

final class UpdateMovieInBatch extends MovieBatchWrite {
  const UpdateMovieInBatch(super.movieId, this.fields);

  final Map<String, FieldWrite> fields;

  @override
  bool operator ==(Object other) =>
      other is UpdateMovieInBatch &&
      other.movieId == movieId &&
      other.fields.length == fields.length &&
      fields.entries.every((e) => other.fields[e.key] == e.value);

  @override
  int get hashCode => Object.hash(
    movieId,
    Object.hashAllUnordered(fields.entries.map((e) => (e.key, e.value))),
  );

  @override
  String toString() => 'UpdateMovieInBatch($movieId, $fields)';
}

final class DeleteMovieInBatch extends MovieBatchWrite {
  const DeleteMovieInBatch(super.movieId);

  @override
  bool operator ==(Object other) =>
      other is DeleteMovieInBatch && other.movieId == movieId;

  @override
  int get hashCode => movieId.hashCode;

  @override
  String toString() => 'DeleteMovieInBatch($movieId)';
}

/// Fachada fina sobre o `cloud_firestore` para as listas (decisão 019):
/// `users/{uid}/lists/{listId}` e as leituras de `users/{uid}/movies` que
/// só as listas fazem. As escritas num filme só vão pelo [ShelfGateway].
/// Repassa as exceções do SDK sem traduzir, como ele.
abstract interface class MovieListsGateway {
  /// As listas da conta ao assinar e a cada mudança, até o [limit].
  Stream<List<ShelfDocument>> watchLists(String uid, int limit);

  /// Um id automático novo (`doc()`), sem gravar nada.
  String newListId(String uid);

  /// Contagem do servidor (`count()`), que falha offline.
  Future<int> countListsOnServer(String uid);

  /// Contagem do cache do aparelho, que funciona offline.
  Future<int> countListsInCache(String uid);

  /// Quantos filmes têm o campo [orderField], do servidor.
  Future<int> countMoviesOnServer(String uid, String orderField);

  /// Quantos filmes têm o campo [orderField], do cache do aparelho.
  Future<int> countMoviesInCache(String uid, String orderField);

  /// `set` sem `merge`: o documento da lista tem só o nome.
  Future<void> setList(
    String uid,
    String listId,
    Map<String, FieldWrite> fields,
  );

  /// `update`: falha com `not-found` se a lista não existir.
  Future<void> updateList(
    String uid,
    String listId,
    Map<String, FieldWrite> fields,
  );

  Future<void> deleteList(String uid, String listId);

  /// Os filmes com o campo [orderField], lidos do servidor (nunca do cache),
  /// até o [limit]. Offline, falha com `unavailable`.
  Future<List<ShelfDocument>> fetchMoviesFromServer(
    String uid,
    String orderField,
    int limit,
  );

  /// Os campos do filme lidos do servidor (nunca do cache), como o
  /// [ShelfGateway.watchMovie] os entrega; vazio sem documento. Offline,
  /// falha com `unavailable`.
  Future<Map<String, Object?>> fetchMovieFromServer(String uid, int movieId);

  /// Um `WriteBatch` com as [writes], que só completa quando o servidor
  /// confirma.
  Future<void> commitMovies(String uid, List<MovieBatchWrite> writes);
}

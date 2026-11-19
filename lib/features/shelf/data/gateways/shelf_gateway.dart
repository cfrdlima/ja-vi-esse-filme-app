/// Um campo a escrever no documento, sem o `FieldValue` do SDK: o model
/// monta a escrita e é testado sem o Firestore.
sealed class FieldWrite {
  const FieldWrite();
}

final class SetField extends FieldWrite {
  const SetField(this.value);

  final Object value;

  @override
  bool operator ==(Object other) => other is SetField && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'SetField($value)';
}

/// A hora do servidor (`FieldValue.serverTimestamp()`), a única que as
/// regras aceitam nas datas (decisão 013).
final class ServerTime extends FieldWrite {
  const ServerTime();

  @override
  bool operator ==(Object other) => other is ServerTime;

  @override
  int get hashCode => (ServerTime).hashCode;

  @override
  String toString() => 'ServerTime()';
}

/// Um mapa com as próprias escritas, como o `lists` do filme (decisão 019):
/// com `merge`, as chaves que ficam de fora não mudam.
final class MapFields extends FieldWrite {
  const MapFields(this.fields);

  final Map<String, FieldWrite> fields;

  @override
  bool operator ==(Object other) =>
      other is MapFields &&
      other.fields.length == fields.length &&
      fields.entries.every((e) => other.fields[e.key] == e.value);

  @override
  int get hashCode => Object.hashAllUnordered(
    fields.entries.map((e) => (e.key, e.value)),
  );

  @override
  String toString() => 'MapFields($fields)';
}

/// Remove o campo (`FieldValue.delete()`).
final class DeleteField extends FieldWrite {
  const DeleteField();

  @override
  bool operator ==(Object other) => other is DeleteField;

  @override
  int get hashCode => (DeleteField).hashCode;

  @override
  String toString() => 'DeleteField()';
}

/// Um documento de `users/{uid}/movies`: o id (o do filme no TMDB, em
/// texto) e os campos, já como o [ShelfGateway.watchMovie] os entrega.
typedef ShelfDocument = ({String id, Map<String, Object?> fields});

/// Fachada fina sobre o `cloud_firestore` em `users/{uid}/movies/{movieId}`,
/// para o repositório ser testado com fakes (decisão 013). Repassa as
/// exceções do SDK (`FirebaseException`) sem traduzir: a tradução é do
/// repositório.
abstract interface class ShelfGateway {
  /// Emite os campos do documento ao assinar e a cada mudança, com as datas
  /// já em `DateTime` (UTC). Uma data do servidor ainda pendente (escrita
  /// offline) vem estimada, e não nula. Sem documento, emite o mapa vazio.
  Stream<Map<String, Object?>> watchMovie(String uid, int movieId);

  /// Os documentos com o campo [orderField], do maior para o menor valor,
  /// até o [limit], ao assinar e a cada mudança. As datas vêm como no
  /// [watchMovie].
  Stream<List<ShelfDocument>> watchShelf(
    String uid,
    String orderField,
    int limit,
  );

  /// `set` com `merge`: cria o documento ou mescla os campos.
  Future<void> mergeMovie(
    String uid,
    int movieId,
    Map<String, FieldWrite> fields,
  );

  /// `update`: falha com `not-found` se o documento não existir.
  Future<void> updateMovie(
    String uid,
    int movieId,
    Map<String, FieldWrite> fields,
  );

  Future<void> deleteMovie(String uid, int movieId);
}

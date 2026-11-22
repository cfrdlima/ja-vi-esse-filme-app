import 'package:cloud_firestore/cloud_firestore.dart';

import 'shelf_gateway.dart';

/// As conversões entre os valores do `cloud_firestore` e os do
/// [ShelfGateway], fora do gateway para serem testadas sem o SDK rodando.
abstract final class FirestoreFields {
  /// Os campos lidos de um documento, com as datas em `DateTime` UTC. Sem
  /// documento ([data] nula), devolve o mapa vazio.
  ///
  /// Uma data do servidor ainda pendente chega como `null`, e o
  /// `snapshots()` público da 7.1.0 não aceita o
  /// `ServerTimestampBehavior.estimate`. Com escrita pendente, [pendingAt]
  /// traz a hora local, que entra no lugar do `null`; sem escrita pendente,
  /// ele é nulo. As regras nunca deixam um `null` gravado de verdade.
  ///
  /// Os mapas (como o `lists` do filme, decisão 019) são lidos do mesmo
  /// jeito, um nível abaixo.
  static Map<String, Object?> read(
    Map<String, dynamic>? data, {
    required DateTime? pendingAt,
  }) => {
    for (final MapEntry(:key, :value) in (data ?? {}).entries)
      key: _readValue(value, pendingAt),
  };

  static Object? _readValue(Object? value, DateTime? pendingAt) =>
      switch (value) {
        final Timestamp at => at.toDate().toUtc(),
        null => pendingAt,
        final Map<Object?, Object?> map => {
          for (final MapEntry(:key, :value) in map.entries)
            '$key': _readValue(value, pendingAt),
        },
        _ => value,
      };

  static Map<String, Object> write(Map<String, FieldWrite> fields) => {
    for (final MapEntry(:key, :value) in fields.entries)
      key: switch (value) {
        SetField(:final value) => value,
        ServerTime() => FieldValue.serverTimestamp(),
        DeleteField() => FieldValue.delete(),
        MapFields(:final fields) => write(fields),
      },
  };
}

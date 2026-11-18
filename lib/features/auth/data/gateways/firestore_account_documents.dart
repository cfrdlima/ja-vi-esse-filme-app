import '../../domain/repositories/auth_repository.dart';
import 'auth_gateways.dart';

/// Lê os ids de até `limit` documentos de `users/{uid}/{collection}` no
/// servidor (`Source.server`), nunca no cache.
typedef FetchDocumentIds =
    Future<List<String>> Function(String uid, String collection, int limit);

/// Apaga os documentos num `WriteBatch` e completa quando o servidor
/// confirma o `commit()`.
typedef DeleteDocuments =
    Future<void> Function(String uid, String collection, List<String> ids);

/// Apaga em lotes, cada um esperando o servidor, até a leitura voltar vazia
/// (decisão 015). As chamadas do SDK vêm prontas do `main.dart`, para o laço
/// e o prazo serem testados sem o plugin, como no `FirestoreAccountCache`.
final class FirestoreAccountDocuments implements AccountDocumentsGateway {
  FirestoreAccountDocuments({
    required this._collections,
    required this._fetchIds,
    required this._delete,
  });

  final List<String> _collections;
  final FetchDocumentIds _fetchIds;
  final DeleteDocuments _delete;

  /// O máximo de escritas num `WriteBatch`.
  static const batchLimit = 500;

  @override
  Future<void> deleteAll(String uid) async {
    for (final collection in _collections) {
      await _deleteCollection(uid, collection);
    }
  }

  // A leitura é do servidor, então um lote confirmado não volta na próxima.
  Future<void> _deleteCollection(String uid, String collection) async {
    while (true) {
      final ids = await _fetchIds(uid, collection, batchLimit).timeout(_step);
      if (ids.isEmpty) return;
      await _delete(uid, collection, ids).timeout(_step);
    }
  }

  static const _step = AuthRepository.deleteStepTimeout;
}

import 'auth_gateways.dart';

/// Limpa o cache do Firestore no logout, na ordem da decisão 010. Recebe as
/// chamadas do SDK prontas (montadas no `main.dart`), para a ordem ser
/// testada sem o plugin.
final class FirestoreAccountCache implements AccountCacheGateway {
  FirestoreAccountCache({
    required this._closeStreams,
    required this._terminate,
    required this._clearPersistence,
    required this._waitForPendingWrites,
  });

  final Future<void> Function() _closeStreams;
  final Future<void> Function() _terminate;
  final Future<void> Function() _clearPersistence;
  final Future<void> Function() _waitForPendingWrites;

  @override
  Future<void> waitForPendingWrites() => _waitForPendingWrites();

  /// No Android, o `terminate()` do plugin também tira a instância nativa
  /// do cache dele, e a próxima chamada cria uma nova: o "recriar a
  /// instância" da decisão 010 acontece sozinho (sessão 022, "Notas").
  @override
  Future<void> clear() async {
    await _closeStreams();
    await _terminate();
    await _clearPersistence();
  }
}

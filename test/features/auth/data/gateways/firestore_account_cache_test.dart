import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/features/auth/data/gateways/firestore_account_cache.dart';

void main() {
  late List<String> calls;
  Object? terminateError;

  FirestoreAccountCache cache() => FirestoreAccountCache(
    closeStreams: () async => calls.add('closeStreams'),
    terminate: () async {
      calls.add('terminate');
      if (terminateError case final Object error) throw error;
    },
    clearPersistence: () async => calls.add('clearPersistence'),
    waitForPendingWrites: () async => calls.add('waitForPendingWrites'),
  );

  setUp(() {
    calls = [];
    terminateError = null;
  });

  test('deve fechar os streams, terminar e limpar, nessa ordem', () async {
    await cache().clear();

    expect(calls, ['closeStreams', 'terminate', 'clearPersistence']);
  });

  // O `clearPersistence` falha com a instância rodando: sem o `terminate`,
  // não adianta tentar.
  test('deve parar sem limpar quando o terminate falha', () async {
    terminateError = StateError('terminate');

    await cache().clear().then((_) {}, onError: (Object _) {});

    expect(calls, ['closeStreams', 'terminate']);
  });

  test('deve repassar a falha do terminate', () async {
    terminateError = StateError('terminate');

    await expectLater(cache().clear(), throwsStateError);
  });

  test('deve repassar a espera pelas escritas pendentes', () async {
    await cache().waitForPendingWrites();

    expect(calls, ['waitForPendingWrites']);
  });

  test('deve limpar sem terminar no início do app', () async {
    await cache().clearUnused();

    expect(calls, ['clearPersistence']);
  });
}

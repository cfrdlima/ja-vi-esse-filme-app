import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/features/auth/data/gateways/firestore_account_documents.dart';
import 'package:ja_vi_esse_filme/features/auth/domain/repositories/auth_repository.dart';

/// Um "servidor" em memória: cada subcoleção com os ids que ainda existem.
final class _FakeServer {
  _FakeServer(this.documents);

  final Map<String, List<String>> documents;
  final List<int> requestedLimits = [];
  final List<String> calls = [];
  Object? deleteError;
  bool fetchHangs = false;
  bool deleteHangs = false;

  Future<List<String>> fetchIds(String uid, String collection, int limit) {
    calls.add('fetch $uid/$collection');
    requestedLimits.add(limit);
    if (fetchHangs) return Completer<List<String>>().future;
    final ids = documents[collection] ?? [];
    return Future.value(ids.take(limit).toList());
  }

  Future<void> delete(String uid, String collection, List<String> ids) {
    calls.add('delete $uid/$collection ${ids.length}');
    if (deleteHangs) return Completer<void>().future;
    if (deleteError case final Object error) return Future.error(error);
    documents[collection]?.removeWhere(ids.contains);
    return Future.value();
  }
}

List<String> _ids(int count) => [for (var i = 1; i <= count; i++) '$i'];

void main() {
  late _FakeServer server;

  FirestoreAccountDocuments gateway({
    List<String> collections = const ['movies'],
  }) => FirestoreAccountDocuments(
    collections: collections,
    fetchIds: server.fetchIds,
    delete: server.delete,
  );

  setUp(() => server = _FakeServer({'movies': _ids(3)}));

  test('deve apagar todos os documentos da subcoleção', () async {
    await gateway().deleteAll('alice');

    expect(server.documents['movies'], isEmpty);
  });

  test('deve apagar os documentos de cada subcoleção da lista', () async {
    server = _FakeServer({'movies': _ids(2), 'lists': _ids(2)});

    await gateway(collections: ['movies', 'lists']).deleteAll('alice');

    expect(server.documents.values.expand((ids) => ids), isEmpty);
  });

  test('deve ler e apagar só em users/{uid} da conta pedida', () async {
    await gateway().deleteAll('alice');

    expect(server.calls.every((call) => call.contains(' alice/')), isTrue);
  });

  test('deve pedir lotes de no máximo 500 documentos', () async {
    server = _FakeServer({'movies': _ids(1200)});

    await gateway().deleteAll('alice');

    expect(server.requestedLimits.every((limit) => limit == 500), isTrue);
  });

  test('deve repetir os lotes até a leitura voltar vazia', () async {
    server = _FakeServer({'movies': _ids(1200)});

    await gateway().deleteAll('alice');

    expect(server.calls, [
      'fetch alice/movies',
      'delete alice/movies 500',
      'fetch alice/movies',
      'delete alice/movies 500',
      'fetch alice/movies',
      'delete alice/movies 200',
      'fetch alice/movies',
    ]);
  });

  test('não deve apagar nada quando a subcoleção já está vazia', () async {
    server = _FakeServer({'movies': []});

    await gateway().deleteAll('alice');

    expect(server.calls, ['fetch alice/movies']);
  });

  test('deve repassar o erro do lote', () async {
    server.deleteError = StateError('permission-denied');

    await expectLater(gateway().deleteAll('alice'), throwsStateError);
  });

  // Sem o servidor confirmar o lote, a próxima leitura traria os mesmos ids.
  test('deve parar no lote que falha, sem ler de novo', () async {
    server.deleteError = StateError('permission-denied');

    await gateway().deleteAll('alice').then((_) {}, onError: (Object _) {});

    expect(server.calls, ['fetch alice/movies', 'delete alice/movies 3']);
  });

  test('deve falhar com TimeoutException quando a leitura passa do prazo', () {
    fakeAsync((async) {
      server.fetchHangs = true;
      Object? error;
      unawaited(
        gateway()
            .deleteAll('alice')
            .then((_) {}, onError: (Object e) => error = e),
      );

      async.elapse(AuthRepository.deleteStepTimeout);

      expect(error, isA<TimeoutException>());
    });
  });

  test('deve falhar com TimeoutException quando o lote passa do prazo', () {
    fakeAsync((async) {
      server.deleteHangs = true;
      Object? error;
      unawaited(
        gateway()
            .deleteAll('alice')
            .then((_) {}, onError: (Object e) => error = e),
      );

      async.elapse(AuthRepository.deleteStepTimeout);

      expect(error, isA<TimeoutException>());
    });
  });

  // O prazo é de cada passo, e não da exclusão inteira (decisão 015).
  test('não deve falhar antes do prazo do passo', () {
    fakeAsync((async) {
      server.fetchHangs = true;
      Object? error;
      unawaited(
        gateway()
            .deleteAll('alice')
            .then((_) {}, onError: (Object e) => error = e),
      );

      async.elapse(
        AuthRepository.deleteStepTimeout - const Duration(seconds: 1),
      );

      expect(error, isNull);
    });
  });
}

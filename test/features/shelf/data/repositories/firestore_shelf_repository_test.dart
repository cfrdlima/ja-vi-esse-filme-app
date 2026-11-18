import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/core/error/failures.dart';
import 'package:ja_vi_esse_filme/core/firestore/user_data_write_lock.dart';
import 'package:ja_vi_esse_filme/features/shelf/data/gateways/shelf_gateway.dart';
import 'package:ja_vi_esse_filme/features/shelf/data/models/shelf_movie_model.dart';
import 'package:ja_vi_esse_filme/features/shelf/data/repositories/firestore_shelf_repository.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/movie_copy.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/shelf_entry.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/shelf_mark.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/shelf_movie.dart';

/// Grava as chamadas e devolve o que o teste mandar.
class _FakeShelfGateway implements ShelfGateway {
  final documents = StreamController<Map<String, Object?>>.broadcast();
  final calls = <String>[];
  Map<String, FieldWrite>? lastFields;
  Object? failure;

  /// Falha só no `update`, para o `delete` seguinte poder dar certo.
  Object? updateFailure;

  @override
  Stream<Map<String, Object?>> watchMovie(String uid, int movieId) {
    calls.add('watch $uid $movieId');
    return documents.stream;
  }

  final shelfDocuments = StreamController<List<ShelfDocument>>.broadcast();

  @override
  Stream<List<ShelfDocument>> watchShelf(
    String uid,
    String orderField,
    int limit,
  ) {
    calls.add('shelf $uid $orderField $limit');
    return shelfDocuments.stream;
  }

  @override
  Future<void> mergeMovie(
    String uid,
    int movieId,
    Map<String, FieldWrite> fields,
  ) => _record('merge $uid $movieId', fields);

  @override
  Future<void> updateMovie(
    String uid,
    int movieId,
    Map<String, FieldWrite> fields,
  ) async {
    await _record('update $uid $movieId', fields);
    if (updateFailure case final Object error) throw error;
  }

  @override
  Future<void> deleteMovie(String uid, int movieId) =>
      _record('delete $uid $movieId', null);

  Future<void> close() async {
    await documents.close();
    await shelfDocuments.close();
  }

  Future<void> _record(String call, Map<String, FieldWrite>? fields) async {
    calls.add(call);
    lastFields = fields;
    if (failure case final Object error) throw error;
  }
}

FirebaseException _firestoreError(String code) => FirebaseException(
  plugin: 'cloud_firestore',
  code: code,
  message: 'mensagem com segredo@example.com',
);

void main() {
  late _FakeShelfGateway gateway;
  String? uid;
  late FirestoreShelfRepository repository;

  final copy = MovieCopy(movieId: 550, title: 'Clube da Luta');
  final watchedAt = DateTime.utc(2026, 11, 2);

  ShelfMovie movieWith(Set<ShelfMark> marks) => ShelfMovie(
    copy: copy,
    cachedAt: DateTime.utc(2026, 11, 1),
    marks: {for (final mark in marks) mark: watchedAt},
  );

  late UserDataWriteLock writeLock;

  setUp(() {
    gateway = _FakeShelfGateway();
    uid = 'alice';
    writeLock = UserDataWriteLock();
    repository = FirestoreShelfRepository(
      gateway: gateway,
      currentUid: () => uid,
      writeLock: writeLock,
    );
  });

  tearDown(() => gateway.close());

  group('watchMovie', () {
    test('deve falhar com SignInRequiredFailure sem ninguém logado', () {
      uid = null;

      expect(
        repository.watchMovie(550),
        emitsError(isA<SignInRequiredFailure>()),
      );
    });

    test('deve observar o filme do usuário logado', () async {
      final subscription = repository.watchMovie(550).listen((_) {});
      await subscription.cancel();

      expect(gateway.calls, ['watch alice 550']);
    });

    test('deve emitir o filme na Estante a partir do documento', () async {
      final entries = repository.watchMovie(550);
      final next = entries.first;

      gateway.documents.add({'title': 'Clube da Luta', 'watchedAt': watchedAt});

      expect(await next, isA<OnShelf>());
    });

    test('deve emitir fora da Estante sem documento', () async {
      final next = repository.watchMovie(550).first;

      gateway.documents.add({});

      expect(await next, const NotOnShelf());
    });

    test('deve emitir UnexpectedFailure com o documento ilegível', () {
      final entries = repository.watchMovie(550);

      expect(entries, emitsError(isA<UnexpectedFailure>()));
      gateway.documents.add({'watchedAt': watchedAt});
    });

    test('deve emitir UnexpectedFailure com um movieId fora das regras', () {
      expect(repository.watchMovie(0), emitsError(isA<UnexpectedFailure>()));
    });

    test('deve traduzir o erro do Firestore no stream', () {
      final entries = repository.watchMovie(550);

      expect(entries, emitsError(isA<NetworkFailure>()));
      gateway.documents.addError(_firestoreError('unavailable'));
    });
  });

  group('watchShelf', () {
    ShelfDocument doc(String id) => (
      id: id,
      fields: {
        'title': 'Filme $id',
        'cachedAt': DateTime.utc(2026, 11),
        'watchedAt': watchedAt,
      },
    );

    test('deve falhar com SignInRequiredFailure sem ninguém logado', () {
      uid = null;

      expect(
        repository.watchShelf(ShelfMark.watched, limit: 20),
        emitsError(isA<SignInRequiredFailure>()),
      );
    });

    test('deve recusar um limite menor que 1', () {
      expect(
        () => repository.watchShelf(ShelfMark.watched, limit: 0),
        throwsArgumentError,
      );
    });

    test('deve consultar pelo campo da marca com o limite', () async {
      repository.watchShelf(ShelfMark.favorite, limit: 40).listen(null);
      await pumpEventQueue();

      expect(gateway.calls, ['shelf alice favoriteAt 40']);
    });

    test('deve emitir a página montada pelo model', () {
      final documents = [doc('13'), doc('550')];

      expect(
        repository.watchShelf(ShelfMark.watched, limit: 2),
        emits(ShelfMovieModel.pageFrom(documents, limit: 2)),
      );
      gateway.shelfDocuments.add(documents);
    });

    test('deve traduzir o erro do Firestore no stream', () {
      expect(
        repository.watchShelf(ShelfMark.watched, limit: 20),
        emitsError(isA<NetworkFailure>()),
      );
      gateway.shelfDocuments.addError(_firestoreError('unavailable'));
    });

    test('deve ser encerrado pelo closeStreams', () async {
      final done = Completer<void>();
      repository
          .watchShelf(ShelfMark.watched, limit: 20)
          .listen(null, onDone: done.complete);
      await pumpEventQueue();

      await repository.closeStreams();
      await pumpEventQueue();

      expect(done.isCompleted, isTrue);
    });

    test('deve parar de ouvir o Firestore no closeStreams', () async {
      repository.watchShelf(ShelfMark.watched, limit: 20).listen(null);
      await pumpEventQueue();

      await repository.closeStreams();

      expect(gateway.shelfDocuments.hasListener, isFalse);
    });

    test('deve contar o stream da Estante que alguém ouve', () async {
      repository.watchShelf(ShelfMark.watched, limit: 20).listen(null);
      await pumpEventQueue();

      expect(repository.openStreamCount, 1);
    });
  });

  group('addMark', () {
    test('deve mesclar no filme do usuário logado', () async {
      await repository.addMark(copy, ShelfMark.watched);

      expect(gateway.calls, ['merge alice 550']);
    });

    test('deve mesclar a marca e a cópia do model', () async {
      await repository.addMark(copy, ShelfMark.watched);

      expect(
        gateway.lastFields,
        ShelfMovieModel.markFields(copy, ShelfMark.watched),
      );
    });

    test('não deve tratar o not-found do addMark como sucesso', () async {
      gateway.failure = _firestoreError('not-found');

      await expectLater(
        repository.addMark(copy, ShelfMark.watched),
        throwsA(isA<UnexpectedFailure>()),
      );
    });

    test(
      'deve falhar com SignInRequiredFailure sem tocar no Firestore',
      () async {
        uid = null;

        await expectLater(
          repository.addMark(copy, ShelfMark.watched),
          throwsA(isA<SignInRequiredFailure>()),
        );
        expect(gateway.calls, isEmpty);
      },
    );
  });

  group('removeMark', () {
    test('deve atualizar o filme quando sobra outra marca', () async {
      final movie = movieWith({ShelfMark.watched, ShelfMark.favorite});

      await repository.removeMark(movie, ShelfMark.favorite);

      expect(gateway.calls, ['update alice 550']);
    });

    test('deve tirar só o campo da marca', () async {
      final movie = movieWith({ShelfMark.watched, ShelfMark.favorite});

      await repository.removeMark(movie, ShelfMark.favorite);

      expect(
        gateway.lastFields,
        ShelfMovieModel.unmarkFields(ShelfMark.favorite),
      );
    });

    // O aparelho achava que sobrava outra marca, mas no servidor ela já
    // tinha saído: as regras negam o documento sem marcas, e o delete
    // termina o que o desmarcar queria.
    test(
      'deve apagar o filme quando as regras negam tirar a última marca',
      () async {
        gateway.updateFailure = _firestoreError('permission-denied');
        final movie = movieWith({ShelfMark.watched, ShelfMark.favorite});

        await repository.removeMark(movie, ShelfMark.favorite);

        expect(gateway.calls, ['update alice 550', 'delete alice 550']);
      },
    );

    test('deve apagar o documento ao tirar a única marca', () async {
      await repository.removeMark(
        movieWith({ShelfMark.watched}),
        ShelfMark.watched,
      );

      expect(gateway.calls, ['delete alice 550']);
    });

    test('deve aceitar o documento que já não existe', () async {
      gateway.failure = _firestoreError('not-found');
      final movie = movieWith({ShelfMark.watched, ShelfMark.favorite});

      await expectLater(
        repository.removeMark(movie, ShelfMark.favorite),
        completes,
      );
    });

    test(
      'deve falhar com SignInRequiredFailure sem tocar no Firestore',
      () async {
        uid = null;

        await expectLater(
          repository.removeMark(
            movieWith({ShelfMark.watched}),
            ShelfMark.watched,
          ),
          throwsA(isA<SignInRequiredFailure>()),
        );
        expect(gateway.calls, isEmpty);
      },
    );
  });

  group('renewCopy', () {
    test('deve atualizar o filme do usuário logado', () async {
      await repository.renewCopy(copy);

      expect(gateway.calls, ['update alice 550']);
    });

    test('deve atualizar só a cópia do model', () async {
      await repository.renewCopy(copy);

      expect(gateway.lastFields, ShelfMovieModel.copyFields(copy));
    });

    test('deve aceitar o documento que já não existe', () async {
      gateway.updateFailure = _firestoreError('not-found');

      await expectLater(repository.renewCopy(copy), completes);
    });

    test('deve falhar com SignInRequiredFailure sem ninguém logado', () async {
      uid = null;

      await expectLater(
        repository.renewCopy(copy),
        throwsA(isA<SignInRequiredFailure>()),
      );
    });

    test('deve traduzir o erro do Firestore', () async {
      gateway.updateFailure = _firestoreError('resource-exhausted');

      await expectLater(
        repository.renewCopy(copy),
        throwsA(isA<RateLimitFailure>()),
      );
    });
  });

  // Enquanto a exclusão da conta apaga os documentos (decisão 015).
  group('com as escritas travadas', () {
    setUp(() => writeLock.lock());

    test('deve recusar a marca sem tocar no Firestore', () async {
      await repository
          .addMark(copy, ShelfMark.watched)
          .then<void>((_) {}, onError: (Object _) {});

      expect(gateway.calls, isEmpty);
    });

    test('deve falhar a marca com UnexpectedFailure', () async {
      await expectLater(
        repository.addMark(copy, ShelfMark.watched),
        throwsA(isA<UnexpectedFailure>()),
      );
    });

    test('deve recusar desmarcar sem tocar no Firestore', () async {
      await repository
          .removeMark(movieWith({ShelfMark.watched}), ShelfMark.watched)
          .then<void>((_) {}, onError: (Object _) {});

      expect(gateway.calls, isEmpty);
    });

    test('deve recusar a renovação da cópia sem tocar no Firestore', () async {
      await repository
          .renewCopy(copy)
          .then<void>((_) {}, onError: (Object _) {});

      expect(gateway.calls, isEmpty);
    });

    test('deve voltar a gravar depois de destravar', () async {
      writeLock.unlock();

      await repository.addMark(copy, ShelfMark.watched);

      expect(gateway.calls, ['merge alice 550']);
    });
  });

  group('tradução dos erros do Firestore', () {
    for (final (code, matcher) in [
      ('unavailable', isA<NetworkFailure>()),
      ('deadline-exceeded', isA<NetworkFailure>()),
      ('resource-exhausted', isA<RateLimitFailure>()),
      ('unauthenticated', isA<SignInRequiredFailure>()),
      ('permission-denied', isA<UnexpectedFailure>()),
      ('internal', isA<UnexpectedFailure>()),
    ]) {
      test('deve traduzir $code', () async {
        gateway.failure = _firestoreError(code);

        await expectLater(
          repository.addMark(copy, ShelfMark.watched),
          throwsA(matcher),
        );
      });
    }

    test('não deve levar a message do SDK para a falha', () async {
      gateway.failure = _firestoreError('internal');

      final failure = await repository
          .addMark(copy, ShelfMark.watched)
          .then<Object?>((_) => null, onError: (Object e) => e);

      expect(failure.toString(), isNot(contains('segredo')));
    });

    test(
      'deve traduzir uma exceção fora do SDK como UnexpectedFailure',
      () async {
        gateway.failure = Exception('fora do SDK');

        await expectLater(
          repository.addMark(copy, ShelfMark.watched),
          throwsA(isA<UnexpectedFailure>()),
        );
      },
    );

    // Um Error é bug: sobe como está, para o relatório de erros ver.
    test('deve deixar um Error subir sem virar falha', () async {
      gateway.failure = StateError('bug');

      await expectLater(
        repository.addMark(copy, ShelfMark.watched),
        throwsStateError,
      );
    });
  });

  group('closeStreams', () {
    test('deve encerrar os streams abertos', () async {
      final done = Completer<void>();
      repository.watchMovie(550).listen(null, onDone: done.complete);
      await pumpEventQueue();

      await repository.closeStreams();
      await pumpEventQueue();

      expect(done.isCompleted, isTrue);
    });

    test('deve parar de ouvir o Firestore', () async {
      repository.watchMovie(550).listen(null);
      await pumpEventQueue();

      await repository.closeStreams();

      expect(gateway.documents.hasListener, isFalse);
    });

    test('deve contar o stream só depois de alguém ouvir', () {
      repository.watchMovie(550);

      expect(repository.openStreamCount, 0);
    });

    test('deve contar o stream que alguém ouve', () async {
      repository.watchMovie(550).listen(null);
      await pumpEventQueue();

      expect(repository.openStreamCount, 1);
    });

    test('deve esquecer o stream que quem ouvia cancelou', () async {
      final subscription = repository.watchMovie(550).listen(null);
      await pumpEventQueue();

      await subscription.cancel();

      expect(repository.openStreamCount, 0);
    });

    test('deve esquecer o stream que o Firestore encerrou', () async {
      repository.watchMovie(550).listen(null);
      await pumpEventQueue();

      await gateway.close();
      await pumpEventQueue();

      expect(repository.openStreamCount, 0);
    });

    // Com quem ouve pausado, esperar o fim do stream travaria o logout.
    test('deve concluir com o stream pausado', () async {
      repository.watchMovie(550).listen(null).pause();
      await pumpEventQueue();

      await expectLater(
        repository.closeStreams().timeout(const Duration(seconds: 1)),
        completes,
      );
    });
  });
}

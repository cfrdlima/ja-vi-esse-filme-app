import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/core/error/failures.dart';
import 'package:ja_vi_esse_filme/core/firestore/user_data_write_lock.dart';
import 'package:ja_vi_esse_filme/features/shelf/data/gateways/movie_lists_gateway.dart';
import 'package:ja_vi_esse_filme/features/shelf/data/gateways/shelf_gateway.dart';
import 'package:ja_vi_esse_filme/features/shelf/data/models/movie_list_model.dart';
import 'package:ja_vi_esse_filme/features/shelf/data/models/shelf_movie_model.dart';
import 'package:ja_vi_esse_filme/features/shelf/data/repositories/firestore_movie_lists_repository.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/list_name.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/movie_copy.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/movie_list.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/shelf_mark.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/shelf_movie.dart';

const _terrorId = 'Lst0aBcDeFgHiJkLmNoP';
const _comedyId = 'Lst1aBcDeFgHiJkLmNoP';

/// Grava as chamadas e devolve o que o teste mandar.
class _FakeListsGateway implements MovieListsGateway {
  final calls = <String>[];
  final lists = StreamController<List<ShelfDocument>>.broadcast();
  Map<String, FieldWrite>? lastFields;
  Object? failure;

  int serverCount = 0;
  int cacheCount = 0;
  Object? serverCountFailure;

  /// Nunca completa a contagem do servidor, como uma rede muito lenta.
  bool serverCountHangs = false;

  /// Cada leitura do servidor devolve o próximo lote; sem lote, vazio.
  final List<List<ShelfDocument>> serverBatches = [];
  final List<List<MovieBatchWrite>> committed = [];

  /// Nunca completa a leitura do servidor.
  bool fetchHangs = false;

  @override
  Stream<List<ShelfDocument>> watchLists(String uid, int limit) {
    calls.add('lists $uid $limit');
    return lists.stream;
  }

  @override
  String newListId(String uid) => _terrorId;

  Future<int> _count(int value) async {
    if (serverCountHangs) return Completer<int>().future;
    if (serverCountFailure case final Object error) throw error;
    return value;
  }

  @override
  Future<int> countListsOnServer(String uid) => _count(serverCount);

  @override
  Future<int> countListsInCache(String uid) async => cacheCount;

  @override
  Future<int> countMoviesOnServer(String uid, String orderField) {
    calls.add('count server $orderField');
    return _count(serverCount);
  }

  @override
  Future<int> countMoviesInCache(String uid, String orderField) async =>
      cacheCount;

  @override
  Future<void> setList(
    String uid,
    String listId,
    Map<String, FieldWrite> fields,
  ) => _record('set $uid $listId', fields);

  @override
  Future<void> updateList(
    String uid,
    String listId,
    Map<String, FieldWrite> fields,
  ) => _record('update $uid $listId', fields);

  @override
  Future<void> deleteList(String uid, String listId) =>
      _record('delete $uid $listId', null);

  @override
  Future<List<ShelfDocument>> fetchMoviesFromServer(
    String uid,
    String orderField,
    int limit,
  ) async {
    calls.add('fetch $orderField $limit');
    if (fetchHangs) return Completer<List<ShelfDocument>>().future;
    if (failure case final Object error) throw error;
    return serverBatches.isEmpty ? const [] : serverBatches.removeAt(0);
  }

  @override
  Future<void> commitMovies(String uid, List<MovieBatchWrite> writes) async {
    calls.add('commit ${writes.length}');
    committed.add(writes);
  }

  Future<void> _record(String call, Map<String, FieldWrite>? fields) async {
    calls.add(call);
    lastFields = fields;
    if (failure case final Object error) throw error;
  }

  Future<void> close() => lists.close();
}

class _FakeMoviesGateway implements ShelfGateway {
  final calls = <String>[];
  final shelf = StreamController<List<ShelfDocument>>.broadcast();
  Map<String, FieldWrite>? lastFields;

  /// Falha só no `update`, para o `delete` seguinte poder dar certo.
  Object? updateFailure;

  @override
  Stream<Map<String, Object?>> watchMovie(String uid, int movieId) =>
      const Stream.empty();

  @override
  Stream<List<ShelfDocument>> watchShelf(
    String uid,
    String orderField,
    int limit,
  ) {
    calls.add('shelf $orderField $limit');
    return shelf.stream;
  }

  @override
  Future<void> mergeMovie(
    String uid,
    int movieId,
    Map<String, FieldWrite> fields,
  ) async {
    calls.add('merge $uid $movieId');
    lastFields = fields;
  }

  @override
  Future<void> updateMovie(
    String uid,
    int movieId,
    Map<String, FieldWrite> fields,
  ) async {
    calls.add('update $uid $movieId');
    lastFields = fields;
    if (updateFailure case final Object error) throw error;
  }

  @override
  Future<void> deleteMovie(String uid, int movieId) async {
    calls.add('delete $uid $movieId');
  }

  Future<void> close() => shelf.close();
}

FirebaseException _firestoreError(String code) => FirebaseException(
  plugin: 'cloud_firestore',
  code: code,
  message: 'mensagem com segredo@example.com',
);

void main() {
  late _FakeListsGateway listsGateway;
  late _FakeMoviesGateway moviesGateway;
  late UserDataWriteLock writeLock;
  String? uid;
  late FirestoreMovieListsRepository repository;

  final terror = MovieList(id: _terrorId, name: ListName('Terror'));
  final copy = MovieCopy(movieId: 550, title: 'Clube da Luta');
  final at = DateTime.utc(2026, 11, 2);

  ShelfMovie movieIn(Set<String> listIds, {Set<ShelfMark> marks = const {}}) =>
      ShelfMovie(
        copy: copy,
        cachedAt: at,
        marks: {for (final mark in marks) mark: at},
        lists: {for (final id in listIds) id: at},
      );

  ShelfDocument movieDocument(
    int id,
    Set<String> listIds, {
    bool watched = false,
  }) => (
    id: '$id',
    fields: {
      'title': 'Filme $id',
      'cachedAt': at,
      if (watched) 'watchedAt': at,
      'lists': {for (final listId in listIds) listId: at},
    },
  );

  setUp(() {
    listsGateway = _FakeListsGateway();
    moviesGateway = _FakeMoviesGateway();
    writeLock = UserDataWriteLock();
    uid = 'alice';
    repository = FirestoreMovieListsRepository(
      lists: listsGateway,
      movies: moviesGateway,
      currentUid: () => uid,
      writeLock: writeLock,
    );
  });

  tearDown(() async {
    await listsGateway.close();
    await moviesGateway.close();
  });

  group('watchLists', () {
    test('deve falhar com SignInRequiredFailure sem ninguém logado', () {
      uid = null;

      expect(repository.watchLists(), emitsError(isA<SignInRequiredFailure>()));
    });

    test('deve emitir as listas pelo model', () async {
      final documents = [
        (id: _terrorId, fields: <String, Object?>{'name': 'Terror'}),
        (id: _comedyId, fields: <String, Object?>{'name': 'Comédia'}),
      ];
      final emitted = repository.watchLists().first;
      await pumpEventQueue();

      listsGateway.lists.add(documents);

      expect(await emitted, MovieListModel.listsFrom(documents));
    });

    // Uma a mais que o teto, para a UI saber que a conta passou dele.
    test('deve assinar até uma lista além do teto', () async {
      final subscription = repository.watchLists().listen((_) {});
      await pumpEventQueue();

      expect(listsGateway.calls, [
        'lists alice ${MovieList.maxPerAccount + 1}',
      ]);
      await subscription.cancel();
    });

    test('deve traduzir a falta de rede', () async {
      final emitted = repository.watchLists().first;
      await pumpEventQueue();

      listsGateway.lists.addError(_firestoreError('unavailable'));

      await expectLater(emitted, throwsA(isA<NetworkFailure>()));
    });

    test('deve encerrar o stream no closeStreams', () async {
      final done = Completer<void>();
      repository.watchLists().listen((_) {}, onDone: done.complete);
      await pumpEventQueue();

      await repository.closeStreams();

      await expectLater(done.future, completes);
    });
  });

  group('newList', () {
    test('deve dar à lista o id novo do gateway', () {
      expect(repository.newList(ListName('Terror')), terror);
    });

    test('deve falhar com SignInRequiredFailure sem ninguém logado', () {
      uid = null;

      expect(
        () => repository.newList(ListName('Terror')),
        throwsA(isA<SignInRequiredFailure>()),
      );
    });
  });

  group('contagens', () {
    test('deve contar as listas no servidor', () async {
      listsGateway.serverCount = 7;

      expect(await repository.countLists(), 7);
    });

    test('deve contar as listas no aparelho sem rede', () async {
      listsGateway.serverCountFailure = _firestoreError('unavailable');
      listsGateway.cacheCount = 3;

      expect(await repository.countLists(), 3);
    });

    test('deve contar no aparelho quando o servidor demora', () {
      fakeAsync((async) {
        listsGateway.serverCountHangs = true;
        listsGateway.cacheCount = 4;
        int? count;

        unawaited(repository.countLists().then((value) => count = value));
        async.elapse(FirestoreMovieListsRepository.countTimeout);

        expect(count, 4);
      });
    });

    test('deve traduzir outra falha da contagem', () async {
      listsGateway.serverCountFailure = _firestoreError('permission-denied');

      await expectLater(
        repository.countLists(),
        throwsA(isA<UnexpectedFailure>()),
      );
    });

    test('deve contar os filmes pelo campo da lista', () async {
      listsGateway.serverCount = 12;

      await repository.countMovies(terror);

      expect(listsGateway.calls, [
        'count server ${ShelfMovieModel.listOrderField(_terrorId)}',
      ]);
    });

    test('deve contar os filmes no aparelho sem rede', () async {
      listsGateway.serverCountFailure = _firestoreError('unavailable');
      listsGateway.cacheCount = 9;

      expect(await repository.countMovies(terror), 9);
    });
  });

  group('createList e renameList', () {
    test('deve gravar a lista só com o nome', () async {
      await repository.createList(terror);

      expect(listsGateway.lastFields, MovieListModel.nameFields(terror.name));
    });

    test('deve gravar a lista no id dela', () async {
      await repository.createList(terror);

      expect(listsGateway.calls, ['set alice $_terrorId']);
    });

    test('deve renomear a lista', () async {
      await repository.renameList(terror, ListName('Suspense'));

      expect(
        listsGateway.lastFields,
        MovieListModel.nameFields(ListName('Suspense')),
      );
    });

    test('deve aceitar renomear a lista que já não existe', () async {
      listsGateway.failure = _firestoreError('not-found');

      await expectLater(
        repository.renameList(terror, ListName('Suspense')),
        completes,
      );
    });

    test('deve recusar criar durante a exclusão da conta', () async {
      writeLock.lock();

      await expectLater(
        repository.createList(terror),
        throwsA(isA<UnexpectedFailure>()),
      );
    });

    test('deve traduzir a cota esgotada', () async {
      listsGateway.failure = _firestoreError('resource-exhausted');

      await expectLater(
        repository.createList(terror),
        throwsA(isA<RateLimitFailure>()),
      );
    });

    test('deve falhar com SignInRequiredFailure sem ninguém logado', () async {
      uid = null;

      await expectLater(
        repository.createList(terror),
        throwsA(isA<SignInRequiredFailure>()),
      );
    });
  });

  group('watchList', () {
    test('deve assinar os filmes pelo campo da lista', () async {
      final subscription = repository
          .watchList(terror, limit: 20)
          .listen((_) {});
      await pumpEventQueue();

      expect(moviesGateway.calls, [
        'shelf ${ShelfMovieModel.listOrderField(_terrorId)} 20',
      ]);
      await subscription.cancel();
    });

    test('deve emitir a página pelo model', () async {
      final documents = [
        movieDocument(550, {_terrorId}),
      ];
      final emitted = repository.watchList(terror, limit: 20).first;
      await pumpEventQueue();

      moviesGateway.shelf.add(documents);

      expect(await emitted, ShelfMovieModel.pageFrom(documents, limit: 20));
    });

    test('deve recusar o limite menor que 1', () {
      expect(() => repository.watchList(terror, limit: 0), throwsArgumentError);
    });
  });

  group('addToList e removeFromList', () {
    test('deve pôr o filme na lista com merge', () async {
      await repository.addToList(copy, terror);

      expect(
        moviesGateway.lastFields,
        ShelfMovieModel.addToListFields(copy, _terrorId),
      );
    });

    test('deve pôr o filme na lista sem apagar o documento', () async {
      await repository.addToList(copy, terror);

      expect(moviesGateway.calls, ['merge alice 550']);
    });

    test('deve tirar da lista o filme que continua no documento', () async {
      final movie = movieIn({_terrorId, _comedyId});

      await repository.removeFromList(movie, terror);

      expect(
        moviesGateway.lastFields,
        ShelfMovieModel.removeFromListFields(movie, _terrorId),
      );
    });

    test('deve apagar o filme sem marca e sem outra lista', () async {
      await repository.removeFromList(movieIn({_terrorId}), terror);

      expect(moviesGateway.calls, ['delete alice 550']);
    });

    // O aparelho via outra lista que no servidor já tinha saído.
    test('deve apagar o filme quando as regras negam tirar a lista', () async {
      moviesGateway.updateFailure = _firestoreError('permission-denied');

      await repository.removeFromList(movieIn({_terrorId, _comedyId}), terror);

      expect(moviesGateway.calls, ['update alice 550', 'delete alice 550']);
    });

    test('deve aceitar o filme que já não existe', () async {
      moviesGateway.updateFailure = _firestoreError('not-found');

      await expectLater(
        repository.removeFromList(movieIn({_terrorId, _comedyId}), terror),
        completes,
      );
    });

    test('deve recusar pôr na lista durante a exclusão da conta', () async {
      writeLock.lock();

      await expectLater(
        repository.addToList(copy, terror),
        throwsA(isA<UnexpectedFailure>()),
      );
    });
  });

  group('deleteList', () {
    test('deve apagar a lista sem filmes', () async {
      await repository.deleteList(terror);

      expect(listsGateway.calls.last, 'delete alice $_terrorId');
    });

    test('deve ler os filmes da lista do servidor em lotes de 500', () async {
      await repository.deleteList(terror);

      expect(
        listsGateway.calls.first,
        'fetch ${ShelfMovieModel.listOrderField(_terrorId)} 500',
      );
    });

    test(
      'deve tirar a lista dos filmes que continuam e apagar os outros',
      () async {
        listsGateway.serverBatches.add([
          movieDocument(550, {_terrorId}, watched: true),
          movieDocument(551, {_terrorId, _comedyId}),
          movieDocument(552, {_terrorId}),
        ]);

        await repository.deleteList(terror);

        expect(listsGateway.committed.single, [
          const UpdateMovieInBatch(550, {'lists': DeleteField()}),
          UpdateMovieInBatch(551, {
            ShelfMovieModel.listOrderField(_terrorId): const DeleteField(),
          }),
          const DeleteMovieInBatch(552),
        ]);
      },
    );

    test('deve repetir até a leitura voltar vazia', () async {
      listsGateway.serverBatches
        ..add([
          movieDocument(550, {_terrorId}),
        ])
        ..add([
          movieDocument(551, {_terrorId}),
        ]);

      await repository.deleteList(terror);

      expect(listsGateway.committed, hasLength(2));
    });

    test('deve apagar a lista só depois dos filmes', () async {
      listsGateway.serverBatches.add([
        movieDocument(550, {_terrorId}),
      ]);

      await repository.deleteList(terror);

      expect(listsGateway.calls, [
        'fetch ${ShelfMovieModel.listOrderField(_terrorId)} 500',
        'commit 1',
        'fetch ${ShelfMovieModel.listOrderField(_terrorId)} 500',
        'delete alice $_terrorId',
      ]);
    });

    // Sem título legível o documento não passa nas regras num update.
    test('deve apagar o documento ilegível da lista', () async {
      listsGateway.serverBatches.add([
        (
          id: '550',
          fields: <String, Object?>{
            'lists': {_terrorId: at},
          },
        ),
      ]);

      await repository.deleteList(terror);

      expect(listsGateway.committed.single, [const DeleteMovieInBatch(550)]);
    });

    test('deve falhar com NetworkFailure sem rede', () async {
      listsGateway.failure = _firestoreError('unavailable');

      await expectLater(
        repository.deleteList(terror),
        throwsA(isA<NetworkFailure>()),
      );
    });

    test('deve falhar com NetworkFailure quando um passo passa do prazo', () {
      fakeAsync((async) {
        listsGateway.fetchHangs = true;
        Object? error;

        unawaited(
          repository.deleteList(terror).catchError((Object e) {
            error = e;
          }),
        );
        async.elapse(FirestoreMovieListsRepository.stepTimeout);

        expect(error, isA<NetworkFailure>());
      });
    });

    test('não deve apagar a lista se a leitura falhar', () async {
      listsGateway.failure = _firestoreError('unavailable');

      await repository.deleteList(terror).catchError((Object _) {});

      expect(listsGateway.calls, isNot(contains('delete alice $_terrorId')));
    });

    test('deve recusar apagar durante a exclusão da conta', () async {
      writeLock.lock();

      await expectLater(
        repository.deleteList(terror),
        throwsA(isA<UnexpectedFailure>()),
      );
    });
  });
}

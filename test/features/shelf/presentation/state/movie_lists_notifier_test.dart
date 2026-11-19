import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/core/error/failures.dart';
import 'package:ja_vi_esse_filme/features/auth/domain/entities/app_user.dart';
import 'package:ja_vi_esse_filme/features/auth/domain/entities/auth_state.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/list_name.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/movie_list.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/usecases/create_movie_list.dart';
import 'package:ja_vi_esse_filme/features/shelf/presentation/state/movie_lists_notifier.dart';
import 'package:ja_vi_esse_filme/features/shelf/presentation/state/movie_lists_state.dart';

import '../../../../helpers/fake_movie_lists_repository.dart';

void main() {
  late FakeMovieListsRepository lists;
  late StreamController<AuthState> account;
  late MovieListsNotifier notifier;

  final ana = AppUser(uid: 'ana123', displayName: 'Ana');
  final bia = AppUser(uid: 'bia456', displayName: 'Bia');

  MovieList listNamed(String name, int id) => MovieList(
    id: 'Lst${id.toString().padLeft(17, '0')}',
    name: ListName(name),
  );

  final terror = listNamed('Terror', 1);
  final comedy = listNamed('Comédia', 2);

  MovieListsReady ready() => switch (notifier.state) {
    final MovieListsReady state => state,
    final other => fail('esperava as listas prontas, veio $other'),
  };

  List<String> shownNames() => [
    for (final item in ready().lists) item.list.name.value,
  ];

  Future<void> signInAs(AppUser user) async {
    account.add(SignedIn(user));
    await pumpEventQueue();
  }

  Future<void> emit(List<MovieList> value) async {
    lists.emitLists(value);
    await pumpEventQueue();
  }

  setUp(() {
    lists = FakeMovieListsRepository();
    account = StreamController<AuthState>.broadcast();
    notifier = MovieListsNotifier(
      lists: lists,
      createList: CreateMovieList(lists),
      account: account.stream,
    );
  });

  tearDown(() async {
    notifier.dispose();
    await account.close();
  });

  group('leitura', () {
    test('deve começar carregando', () {
      expect(notifier.state, isA<MovieListsLoading>());
    });

    test('deve ficar deslogado sem conta', () async {
      account.add(const SignedOut());
      await pumpEventQueue();

      expect(notifier.state, isA<MovieListsSignedOut>());
    });

    test('deve mostrar as listas da conta', () async {
      await signInAs(ana);

      await emit([comedy, terror]);

      expect(shownNames(), ['Comédia', 'Terror']);
    });

    test('deve mostrar o vazio sem nenhuma lista', () async {
      await signInAs(ana);

      await emit([]);

      expect(notifier.state, isA<MovieListsEmpty>());
    });

    test('deve mostrar o erro da leitura', () async {
      await signInAs(ana);

      lists.emitListsError(const NetworkFailure());
      await pumpEventQueue();

      expect(notifier.state, isA<MovieListsError>());
    });

    test('deve assinar de novo no tentar de novo', () async {
      await signInAs(ana);
      lists.emitListsError(const NetworkFailure());
      await pumpEventQueue();

      notifier.retry();

      expect(lists.watchListsCalls, 2);
    });

    test('deve assinar de novo quando a conta muda', () async {
      await signInAs(ana);

      await signInAs(bia);

      expect(lists.activeListWatches, 1);
    });

    test('deve avisar o teto com 50 listas', () async {
      await signInAs(ana);

      await emit([
        for (var i = 0; i < MovieList.maxPerAccount; i++) listNamed('L$i', i),
      ]);

      expect(ready().atLimit, isTrue);
    });

    test('não deve avisar o teto com 49 listas', () async {
      await signInAs(ana);

      await emit([
        for (var i = 0; i < MovieList.maxPerAccount - 1; i++)
          listNamed('L$i', i),
      ]);

      expect(ready().atLimit, isFalse);
    });

    test('deve voltar a carregar quando o stream acaba no logout', () async {
      await signInAs(ana);
      await emit([terror]);

      lists.endLists();
      await pumpEventQueue();

      expect(notifier.state, isA<MovieListsLoading>());
    });
  });

  group('criar', () {
    setUp(() async {
      await signInAs(ana);
      await emit([terror]);
    });

    test('deve mostrar a lista nova na hora', () async {
      unawaited(notifier.create(ListName('Ação')));
      await pumpEventQueue();

      expect(shownNames(), ['Ação', 'Terror']);
    });

    test('deve tirar a lista nova quando o servidor recusa', () async {
      final created = notifier.create(ListName('Ação'));
      await pumpEventQueue();

      lists.writes.single.fail(const RateLimitFailure());
      await created.catchError((Object _) {});

      expect(shownNames(), ['Terror']);
    });

    test('deve entregar a recusa a quem criou', () async {
      final created = notifier.create(ListName('Ação'));
      await pumpEventQueue();

      lists.writes.single.fail(const RateLimitFailure());

      await expectLater(created, throwsA(isA<RateLimitFailure>()));
    });

    test('deve recusar a lista no teto sem mostrá-la', () async {
      lists.listsCount = MovieList.maxPerAccount;

      await notifier.create(ListName('Ação')).catchError((Object _) {});

      expect(shownNames(), ['Terror']);
    });

    test('deve sair do vazio ao criar a primeira lista', () async {
      await emit([]);

      unawaited(notifier.create(ListName('Ação')));
      await pumpEventQueue();

      expect(shownNames(), ['Ação']);
    });

    test('não deve repetir a lista quando o stream a confirma', () async {
      unawaited(notifier.create(ListName('Ação')));
      await pumpEventQueue();
      final created = lists.writes.single.list;

      await emit([created, terror]);

      expect(shownNames(), ['Ação', 'Terror']);
    });
  });

  group('renomear', () {
    setUp(() async {
      await signInAs(ana);
      await emit([terror, comedy]);
    });

    test('deve mostrar o nome novo na hora', () async {
      unawaited(notifier.rename(terror, ListName('Ação')));
      await pumpEventQueue();

      expect(shownNames(), ['Ação', 'Comédia']);
    });

    test('deve voltar o nome quando o servidor recusa', () async {
      final renamed = notifier.rename(terror, ListName('Ação'));
      await pumpEventQueue();

      lists.writes.single.fail(const RateLimitFailure());
      await renamed.catchError((Object _) {});

      expect(shownNames(), ['Comédia', 'Terror']);
    });
  });

  group('apagar', () {
    setUp(() async {
      await signInAs(ana);
      await emit([terror, comedy]);
    });

    bool isDeleting(MovieList list) =>
        ready().lists.firstWhere((item) => item.list.id == list.id).deleting;

    test('deve marcar a lista como apagando', () async {
      unawaited(notifier.delete(terror));
      await pumpEventQueue();

      expect(isDeleting(terror), isTrue);
    });

    test('deve tirar a marca quando a exclusão falha', () async {
      final deleted = notifier.delete(terror);
      await pumpEventQueue();

      lists.writes.single.fail(const NetworkFailure());
      await deleted.catchError((Object _) {});

      expect(isDeleting(terror), isFalse);
    });

    test('deve entregar a falha a quem apagou', () async {
      final deleted = notifier.delete(terror);
      await pumpEventQueue();

      lists.writes.single.fail(const NetworkFailure());

      await expectLater(deleted, throwsA(isA<NetworkFailure>()));
    });

    test('deve completar quando o servidor confirma', () async {
      final deleted = notifier.delete(terror);
      await pumpEventQueue();

      lists.writes.single.complete();

      await expectLater(deleted, completes);
    });
  });
}

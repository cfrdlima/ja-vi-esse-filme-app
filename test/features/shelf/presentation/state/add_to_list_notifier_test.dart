import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/core/error/failures.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/list_name.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/movie_copy.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/movie_list.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/shelf_entry.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/shelf_movie.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/usecases/add_movie_to_list.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/usecases/create_movie_list.dart';
import 'package:ja_vi_esse_filme/features/shelf/presentation/state/add_to_list_notifier.dart';
import 'package:ja_vi_esse_filme/features/shelf/presentation/state/add_to_list_state.dart';

import '../../../../helpers/fake_movie_lists_repository.dart';

void main() {
  late FakeMovieListsRepository lists;
  late ValueNotifier<ShelfEntry?> entry;
  late AddToListNotifier notifier;

  final copy = MovieCopy(movieId: 550, title: 'Clube da Luta');
  final terror = MovieList(
    id: 'Lst0aBcDeFgHiJkLmNoP',
    name: ListName('Terror'),
  );
  final comedy = MovieList(
    id: 'Lst1aBcDeFgHiJkLmNoP',
    name: ListName('Comédia'),
  );
  final at = DateTime.utc(2026, 11);

  ShelfEntry inLists(Set<MovieList> movieLists) => OnShelf(
    ShelfMovie(
      copy: copy,
      cachedAt: at,
      marks: const {},
      lists: {for (final list in movieLists) list.id: at},
    ),
  );

  AddToListReady ready() => switch (notifier.state) {
    final AddToListReady state => state,
    final other => fail('esperava a folha pronta, veio $other'),
  };

  Map<String, bool> checks() => {
    for (final item in ready().items) item.list.name.value: item.checked,
  };

  Future<void> emitLists(List<MovieList> value) async {
    lists.emitLists(value);
    await pumpEventQueue();
  }

  setUp(() {
    lists = FakeMovieListsRepository();
    entry = ValueNotifier(null);
    notifier = AddToListNotifier(
      lists: lists,
      createList: CreateMovieList(lists),
      addMovie: AddMovieToList(lists),
      copy: copy,
      entry: entry,
    );
  });

  tearDown(() {
    notifier.dispose();
    entry.dispose();
  });

  group('leitura', () {
    test('deve começar carregando', () {
      expect(notifier.state, isA<AddToListLoading>());
    });

    test('deve esperar o filme da Estante', () async {
      await emitLists([terror]);

      expect(notifier.state, isA<AddToListLoading>());
    });

    test('deve marcar as listas que têm o filme', () async {
      entry.value = inLists({terror});

      await emitLists([terror, comedy]);

      expect(checks(), {'Comédia': false, 'Terror': true});
    });

    test('deve mostrar nenhuma lista', () async {
      entry.value = const NotOnShelf();

      await emitLists([]);

      expect(ready().items, isEmpty);
    });

    test('deve mostrar o erro da leitura', () async {
      entry.value = const NotOnShelf();

      lists.emitListsError(const NetworkFailure());
      await pumpEventQueue();

      expect(notifier.state, isA<AddToListError>());
    });

    test('deve assinar de novo no tentar de novo', () async {
      lists.emitListsError(const NetworkFailure());
      await pumpEventQueue();

      notifier.retry();

      expect(lists.watchListsCalls, 2);
    });
  });

  group('marcar e desmarcar', () {
    setUp(() async {
      entry.value = inLists({terror});
      await emitLists([terror, comedy]);
    });

    test('deve marcar na hora ao pôr o filme', () async {
      notifier.toggle(comedy);
      await pumpEventQueue();

      expect(checks()['Comédia'], isTrue);
    });

    test('deve pôr o filme com a cópia', () async {
      notifier.toggle(comedy);
      await pumpEventQueue();

      expect(lists.writes.single.copy, copy);
    });

    test('deve desmarcar na hora ao tirar o filme', () async {
      notifier.toggle(terror);
      await pumpEventQueue();

      expect(checks()['Terror'], isFalse);
    });

    test('deve tirar o filme que a Estante confirmou', () async {
      notifier.toggle(terror);
      await pumpEventQueue();

      expect(lists.writes.single.kind, ListWriteKind.remove);
    });

    test('deve voltar a caixa quando o servidor recusa', () async {
      notifier.toggle(comedy);
      await pumpEventQueue();

      lists.writes.single.fail(const RateLimitFailure());
      await pumpEventQueue();

      expect(checks()['Comédia'], isFalse);
    });

    test('deve mostrar a recusa', () async {
      notifier.toggle(comedy);
      await pumpEventQueue();

      lists.writes.single.fail(const RateLimitFailure());
      await pumpEventQueue();

      expect(ready().failure, isA<RateLimitFailure>());
    });

    test('deve recusar a lista cheia sem marcar', () async {
      lists.moviesCount[comedy.id] = MovieList.maxMovies;

      notifier.toggle(comedy);
      await pumpEventQueue();

      expect(checks()['Comédia'], isFalse);
    });

    test('deve avisar a lista cheia', () async {
      lists.moviesCount[comedy.id] = MovieList.maxMovies;

      notifier.toggle(comedy);
      await pumpEventQueue();

      expect(ready().failure, isA<ListFullFailure>());
    });

    test('deve repetir a última escolha no tentar de novo', () async {
      notifier.toggle(comedy);
      await pumpEventQueue();
      lists.writes.single.fail(const RateLimitFailure());
      await pumpEventQueue();

      notifier.retryToggle();
      await pumpEventQueue();

      expect(lists.writes.last.kind, ListWriteKind.add);
    });

    test('deve manter a caixa quando a Estante confirma', () async {
      notifier.toggle(comedy);
      await pumpEventQueue();

      entry.value = inLists({terror, comedy});
      lists.writes.single.complete();
      await pumpEventQueue();

      expect(checks()['Comédia'], isTrue);
    });
  });

  group('criar lista', () {
    setUp(() async {
      entry.value = const NotOnShelf();
      await emitLists([terror]);
    });

    test('deve mostrar a lista nova já marcada', () async {
      await notifier.createAndAdd(ListName('Ação'));

      expect(checks(), {'Ação': true, 'Terror': false});
    });

    test('deve criar a lista e pôr o filme nela', () async {
      await notifier.createAndAdd(ListName('Ação'));
      await pumpEventQueue();

      expect(
        [for (final write in lists.writes) write.kind],
        [ListWriteKind.create, ListWriteKind.add],
      );
    });

    test('deve mostrar o teto', () async {
      lists.listsCount = MovieList.maxPerAccount;

      await notifier.createAndAdd(ListName('Ação'));

      expect(ready().failure, isA<ListLimitFailure>());
    });

    test('não deve criar nada no teto', () async {
      lists.listsCount = MovieList.maxPerAccount;

      await notifier.createAndAdd(ListName('Ação'));

      expect(lists.writes, isEmpty);
    });

    test('deve tirar a lista nova quando o servidor recusa', () async {
      await notifier.createAndAdd(ListName('Ação'));
      await pumpEventQueue();

      lists.writes.first.fail(const RateLimitFailure());
      await pumpEventQueue();

      expect(checks().keys, ['Terror']);
    });
  });

  group('achados do /revisar da 029', () {
    setUp(() async {
      entry.value = const NotOnShelf();
      await emitLists([terror]);
    });

    test('deve tirar o filme da lista cuja criação foi recusada', () async {
      await notifier.createAndAdd(ListName('Ação'));
      await pumpEventQueue();
      final created = lists.writes.first.list;
      entry.value = inLists({created});

      lists.writes.first.fail(const RateLimitFailure());
      await pumpEventQueue();

      expect(lists.writes.last.kind, ListWriteKind.remove);
    });

    test('deve pôr o filme mesmo com a folha fechada no meio', () async {
      final closing = AddToListNotifier(
        lists: lists,
        createList: CreateMovieList(lists),
        addMovie: AddMovieToList(lists),
        copy: copy,
        entry: entry,
      );

      final created = closing.createAndAdd(ListName('Ação'));
      closing.dispose();
      await created;
      await pumpEventQueue();

      expect(
        [for (final write in lists.writes) write.kind],
        [ListWriteKind.create, ListWriteKind.add],
      );
    });

    test('não deve deixar erro solto com a folha fechada', () async {
      final closing = AddToListNotifier(
        lists: lists,
        createList: CreateMovieList(lists),
        addMovie: AddMovieToList(lists),
        copy: copy,
        entry: entry,
      );
      final created = closing.createAndAdd(ListName('Ação'));
      closing.dispose();
      await created;
      await pumpEventQueue();

      for (final write in [...lists.writes]) {
        write.fail(const RateLimitFailure());
      }
      await pumpEventQueue();

      expect(lists.writes, hasLength(2));
    });

    test('deve oferecer tentar de novo na caixa recusada', () async {
      notifier.toggle(terror);
      await pumpEventQueue();

      lists.writes.single.fail(const RateLimitFailure());
      await pumpEventQueue();

      expect(ready().canRetry, isTrue);
    });

    test('não deve oferecer tentar de novo na lista cheia', () async {
      lists.moviesCount[terror.id] = MovieList.maxMovies;

      notifier.toggle(terror);
      await pumpEventQueue();

      expect(ready().canRetry, isFalse);
    });

    test('não deve oferecer tentar de novo no teto de listas', () async {
      lists.listsCount = MovieList.maxPerAccount;

      await notifier.createAndAdd(ListName('Ação'));

      expect(ready().canRetry, isFalse);
    });

    test(
      'não deve repetir uma caixa antiga depois da falha ao criar',
      () async {
        notifier.toggle(terror);
        await pumpEventQueue();
        lists.writes.single.fail(const RateLimitFailure());
        await pumpEventQueue();
        lists.listsCount = MovieList.maxPerAccount;
        await notifier.createAndAdd(ListName('Ação'));

        notifier.retryToggle();
        await pumpEventQueue();

        expect(lists.writes, hasLength(1));
      },
    );
  });
}

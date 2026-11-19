import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/core/error/failures.dart';
import 'package:ja_vi_esse_filme/features/auth/domain/entities/app_user.dart';
import 'package:ja_vi_esse_filme/features/auth/domain/entities/auth_state.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/list_name.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/movie_copy.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/movie_list.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/shelf_movie.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/usecases/add_movie_to_list.dart';
import 'package:ja_vi_esse_filme/features/shelf/presentation/state/movie_list_notifier.dart';
import 'package:ja_vi_esse_filme/features/shelf/presentation/state/movie_list_state.dart';

import '../../../../helpers/fake_movie_lists_repository.dart';

void main() {
  late FakeMovieListsRepository lists;
  late StreamController<AuthState> account;
  late MovieListNotifier notifier;

  final ana = AppUser(uid: 'ana123', displayName: 'Ana');
  final terror = MovieList(
    id: 'Lst0aBcDeFgHiJkLmNoP',
    name: ListName('Terror'),
  );
  final comedy = MovieList(
    id: 'Lst1aBcDeFgHiJkLmNoP',
    name: ListName('Comédia'),
  );
  final copy = MovieCopy(movieId: 550, title: 'Clube da Luta');
  final movie = ShelfMovie(
    copy: copy,
    cachedAt: DateTime.utc(2026, 11),
    marks: const {},
    lists: {terror.id: DateTime.utc(2026, 11, 2)},
  );

  MovieListNotifier newNotifier({MovieList? initial}) => MovieListNotifier(
    listId: terror.id,
    initial: initial,
    lists: lists,
    addMovie: AddMovieToList(lists),
    account: account.stream,
  );

  Future<void> signIn() async {
    account.add(SignedIn(ana));
    await pumpEventQueue();
  }

  Future<void> emit(List<MovieList> value) async {
    lists.emitLists(value);
    await pumpEventQueue();
  }

  setUp(() {
    lists = FakeMovieListsRepository();
    account = StreamController<AuthState>.broadcast();
    notifier = newNotifier();
  });

  tearDown(() async {
    notifier.dispose();
    await account.close();
  });

  group('leitura', () {
    test('deve começar carregando sem a lista tocada', () {
      expect(notifier.state, isA<MovieListLoading>());
    });

    test('deve começar com a lista tocada na Estante', () {
      notifier.dispose();
      notifier = newNotifier(initial: terror);

      expect(notifier.state, MovieListFound(terror));
    });

    test('deve achar a lista pelo id', () async {
      await signIn();

      await emit([comedy, terror]);

      expect(notifier.state, MovieListFound(terror));
    });

    test('deve seguir o nome novo vindo do stream', () async {
      await signIn();

      await emit([terror.rename(ListName('Suspense'))]);

      expect(
        notifier.state,
        MovieListFound(terror.rename(ListName('Suspense'))),
      );
    });

    test('deve dizer que a lista foi apagada', () async {
      await signIn();

      await emit([comedy]);

      expect(notifier.state, isA<MovieListGone>());
    });

    test('deve mostrar o erro da leitura', () async {
      await signIn();

      lists.emitListsError(const NetworkFailure());
      await pumpEventQueue();

      expect(notifier.state, isA<MovieListError>());
    });

    test('deve assinar de novo no tentar de novo', () async {
      await signIn();
      lists.emitListsError(const NetworkFailure());
      await pumpEventQueue();

      notifier.retry();

      expect(lists.watchListsCalls, 2);
    });

    test('deve ficar deslogado quando a conta sai', () async {
      await signIn();
      await emit([terror]);

      account.add(const SignedOut());
      await pumpEventQueue();

      expect(notifier.state, isA<MovieListSignedOut>());
    });
  });

  group('ações', () {
    setUp(() async {
      await signIn();
      await emit([terror]);
    });

    test('deve mostrar o nome novo na hora', () async {
      unawaited(notifier.rename(ListName('Suspense')));
      await pumpEventQueue();

      expect(
        notifier.state,
        MovieListFound(terror.rename(ListName('Suspense'))),
      );
    });

    test('deve voltar o nome quando o servidor recusa', () async {
      final renamed = notifier.rename(ListName('Suspense'));
      await pumpEventQueue();

      lists.writes.single.fail(const RateLimitFailure());
      await renamed.catchError((Object _) {});

      expect(notifier.state, MovieListFound(terror));
    });

    test('deve apagar a lista', () async {
      unawaited(notifier.delete());
      await pumpEventQueue();

      expect(lists.writes.single.kind, ListWriteKind.delete);
    });

    test('deve tirar o filme da lista', () async {
      unawaited(notifier.removeMovie(movie));
      await pumpEventQueue();

      expect(lists.writes.single.movie, movie);
    });

    test('deve pôr o filme de volta no desfazer', () async {
      unawaited(notifier.undoRemove(movie));
      await pumpEventQueue();

      expect(lists.writes.single.copy, copy);
    });

    test('deve entregar a recusa ao tirar o filme', () async {
      final removed = notifier.removeMovie(movie);
      await pumpEventQueue();

      lists.writes.single.fail(const RateLimitFailure());

      await expectLater(removed, throwsA(isA<RateLimitFailure>()));
    });
  });
}

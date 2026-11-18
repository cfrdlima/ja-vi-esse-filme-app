import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/core/error/failures.dart';
import 'package:ja_vi_esse_filme/features/auth/domain/entities/app_user.dart';
import 'package:ja_vi_esse_filme/features/auth/domain/entities/auth_state.dart';
import 'package:ja_vi_esse_filme/features/movies/presentation/state/paged_movies_state.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/movie_copy.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/shelf_mark.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/shelf_movie.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/shelf_page.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/repositories/movie_copy_source.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/usecases/expired_copy_renewer.dart';
import 'package:ja_vi_esse_filme/features/shelf/presentation/state/shelf_tab_notifier.dart';
import 'package:ja_vi_esse_filme/features/shelf/presentation/state/shelf_tab_state.dart';

import '../../../../helpers/fake_shelf_repository.dart';

/// Responde na hora com uma cópia nova e grava os pedidos.
class _CopySource implements MovieCopySource {
  final List<int> requestedIds = [];

  @override
  Future<MovieCopy> fetchCopy(int movieId) async {
    requestedIds.add(movieId);
    return MovieCopy(movieId: movieId, title: 'Novo $movieId');
  }
}

void main() {
  late FakeShelfRepository shelf;
  late StreamController<AuthState> account;
  late _CopySource source;
  late List<ExpiredCopyRenewer> renewers;
  late ShelfTabNotifier notifier;

  final now = DateTime.utc(2026, 11, 17);
  final ana = AppUser(uid: 'ana123', displayName: 'Ana');
  final bia = AppUser(uid: 'bia456', displayName: 'Bia');

  ShelfMovie movie(int id, {DateTime? cachedAt}) => ShelfMovie(
    copy: MovieCopy(movieId: id, title: 'Filme $id'),
    cachedAt: cachedAt ?? now,
    marks: {ShelfMark.watchlist: now},
  );

  ShelfPage page(List<int> ids, {bool hasMore = false}) =>
      ShelfPage(movies: [for (final id in ids) movie(id)], hasMore: hasMore);

  ShelfTabReady ready() => switch (notifier.state) {
    final ShelfTabReady state => state,
    final other => fail('esperava a aba pronta, veio $other'),
  };

  Future<void> signInAs(AppUser user) async {
    account.add(SignedIn(user));
    await pumpEventQueue();
  }

  Future<void> emitPage(ShelfPage page) async {
    shelf.emitShelf(page);
    await pumpEventQueue();
  }

  Future<void> emitError(Failure failure) async {
    shelf.emitShelfError(failure);
    await pumpEventQueue();
  }

  ShelfTabNotifier newNotifier() => ShelfTabNotifier(
    mark: ShelfMark.watchlist,
    shelf: shelf,
    account: account.stream,
    newRenewer: () {
      final renewer = ExpiredCopyRenewer(
        shelf: shelf,
        source: source,
        now: () => now,
      );
      renewers.add(renewer);
      return renewer;
    },
  );

  setUp(() {
    shelf = FakeShelfRepository();
    account = StreamController<AuthState>.broadcast();
    source = _CopySource();
    renewers = [];
    notifier = newNotifier();
  });

  tearDown(() async {
    notifier.dispose();
    await account.close();
  });

  group('ShelfTabNotifier', () {
    group('conta', () {
      test('deve começar carregando antes de saber a conta', () {
        expect(notifier.state, isA<ShelfTabLoading>());
      });

      test('deve ficar deslogado sem ninguém logado', () async {
        account.add(const SignedOut());
        await pumpEventQueue();

        expect(notifier.state, isA<ShelfTabSignedOut>());
      });

      test('deve tratar o erro da conta como deslogado', () async {
        account.addError(const NetworkFailure());
        await pumpEventQueue();

        expect(notifier.state, isA<ShelfTabSignedOut>());
      });

      test('deve assinar a aba da marca com o primeiro limite', () async {
        await signInAs(ana);

        expect(shelf.shelfCalls, [
          (mark: ShelfMark.watchlist, limit: ShelfTabNotifier.pageSize),
        ]);
      });

      test('deve carregar até a primeira página', () async {
        await signInAs(ana);

        expect(notifier.state, isA<ShelfTabLoading>());
      });

      test('não deve assinar de novo com a mesma conta', () async {
        await signInAs(ana);
        await signInAs(ana);

        expect(shelf.shelfCalls, hasLength(1));
      });

      test('deve assinar de novo quando a conta muda', () async {
        await signInAs(ana);
        await signInAs(bia);

        expect(shelf.shelfCalls, hasLength(2));
      });

      test('deve parar de ouvir a aba no logout', () async {
        await signInAs(ana);

        account.add(const SignedOut());
        await pumpEventQueue();

        expect(shelf.activeShelves, 0);
      });

      test('deve voltar ao primeiro limite quando a conta muda', () async {
        await signInAs(ana);
        await emitPage(page([1], hasMore: true));
        notifier.loadMore();
        await pumpEventQueue();

        await signInAs(bia);

        expect(shelf.shelfCalls.last.limit, ShelfTabNotifier.pageSize);
      });
    });

    group('página', () {
      test('deve mostrar os filmes da página', () async {
        await signInAs(ana);

        await emitPage(page([2, 1]));

        expect(ready().movies.map((m) => m.copy.movieId), [2, 1]);
      });

      test('deve ficar vazia sem filmes na marca', () async {
        await signInAs(ana);

        await emitPage(page([]));

        expect(notifier.state, isA<ShelfTabEmpty>());
      });

      test('deve dizer se há mais filmes', () async {
        await signInAs(ana);

        await emitPage(page([1], hasMore: true));

        expect(ready().hasMore, isTrue);
      });

      test('deve mostrar o erro da primeira página', () async {
        await signInAs(ana);

        await emitError(const NetworkFailure());

        expect(notifier.state, isA<ShelfTabError>());
      });

      test('deve assinar de novo no tentar de novo', () async {
        await signInAs(ana);
        await emitError(const NetworkFailure());

        notifier.retry();
        await pumpEventQueue();

        expect(shelf.shelfCalls, hasLength(2));
      });

      test('deve carregar de novo no tentar de novo', () async {
        await signInAs(ana);
        await emitError(const NetworkFailure());

        notifier.retry();
        await pumpEventQueue();

        expect(notifier.state, isA<ShelfTabLoading>());
      });

      test('deve manter os filmes com o erro depois da página', () async {
        await signInAs(ana);
        await emitPage(page([1]));

        await emitError(const NetworkFailure());

        expect(ready().movies, hasLength(1));
      });

      test('deve guardar o erro depois da página para o rodapé', () async {
        await signInAs(ana);
        await emitPage(page([1]));

        await emitError(const NetworkFailure());

        expect(
          ready().nextPage,
          isA<NextPageFailed>().having(
            (s) => s.failure,
            'failure',
            isA<NetworkFailure>(),
          ),
        );
      });

      test('deve mostrar o erro quando a aba vazia recebe um erro', () async {
        await signInAs(ana);
        await emitPage(page([]));

        await emitError(const NetworkFailure());

        expect(notifier.state, isA<ShelfTabError>());
      });

      test('deve carregar no tentar de novo da aba vazia com erro', () async {
        await signInAs(ana);
        await emitPage(page([]));
        await emitError(const NetworkFailure());

        notifier.retry();
        await pumpEventQueue();

        expect(notifier.state, isA<ShelfTabLoading>());
      });

      test('deve voltar a carregar quando o stream acaba', () async {
        await signInAs(ana);
        await emitPage(page([1]));

        shelf.endShelf();
        await pumpEventQueue();

        expect(notifier.state, isA<ShelfTabLoading>());
      });
    });

    group('mais filmes', () {
      Future<void> showFirstPage() async {
        await signInAs(ana);
        await emitPage(page([1], hasMore: true));
      }

      test('deve assinar com o limite maior', () async {
        await showFirstPage();

        notifier.loadMore();
        await pumpEventQueue();

        expect(shelf.shelfCalls.last.limit, ShelfTabNotifier.pageSize * 2);
      });

      test('deve manter os filmes enquanto carrega mais', () async {
        await showFirstPage();

        notifier.loadMore();
        await pumpEventQueue();

        expect(ready().movies, hasLength(1));
      });

      test('deve mostrar que carrega mais', () async {
        await showFirstPage();

        notifier.loadMore();
        await pumpEventQueue();

        expect(ready().nextPage, isA<NextPageLoading>());
      });

      test('deve parar de carregar mais quando a página nova chega', () async {
        await showFirstPage();
        notifier.loadMore();
        await pumpEventQueue();

        await emitPage(page([1, 2]));

        expect(ready().nextPage, isA<NextPageIdle>());
      });

      test('não deve pedir o mesmo limite duas vezes', () async {
        await showFirstPage();

        notifier
          ..loadMore()
          ..loadMore();
        await pumpEventQueue();

        expect(shelf.shelfCalls, hasLength(2));
      });

      test('não deve pedir mais quando acabou', () async {
        await signInAs(ana);
        await emitPage(page([1]));

        notifier.loadMore();
        await pumpEventQueue();

        expect(shelf.shelfCalls, hasLength(1));
      });

      test('deve parar de ouvir o limite anterior', () async {
        await showFirstPage();

        notifier.loadMore();
        await pumpEventQueue();

        expect(shelf.activeShelves, 1);
      });

      test('deve assinar de novo o limite maior no tentar de novo', () async {
        await showFirstPage();
        notifier.loadMore();
        await pumpEventQueue();
        await emitError(const NetworkFailure());

        notifier.retry();
        await pumpEventQueue();

        expect(shelf.shelfCalls.last.limit, ShelfTabNotifier.pageSize * 2);
      });

      test('não deve pedir mais com o erro no rodapé', () async {
        await showFirstPage();
        await emitError(const RateLimitFailure());

        notifier.loadMore();
        await pumpEventQueue();

        expect(shelf.shelfCalls, hasLength(1));
      });

      test('deve parar no teto de filmes por aba', () async {
        await signInAs(ana);
        for (
          var limit = ShelfTabNotifier.pageSize;
          limit < ShelfTabNotifier.maxLimit;
          limit += ShelfTabNotifier.pageSize
        ) {
          await emitPage(page([1], hasMore: true));
          notifier.loadMore();
          await pumpEventQueue();
        }
        await emitPage(page([1], hasMore: true));

        notifier.loadMore();
        await pumpEventQueue();

        expect(shelf.shelfCalls.last.limit, ShelfTabNotifier.maxLimit);
      });

      test('deve dizer que chegou ao teto quando ainda há mais', () async {
        await signInAs(ana);
        for (
          var limit = ShelfTabNotifier.pageSize;
          limit < ShelfTabNotifier.maxLimit;
          limit += ShelfTabNotifier.pageSize
        ) {
          await emitPage(page([1], hasMore: true));
          notifier.loadMore();
          await pumpEventQueue();
        }

        await emitPage(page([1], hasMore: true));

        expect(ready().capped, isTrue);
      });

      test('não deve dizer que chegou ao teto antes dele', () async {
        await showFirstPage();

        expect(ready().capped, isFalse);
      });

      test('deve tirar o erro do rodapé no tentar de novo', () async {
        await showFirstPage();
        await emitError(const NetworkFailure());

        notifier.retry();
        await pumpEventQueue();

        expect(ready().nextPage, isNot(isA<NextPageFailed>()));
      });
    });

    group('cópia vencida', () {
      test('deve renovar a cópia vencida da página', () async {
        await signInAs(ana);

        await emitPage(
          ShelfPage(
            movies: [movie(7, cachedAt: now.subtract(ShelfMovie.copyMaxAge))],
            hasMore: false,
          ),
        );

        expect(shelf.renewedCopies.single.movieId, 7);
      });

      test('não deve renovar a cópia dentro do prazo', () async {
        await signInAs(ana);

        await emitPage(page([7]));

        expect(source.requestedIds, isEmpty);
      });

      test('deve trocar a renovação quando a conta muda', () async {
        await signInAs(ana);
        await signInAs(bia);

        expect(renewers, hasLength(2));
      });
    });

    test('deve parar de ouvir a aba no dispose', () async {
      final local = newNotifier();
      await signInAs(ana);

      local.dispose();
      await pumpEventQueue();

      expect(shelf.activeShelves, 1);
    });
  });
}

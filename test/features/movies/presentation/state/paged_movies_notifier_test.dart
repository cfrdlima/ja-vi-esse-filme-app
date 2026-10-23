import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/core/error/failures.dart';
import 'package:ja_vi_esse_filme/features/movies/domain/entities/movie.dart';
import 'package:ja_vi_esse_filme/features/movies/domain/entities/movie_category.dart';
import 'package:ja_vi_esse_filme/features/movies/domain/entities/movie_page.dart';
import 'package:ja_vi_esse_filme/features/movies/presentation/state/category_movies_notifier.dart';
import 'package:ja_vi_esse_filme/features/movies/presentation/state/paged_movies_notifier.dart';
import 'package:ja_vi_esse_filme/features/movies/presentation/state/paged_movies_state.dart';

import '../../../../helpers/fake_movie_repository.dart';

void main() {
  late FakeMovieRepository repository;
  late PagedMoviesNotifier notifier;

  setUp(() {
    repository = FakeMovieRepository();
    notifier = CategoryMoviesNotifier(
      repository: repository,
      category: MovieCategory.topRated,
    );
  });

  tearDown(() => notifier.dispose());

  Future<void> loadFirstPage({int totalPages = 3}) async {
    final future = notifier.load();
    repository.complete(moviePage(page: 1, totalPages: totalPages));
    await future;
  }

  group('primeira página', () {
    test('deve começar carregando', () {
      expect(notifier.state, isA<PagedMoviesLoading>());
    });

    test('deve mostrar os filmes da primeira página', () async {
      await loadFirstPage();

      final state = notifier.state as PagedMoviesLoaded;
      expect(state.movies.map((m) => m.id), [100, 101]);
    });

    test('deve ficar vazio quando a primeira página não tem filmes', () async {
      final future = notifier.load();
      repository.complete(moviePage(page: 1, count: 0, totalPages: 0));
      await future;

      expect(notifier.state, isA<PagedMoviesEmpty>());
    });

    test('deve guardar a falha quando a primeira página falha', () async {
      final future = notifier.load();
      repository.fail(const NetworkFailure());
      await future;

      expect(
        notifier.state,
        isA<PagedMoviesError>().having(
          (s) => s.failure,
          'failure',
          isA<NetworkFailure>(),
        ),
      );
    });

    test('deve voltar a carregar ao tentar de novo depois do erro', () async {
      final failed = notifier.load();
      repository.fail(const NetworkFailure());
      await failed;

      final retry = notifier.load();

      expect(notifier.state, isA<PagedMoviesLoading>());
      repository.complete(moviePage(page: 1));
      await retry;
    });

    test('não deve pedir a primeira página de novo enquanto carrega', () async {
      final future = notifier.load();
      final ignored = notifier.load();
      repository.complete(moviePage(page: 1));
      await Future.wait([future, ignored]);

      expect(repository.requestedPages, [1]);
    });
  });

  group('primeira página, casos de borda', () {
    test('deve ignorar filme repetido dentro da primeira página', () async {
      final future = notifier.load();
      repository.complete(
        const MoviePage(
          movies: [
            Movie(id: 1, title: 'A'),
            Movie(id: 1, title: 'A'),
          ],
          page: 1,
          totalPages: 1,
        ),
      );
      await future;

      final state = notifier.state as PagedMoviesLoaded;
      expect(state.movies.map((m) => m.id), [1]);
    });

    test(
      'deve virar erro inesperado quando o repositório lança outra exceção',
      () async {
        final future = notifier.load();
        repository.fail(Exception('inesperada'));
        await future;

        expect(
          notifier.state,
          isA<PagedMoviesError>().having(
            (s) => s.failure,
            'failure',
            isA<UnexpectedFailure>(),
          ),
        );
      },
    );
  });

  group('próxima página', () {
    test('deve acrescentar os filmes da próxima página', () async {
      await loadFirstPage();

      final future = notifier.loadMore();
      repository.complete(moviePage(page: 2));
      await future;

      final state = notifier.state as PagedMoviesLoaded;
      expect(state.movies.map((m) => m.id), [100, 101, 200, 201]);
    });

    test('deve sinalizar o carregamento da próxima página', () async {
      await loadFirstPage();

      final future = notifier.loadMore();

      final state = notifier.state as PagedMoviesLoaded;
      expect(state.nextPage, isA<NextPageLoading>());
      repository.complete(moviePage(page: 2));
      await future;
    });

    test('não deve pedir a mesma página duas vezes', () async {
      await loadFirstPage();

      final future = notifier.loadMore();
      final ignored = notifier.loadMore();
      repository.complete(moviePage(page: 2));
      await Future.wait([future, ignored]);

      expect(repository.requestedPages, [1, 2]);
    });

    test('não deve pedir além da última página', () async {
      await loadFirstPage(totalPages: 1);

      await notifier.loadMore();

      expect(repository.requestedPages, [1]);
    });

    test('não deve pedir a próxima página antes da primeira', () async {
      await notifier.loadMore();

      expect(repository.requestedPages, isEmpty);
    });

    test('deve manter os filmes quando a próxima página falha', () async {
      await loadFirstPage();

      final future = notifier.loadMore();
      repository.fail(const RateLimitFailure());
      await future;

      final state = notifier.state as PagedMoviesLoaded;
      expect(state.movies.length, 2);
    });

    test('deve guardar a falha da próxima página', () async {
      await loadFirstPage();

      final future = notifier.loadMore();
      repository.fail(const RateLimitFailure(retryAfter: Duration(seconds: 7)));
      await future;

      final state = notifier.state as PagedMoviesLoaded;
      expect(
        state.nextPage,
        isA<NextPageFailed>().having(
          (s) => s.failure,
          'failure',
          isA<RateLimitFailure>().having(
            (f) => f.retryAfter,
            'retryAfter',
            const Duration(seconds: 7),
          ),
        ),
      );
    });

    test('não deve pedir de novo pela rolagem depois da falha', () async {
      await loadFirstPage();
      final failed = notifier.loadMore();
      repository.fail(const RateLimitFailure());
      await failed;

      await notifier.loadMore();

      expect(repository.requestedPages, [1, 2]);
    });

    test(
      'deve pedir a mesma página ao tentar de novo depois da falha',
      () async {
        await loadFirstPage();
        final failed = notifier.loadMore();
        repository.fail(const NetworkFailure());
        await failed;

        final retry = notifier.retryNextPage();
        repository.complete(moviePage(page: 2));
        await retry;

        expect(repository.requestedPages, [1, 2, 2]);
      },
    );

    test('não deve tentar de novo a próxima página sem falha', () async {
      await loadFirstPage();

      await notifier.retryNextPage();

      expect(repository.requestedPages, [1]);
    });

    test('deve parar de ter mais páginas na última', () async {
      await loadFirstPage(totalPages: 2);

      final future = notifier.loadMore();
      repository.complete(moviePage(page: 2, totalPages: 2));
      await future;

      final state = notifier.state as PagedMoviesLoaded;
      expect(state.hasMore, isFalse);
    });

    test('deve ignorar filme repetido entre páginas', () async {
      await loadFirstPage();

      final future = notifier.loadMore();
      repository.complete(
        const MoviePage(
          movies: [
            Movie(id: 101, title: 'Repetido'),
            Movie(id: 200, title: 'Novo'),
          ],
          page: 2,
          totalPages: 3,
        ),
      );
      await future;

      final state = notifier.state as PagedMoviesLoaded;
      expect(state.movies.map((m) => m.id), [100, 101, 200]);
    });

    test(
      'deve avançar pela página pedida, e não pela que a resposta diz',
      () async {
        await loadFirstPage();
        final second = notifier.loadMore();
        repository.complete(moviePage(page: 1));
        await second;

        unawaited(notifier.loadMore());

        expect(repository.requestedPages, [1, 2, 3]);
      },
    );

    test(
      'deve descartar a próxima página que chega depois de recarregar',
      () async {
        await loadFirstPage();
        final stale = notifier.loadMore();
        final reload = notifier.load();

        repository.complete(moviePage(page: 2));
        await stale;

        expect(notifier.state, isA<PagedMoviesLoading>());
        repository.complete(moviePage(page: 1, count: 1));
        await reload;
      },
    );

    test(
      'deve marcar falha na próxima página com exceção inesperada',
      () async {
        await loadFirstPage();

        final future = notifier.loadMore();
        repository.fail(Exception('inesperada'));
        await future;

        final state = notifier.state as PagedMoviesLoaded;
        expect(
          state.nextPage,
          isA<NextPageFailed>().having(
            (s) => s.failure,
            'failure',
            isA<UnexpectedFailure>(),
          ),
        );
      },
    );
  });

  test('não deve notificar depois de descartado', () async {
    final future = notifier.load();
    notifier.dispose();
    repository.complete(moviePage(page: 1));

    await expectLater(future, completes);
    notifier = CategoryMoviesNotifier(
      repository: repository,
      category: MovieCategory.topRated,
    );
  });

  group('descartado', () {
    // O tearDown descarta o notifier, e descartar duas vezes é erro.
    void disposeAndReplace() {
      final disposed = notifier;
      notifier = CategoryMoviesNotifier(
        repository: FakeMovieRepository(),
        category: MovieCategory.topRated,
      );
      disposed.dispose();
    }

    test('não deve pedir a primeira página', () {
      final disposed = notifier;
      disposeAndReplace();

      // Sem await: se o pedido saísse, ficaria pendente no fake.
      unawaited(disposed.load());

      expect(repository.requestedPages, isEmpty);
    });

    test('não deve pedir a próxima página', () async {
      await loadFirstPage();
      final disposed = notifier;
      disposeAndReplace();

      // Sem await: se o pedido saísse, ficaria pendente no fake.
      unawaited(disposed.loadMore());

      expect(repository.requestedPages, [1]);
    });

    test('não deve repetir a próxima página que falhou', () async {
      await loadFirstPage();
      final future = notifier.loadMore();
      repository.fail(const NetworkFailure());
      await future;
      final disposed = notifier;
      disposeAndReplace();

      // Sem await: se o pedido saísse, ficaria pendente no fake.
      unawaited(disposed.retryNextPage());

      expect(repository.requestedPages, [1, 2]);
    });
  });
}

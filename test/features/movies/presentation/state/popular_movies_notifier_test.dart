import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/core/error/failures.dart';
import 'package:ja_vi_esse_filme/features/movies/presentation/state/popular_movies_notifier.dart';
import 'package:ja_vi_esse_filme/features/movies/presentation/state/popular_movies_state.dart';

import '../../fakes/fake_movie_repository.dart';

void main() {
  late FakeMovieRepository repository;
  late PopularMoviesNotifier notifier;

  setUp(() {
    repository = FakeMovieRepository();
    notifier = PopularMoviesNotifier(repository: repository);
  });

  tearDown(() => notifier.dispose());

  Future<void> loadFirstPage({int totalPages = 3}) async {
    final future = notifier.load();
    repository.complete(moviePage(page: 1, totalPages: totalPages));
    await future;
  }

  group('primeira página', () {
    test('deve começar carregando', () {
      expect(notifier.state, isA<PopularMoviesLoading>());
    });

    test('deve mostrar os filmes da primeira página', () async {
      await loadFirstPage();

      final state = notifier.state as PopularMoviesLoaded;
      expect(state.movies.map((m) => m.id), [100, 101]);
    });

    test('deve ficar vazio quando a primeira página não tem filmes', () async {
      final future = notifier.load();
      repository.complete(moviePage(page: 1, count: 0, totalPages: 0));
      await future;

      expect(notifier.state, isA<PopularMoviesEmpty>());
    });

    test('deve guardar a falha quando a primeira página falha', () async {
      final future = notifier.load();
      repository.fail(const NetworkFailure());
      await future;

      expect(
        notifier.state,
        isA<PopularMoviesError>().having(
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

      expect(notifier.state, isA<PopularMoviesLoading>());
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

  group('próxima página', () {
    test('deve acrescentar os filmes da próxima página', () async {
      await loadFirstPage();

      final future = notifier.loadMore();
      repository.complete(moviePage(page: 2));
      await future;

      final state = notifier.state as PopularMoviesLoaded;
      expect(state.movies.map((m) => m.id), [100, 101, 200, 201]);
    });

    test('deve sinalizar o carregamento da próxima página', () async {
      await loadFirstPage();

      final future = notifier.loadMore();

      final state = notifier.state as PopularMoviesLoaded;
      expect(state.nextPage, NextPageStatus.loading);
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

      final state = notifier.state as PopularMoviesLoaded;
      expect((state.movies.length, state.nextPage), (2, NextPageStatus.failed));
    });

    test('deve pedir a mesma página de novo depois da falha', () async {
      await loadFirstPage();
      final failed = notifier.loadMore();
      repository.fail(const NetworkFailure());
      await failed;

      final retry = notifier.loadMore();
      repository.complete(moviePage(page: 2));
      await retry;

      expect(repository.requestedPages, [1, 2, 2]);
    });

    test('deve parar de ter mais páginas na última', () async {
      await loadFirstPage(totalPages: 2);

      final future = notifier.loadMore();
      repository.complete(moviePage(page: 2, totalPages: 2));
      await future;

      final state = notifier.state as PopularMoviesLoaded;
      expect(state.hasMore, isFalse);
    });

    test('deve ignorar filme repetido entre páginas', () async {
      await loadFirstPage();

      final future = notifier.loadMore();
      repository.complete(moviePage(page: 1));
      await future;

      final state = notifier.state as PopularMoviesLoaded;
      expect(state.movies.map((m) => m.id), [100, 101]);
    });
  });

  test('não deve notificar depois de descartado', () async {
    final future = notifier.load();
    notifier.dispose();
    repository.complete(moviePage(page: 1));

    await expectLater(future, completes);
    notifier = PopularMoviesNotifier(repository: repository);
  });
}

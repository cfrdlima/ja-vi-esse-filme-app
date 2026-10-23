import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/core/error/failures.dart';
import 'package:ja_vi_esse_filme/features/movies/domain/entities/movie_details.dart';
import 'package:ja_vi_esse_filme/features/movies/presentation/state/movie_details_notifier.dart';
import 'package:ja_vi_esse_filme/features/movies/presentation/state/movie_details_state.dart';

import '../../../../helpers/fake_movie_repository.dart';

void main() {
  late FakeMovieRepository repository;
  final details = MovieDetails(id: 7, title: 'Filme', overview: '');

  setUp(() => repository = FakeMovieRepository());

  MovieDetailsNotifier notifierFor(int? movieId) {
    final notifier = MovieDetailsNotifier(
      repository: repository,
      movieId: movieId,
    );
    addTearDown(notifier.dispose);
    return notifier;
  }

  test('deve começar carregando', () {
    final notifier = notifierFor(7);

    expect(notifier.state, isA<MovieDetailsLoading>());
  });

  test('deve pedir os detalhes do id recebido', () {
    final notifier = notifierFor(7);

    unawaited(notifier.load());

    expect(repository.requestedDetails, [7]);
  });

  test('deve mostrar os detalhes quando o pedido dá certo', () async {
    final notifier = notifierFor(7);

    final future = notifier.load();
    repository.completeDetails(details);
    await future;

    expect((notifier.state as MovieDetailsLoaded).details, same(details));
  });

  test('deve ir para não encontrado quando o TMDB responde 404', () async {
    final notifier = notifierFor(7);

    final future = notifier.load();
    repository.failDetails(const NotFoundFailure());
    await future;

    expect(notifier.state, isA<MovieDetailsNotFound>());
  });

  test('deve guardar a falha quando o pedido falha', () async {
    final notifier = notifierFor(7);
    const failure = RateLimitFailure(retryAfter: Duration(seconds: 3));

    final future = notifier.load();
    repository.failDetails(failure);
    await future;

    expect((notifier.state as MovieDetailsError).failure, same(failure));
  });

  test('deve tratar exceção fora das falhas tipadas como inesperada', () async {
    final notifier = notifierFor(7);

    final future = notifier.load();
    repository.failDetails(const FormatException('json'));
    await future;

    expect(
      (notifier.state as MovieDetailsError).failure,
      isA<UnexpectedFailure>(),
    );
  });

  group('id inválido na rota', () {
    for (final (description, movieId) in [
      ('que não é número', null),
      ('zero', 0),
      ('negativo', -3),
    ]) {
      test('deve ir para não encontrado com id $description', () async {
        final notifier = notifierFor(movieId);

        await notifier.load();

        expect(notifier.state, isA<MovieDetailsNotFound>());
      });

      test('não deve pedir ao TMDB com id $description', () async {
        final notifier = notifierFor(movieId);

        await notifier.load();

        expect(repository.requestedDetails, isEmpty);
      });
    }
  });

  group('tentar de novo depois de uma falha', () {
    late MovieDetailsNotifier notifier;

    setUp(() async {
      notifier = notifierFor(7);
      final first = notifier.load();
      repository.failDetails(const NetworkFailure());
      await first;
    });

    test('deve passar por carregando antes dos detalhes', () async {
      final states = <Type>[];
      notifier.addListener(() => states.add(notifier.state.runtimeType));

      final retry = notifier.load();
      repository.completeDetails(details);
      await retry;

      expect(states, [MovieDetailsLoading, MovieDetailsLoaded]);
    });

    test('deve pedir de novo ao TMDB', () async {
      final retry = notifier.load();
      repository.completeDetails(details);
      await retry;

      expect(repository.requestedDetails, [7, 7]);
    });
  });

  test('não deve pedir de novo enquanto o pedido está em andamento', () {
    final notifier = notifierFor(7);

    unawaited(notifier.load());
    unawaited(notifier.load());

    expect(repository.requestedDetails, [7]);
  });

  group('resposta depois do descarte', () {
    // O `ChangeNotifier` já tira os ouvintes no `dispose`; o que a guarda
    // evita é o `notifyListeners` de um notifier descartado, que lança.
    test('deve terminar sem erro', () async {
      final notifier = MovieDetailsNotifier(repository: repository, movieId: 7);
      final future = notifier.load();
      notifier.dispose();

      repository.completeDetails(details);

      await expectLater(future, completes);
    });

    test('não deve mudar o estado', () async {
      final notifier = MovieDetailsNotifier(repository: repository, movieId: 7);
      final future = notifier.load();
      notifier.dispose();

      repository.completeDetails(details);
      await future;

      expect(notifier.state, isA<MovieDetailsLoading>());
    });
  });
}

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/core/error/failures.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/movie_copy.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/shelf_mark.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/shelf_movie.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/repositories/movie_copy_source.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/usecases/expired_copy_renewer.dart';

import '../../../../helpers/fake_shelf_repository.dart';

/// Cada pedido fica pendente até o teste completá-lo.
class _FakeCopySource implements MovieCopySource {
  final Map<int, Completer<MovieCopy>> requests = {};

  List<int> get requestedIds => requests.keys.toList();

  @override
  Future<MovieCopy> fetchCopy(int movieId) =>
      (requests[movieId] = Completer<MovieCopy>()).future;

  void answer(int movieId) => requests[movieId]!.complete(
    MovieCopy(movieId: movieId, title: 'Novo $movieId', posterPath: '/n.jpg'),
  );

  void fail(int movieId, Failure failure) =>
      requests[movieId]!.completeError(failure);
}

void main() {
  final now = DateTime.utc(2026, 11, 17);
  final expiredAt = now.subtract(ShelfMovie.copyMaxAge);
  final freshAt = now.subtract(const Duration(days: 1));

  ShelfMovie movie(int id, {required DateTime cachedAt}) => ShelfMovie(
    copy: MovieCopy(movieId: id, title: 'Velho $id'),
    cachedAt: cachedAt,
    marks: {ShelfMark.watched: freshAt},
  );

  late FakeShelfRepository shelf;
  late _FakeCopySource source;
  late ExpiredCopyRenewer renewer;

  setUp(() {
    shelf = FakeShelfRepository();
    source = _FakeCopySource();
    renewer = ExpiredCopyRenewer(shelf: shelf, source: source, now: () => now);
  });

  group('ExpiredCopyRenewer', () {
    test('deve regravar a cópia vencida com a cópia nova do TMDB', () async {
      renewer.renew([movie(1, cachedAt: expiredAt)]);
      await pumpEventQueue();

      source.answer(1);
      await pumpEventQueue();

      expect(shelf.renewedCopies.single.title, 'Novo 1');
    });

    test('não deve buscar a cópia dentro do prazo', () async {
      renewer.renew([movie(1, cachedAt: freshAt)]);
      await pumpEventQueue();

      expect(source.requestedIds, isEmpty);
    });

    test('não deve buscar de novo um filme já pedido', () async {
      renewer.renew([movie(1, cachedAt: expiredAt)]);
      await pumpEventQueue();
      source.answer(1);
      await pumpEventQueue();

      renewer.renew([movie(1, cachedAt: expiredAt)]);
      await pumpEventQueue();

      expect(source.requests, hasLength(1));
    });

    test('deve buscar um filme de cada vez', () async {
      renewer.renew([
        movie(1, cachedAt: expiredAt),
        movie(2, cachedAt: expiredAt),
      ]);
      await pumpEventQueue();

      expect(source.requestedIds, [1]);
    });

    test('deve buscar o próximo depois de terminar o anterior', () async {
      renewer.renew([
        movie(1, cachedAt: expiredAt),
        movie(2, cachedAt: expiredAt),
      ]);
      await pumpEventQueue();

      source.answer(1);
      await pumpEventQueue();

      expect(source.requestedIds, [1, 2]);
    });

    test(
      'deve juntar à fila os filmes de um pedido feito durante outro',
      () async {
        renewer.renew([movie(1, cachedAt: expiredAt)]);
        await pumpEventQueue();
        renewer.renew([movie(2, cachedAt: expiredAt)]);
        await pumpEventQueue();

        source.answer(1);
        await pumpEventQueue();

        expect(source.requestedIds, [1, 2]);
      },
    );

    test('não deve esperar a escrita no Firestore para seguir', () async {
      shelf.holdRenewals = true;
      renewer.renew([
        movie(1, cachedAt: expiredAt),
        movie(2, cachedAt: expiredAt),
      ]);
      await pumpEventQueue();

      source.answer(1);
      await pumpEventQueue();

      expect(source.requestedIds, [1, 2]);
    });

    test('deve seguir para o próximo quando o filme sumiu do TMDB', () async {
      renewer.renew([
        movie(1, cachedAt: expiredAt),
        movie(2, cachedAt: expiredAt),
      ]);
      await pumpEventQueue();

      source.fail(1, const NotFoundFailure());
      await pumpEventQueue();

      expect(source.requestedIds, [1, 2]);
    });

    test('deve parar a fila no limite de requisições', () async {
      renewer.renew([
        movie(1, cachedAt: expiredAt),
        movie(2, cachedAt: expiredAt),
      ]);
      await pumpEventQueue();

      source.fail(1, const RateLimitFailure());
      await pumpEventQueue();

      expect(source.requestedIds, [1]);
    });

    test('deve parar a fila sem rede', () async {
      renewer.renew([
        movie(1, cachedAt: expiredAt),
        movie(2, cachedAt: expiredAt),
      ]);
      await pumpEventQueue();

      source.fail(1, const NetworkFailure());
      await pumpEventQueue();

      expect(source.requestedIds, [1]);
    });

    test('deve tentar de novo num pedido depois de parar a fila', () async {
      renewer.renew([movie(1, cachedAt: expiredAt)]);
      await pumpEventQueue();
      source.fail(1, const NetworkFailure());
      await pumpEventQueue();
      source.requests.clear();

      renewer.renew([movie(1, cachedAt: expiredAt)]);
      await pumpEventQueue();

      expect(source.requestedIds, [1]);
    });

    test('não deve regravar depois do dispose', () async {
      renewer.renew([movie(1, cachedAt: expiredAt)]);
      await pumpEventQueue();

      renewer.dispose();
      source.answer(1);
      await pumpEventQueue();

      expect(shelf.renewedCopies, isEmpty);
    });
  });
}

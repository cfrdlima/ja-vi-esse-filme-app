import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/core/error/failures.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/list_name.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/movie_list.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/usecases/create_movie_list.dart';

import '../../../../helpers/fake_movie_lists_repository.dart';

void main() {
  late FakeMovieListsRepository lists;
  late CreateMovieList create;
  late MovieList terror;

  setUp(() {
    lists = FakeMovieListsRepository();
    create = CreateMovieList(lists);
    terror = lists.newList(ListName('Terror'));
  });

  group('CreateMovieList', () {
    test('deve gravar a lista abaixo do teto', () async {
      lists.listsCount = MovieList.maxPerAccount - 1;

      unawaited(create(terror));
      await pumpEventQueue();

      expect(lists.writes.single.list, terror);
    });

    test('deve recusar a lista no teto', () async {
      lists.listsCount = MovieList.maxPerAccount;

      await expectLater(create(terror), throwsA(isA<ListLimitFailure>()));
    });

    test('não deve gravar nada no teto', () async {
      lists.listsCount = MovieList.maxPerAccount;

      await create(terror).then((_) {}, onError: (Object _) {});

      expect(lists.writes, isEmpty);
    });

    test('deve repassar a falha da contagem sem gravar', () async {
      lists.countError = const NetworkFailure();

      await expectLater(create(terror), throwsA(isA<NetworkFailure>()));
    });

    // Passado o teto, quem chama pode pôr um filme na lista nova sem
    // esperar o servidor, que offline demora (decisão 019).
    test('deve devolver a escrita antes de o servidor confirmar', () async {
      final created = await create(terror);

      lists.writes.single.complete();

      await expectLater(created.saved, completes);
    });

    test('deve entregar na escrita a recusa do servidor', () async {
      final created = await create(terror);

      lists.writes.single.fail(const RateLimitFailure());

      await expectLater(created.saved, throwsA(isA<RateLimitFailure>()));
    });
  });
}

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/core/error/failures.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/list_name.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/movie_copy.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/movie_list.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/shelf_entry.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/shelf_mark.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/shelf_movie.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/usecases/add_movie_to_list.dart';

import '../../../../helpers/fake_movie_lists_repository.dart';

void main() {
  final copy = MovieCopy(movieId: 550, title: 'Clube da Luta');
  final at = DateTime.utc(2026, 11, 18);

  late FakeMovieListsRepository lists;
  late AddMovieToList add;
  late MovieList terror;

  setUp(() {
    lists = FakeMovieListsRepository();
    add = AddMovieToList(lists);
    terror = lists.newList(ListName('Terror'));
  });

  ShelfEntry inTerror() => OnShelf(
    ShelfMovie(
      copy: copy,
      cachedAt: at,
      marks: const {},
      lists: {terror.id: at},
    ),
  );

  ShelfEntry watchedOnly() => OnShelf(
    ShelfMovie(copy: copy, cachedAt: at, marks: {ShelfMark.watched: at}),
  );

  group('AddMovieToList', () {
    test('deve pôr o filme fora da Estante na lista', () async {
      unawaited(add(copy, terror, current: const NotOnShelf()));
      await pumpEventQueue();

      expect(lists.writes.single.copy, copy);
    });

    test('deve pôr o filme marcado na lista', () async {
      unawaited(add(copy, terror, current: watchedOnly()));
      await pumpEventQueue();

      expect(lists.writes.single.list, terror);
    });

    test('deve aceitar a lista com um filme a menos que o teto', () async {
      lists.moviesCount[terror.id] = MovieList.maxMovies - 1;

      unawaited(add(copy, terror, current: const NotOnShelf()));
      await pumpEventQueue();

      expect(lists.writes, hasLength(1));
    });

    test('deve recusar a lista cheia', () async {
      lists.moviesCount[terror.id] = MovieList.maxMovies;

      await expectLater(
        add(copy, terror, current: const NotOnShelf()),
        throwsA(isA<ListFullFailure>()),
      );
    });

    test('não deve gravar nada na lista cheia', () async {
      lists.moviesCount[terror.id] = MovieList.maxMovies;

      await add(
        copy,
        terror,
        current: const NotOnShelf(),
      ).catchError((Object _) {});

      expect(lists.writes, isEmpty);
    });

    // As regras recusam regravar a hora de uma lista que já tem o filme.
    test('não deve gravar o filme que já está na lista', () async {
      await add(copy, terror, current: inTerror());

      expect(lists.writes, isEmpty);
    });

    test('deve repassar a falha da contagem sem gravar', () async {
      lists.countError = const NetworkFailure();

      await expectLater(
        add(copy, terror, current: const NotOnShelf()),
        throwsA(isA<NetworkFailure>()),
      );
    });
  });
}

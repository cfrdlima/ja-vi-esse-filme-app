import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/movie_copy.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/shelf_mark.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/shelf_movie.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/watched_on.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/usecases/choose_watched_on.dart';

import '../../../../helpers/fake_shelf_repository.dart';

void main() {
  // Meio-dia local: longe da virada do dia em qualquer fuso de teste.
  final now = DateTime(2026, 11, 18, 12);
  final today = WatchedOn(year: 2026, month: 11, day: 18);
  final watchedAt = DateTime(2026, 11, 10, 20);

  ShelfMovie watched({WatchedOn? watchedOn}) => ShelfMovie(
    copy: MovieCopy(movieId: 550, title: 'Clube da Luta'),
    cachedAt: watchedAt,
    marks: {ShelfMark.watched: watchedAt},
    watchedOn: watchedOn,
  );

  late FakeShelfRepository shelf;
  late ChooseWatchedOn choose;

  setUp(() {
    shelf = FakeShelfRepository();
    choose = ChooseWatchedOn(shelf: shelf, now: () => now);
  });

  group('ChooseWatchedOn', () {
    test('deve gravar o dia de hoje', () {
      unawaited(choose(watched(), today));

      expect(shelf.personalWrites.single.value, today);
    });

    test('deve gravar um dia passado', () {
      final day = WatchedOn(year: 1999, month: 3, day: 5);

      unawaited(choose(watched(), day));

      expect(shelf.personalWrites.single.value, day);
    });

    test('deve recusar o dia de amanhã', () {
      final tomorrow = WatchedOn(year: 2026, month: 11, day: 19);

      expect(() => choose(watched(), tomorrow), throwsArgumentError);
    });

    test('não deve gravar o dia de amanhã', () {
      final tomorrow = WatchedOn(year: 2026, month: 11, day: 19);

      expect(() => choose(watched(), tomorrow), throwsArgumentError);
      expect(shelf.personalWrites, isEmpty);
    });

    test('deve devolver o futuro da escrita', () async {
      final result = choose(watched(), today);
      shelf.personalWrites.single.complete();

      await expectLater(result, completes);
    });

    test('deve dizer qual é o dia de hoje para o seletor', () {
      expect(choose.today(), today);
    });

    test('deve sugerir o dia escolhido antes', () {
      final day = WatchedOn(year: 2026, month: 11, day: 1);

      expect(choose.suggestionFor(watched(watchedOn: day)), day);
    });

    test('deve sugerir o dia local em que o Assistido entrou', () {
      expect(
        choose.suggestionFor(watched()),
        WatchedOn(year: 2026, month: 11, day: 10),
      );
    });
  });
}

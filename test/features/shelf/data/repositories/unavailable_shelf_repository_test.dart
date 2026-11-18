import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/core/error/failures.dart';
import 'package:ja_vi_esse_filme/features/shelf/data/repositories/unavailable_shelf_repository.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/movie_copy.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/rating.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/shelf_mark.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/shelf_movie.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/watched_on.dart';

void main() {
  const repository = UnavailableShelfRepository();
  final copy = MovieCopy(movieId: 550, title: 'Clube da Luta');

  test('deve falhar a leitura com SignInRequiredFailure', () async {
    await expectLater(
      repository.watchMovie(550),
      emitsError(isA<SignInRequiredFailure>()),
    );
  });

  test('deve falhar a Estante com SignInRequiredFailure', () async {
    await expectLater(
      repository.watchShelf(ShelfMark.watched, limit: 20),
      emitsError(isA<SignInRequiredFailure>()),
    );
  });

  test('deve falhar a marca com SignInRequiredFailure', () async {
    await expectLater(
      repository.addMark(copy, ShelfMark.watched),
      throwsA(isA<SignInRequiredFailure>()),
    );
  });

  test('deve falhar o desmarcar com SignInRequiredFailure', () async {
    final movie = ShelfMovie(
      copy: copy,
      cachedAt: DateTime.utc(2026, 11),
      marks: {ShelfMark.watched: DateTime.utc(2026, 11)},
    );

    await expectLater(
      repository.removeMark(movie, ShelfMark.watched),
      throwsA(isA<SignInRequiredFailure>()),
    );
  });

  test('deve falhar a renovação da cópia com SignInRequiredFailure', () async {
    await expectLater(
      repository.renewCopy(copy),
      throwsA(isA<SignInRequiredFailure>()),
    );
  });

  final watched = ShelfMovie(
    copy: copy,
    cachedAt: DateTime.utc(2026, 11),
    marks: {ShelfMark.watched: DateTime.utc(2026, 11)},
  );
  final day = WatchedOn(year: 2026, month: 11, day: 1);

  for (final (name, write) in <(String, Future<void> Function())>[
    ('a nota', () => repository.rate(watched, Rating(7))),
    ('tirar a nota', () => repository.clearRating(watched)),
    ('o dia', () => repository.setWatchedOn(watched, day)),
    ('tirar o dia', () => repository.clearWatchedOn(watched)),
  ]) {
    test('deve falhar $name com SignInRequiredFailure', () async {
      await expectLater(write(), throwsA(isA<SignInRequiredFailure>()));
    });
  }

  test('deve concluir o fechamento, porque não há stream aberto', () async {
    await expectLater(repository.closeStreams(), completes);
  });
}

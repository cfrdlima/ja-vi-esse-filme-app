import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/core/error/failures.dart';
import 'package:ja_vi_esse_filme/features/shelf/data/repositories/unavailable_shelf_repository.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/movie_copy.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/shelf_mark.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/shelf_movie.dart';

void main() {
  const repository = UnavailableShelfRepository();
  final copy = MovieCopy(movieId: 550, title: 'Clube da Luta');

  test('deve falhar a leitura com SignInRequiredFailure', () async {
    await expectLater(
      repository.watchMovie(550),
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

  test('deve concluir o fechamento, porque não há stream aberto', () async {
    await expectLater(repository.closeStreams(), completes);
  });
}

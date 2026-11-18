import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/movie_copy.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/shelf_mark.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/shelf_movie.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/shelf_page.dart';

void main() {
  ShelfMovie movie(int id) => ShelfMovie(
    copy: MovieCopy(movieId: id, title: 'Filme $id'),
    cachedAt: DateTime.utc(2026, 11),
    marks: {ShelfMark.watched: DateTime.utc(2026, 11, 2)},
  );

  group('ShelfPage', () {
    test('deve guardar os filmes na ordem recebida', () {
      final page = ShelfPage(movies: [movie(2), movie(1)], hasMore: false);

      expect(page.movies.map((m) => m.copy.movieId), [2, 1]);
    });

    test('não deve deixar mudar a lista de filmes', () {
      final page = ShelfPage(movies: [movie(1)], hasMore: false);

      expect(() => page.movies.add(movie(2)), throwsUnsupportedError);
    });

    test('não deve mudar quando a lista original muda', () {
      final movies = [movie(1)];
      final page = ShelfPage(movies: movies, hasMore: false);

      movies.add(movie(2));

      expect(page.movies, hasLength(1));
    });

    test('deve ser igual a outra página com os mesmos filmes', () {
      final a = ShelfPage(movies: [movie(1)], hasMore: true);
      final b = ShelfPage(movies: [movie(1)], hasMore: true);

      expect(a, b);
    });

    test('deve ser diferente quando muda se há mais filmes', () {
      final a = ShelfPage(movies: [movie(1)], hasMore: true);
      final b = ShelfPage(movies: [movie(1)], hasMore: false);

      expect(a, isNot(b));
    });
  });
}

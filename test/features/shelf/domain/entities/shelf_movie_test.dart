import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/movie_copy.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/shelf_mark.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/shelf_movie.dart';

void main() {
  final copy = MovieCopy(movieId: 550, title: 'Clube da Luta');
  final cachedAt = DateTime.utc(2026, 11, 1);
  final watchedAt = DateTime.utc(2026, 11, 2);

  ShelfMovie movieWith(Map<ShelfMark, DateTime> marks) =>
      ShelfMovie(copy: copy, cachedAt: cachedAt, marks: marks);

  group('ShelfMovie', () {
    test('deve recusar um filme sem nenhuma marca', () {
      expect(() => movieWith({}), throwsArgumentError);
    });

    test('deve dizer que o filme está marcado como assistido', () {
      final movie = movieWith({ShelfMark.watched: watchedAt});

      expect(movie.isMarked(ShelfMark.watched), isTrue);
    });

    test('deve dizer que o filme não está nos favoritos', () {
      final movie = movieWith({ShelfMark.watched: watchedAt});

      expect(movie.isMarked(ShelfMark.favorite), isFalse);
    });

    test('deve devolver quando a marca entrou', () {
      final movie = movieWith({ShelfMark.watched: watchedAt});

      expect(movie.markedAt(ShelfMark.watched), watchedAt);
    });

    test('deve devolver as marcas que sobram sem a marca tirada', () {
      final movie = movieWith({
        ShelfMark.watched: watchedAt,
        ShelfMark.favorite: watchedAt,
      });

      expect(movie.marksWithout(ShelfMark.watched), {ShelfMark.favorite});
    });

    test('deve devolver nenhuma marca ao tirar a única', () {
      final movie = movieWith({ShelfMark.watched: watchedAt});

      expect(movie.marksWithout(ShelfMark.watched), isEmpty);
    });

    test('não deve deixar mudar as marcas por fora', () {
      final marks = {ShelfMark.watched: watchedAt};
      final movie = movieWith(marks);

      marks[ShelfMark.favorite] = watchedAt;

      expect(movie.isMarked(ShelfMark.favorite), isFalse);
    });

    test('deve considerar a cópia válida antes de 180 dias', () {
      final movie = movieWith({ShelfMark.watched: watchedAt});
      final now = cachedAt.add(const Duration(days: 179));

      expect(movie.isCopyExpired(now), isFalse);
    });

    test('deve considerar a cópia vencida com 180 dias, antes dos 6 meses', () {
      final movie = movieWith({ShelfMark.watched: watchedAt});
      final now = cachedAt.add(ShelfMovie.copyMaxAge);

      expect(movie.isCopyExpired(now), isTrue);
    });

    test('deve ser igual a outro filme com os mesmos dados', () {
      expect(
        movieWith({ShelfMark.watched: watchedAt}),
        movieWith({ShelfMark.watched: watchedAt}),
      );
    });
  });
}

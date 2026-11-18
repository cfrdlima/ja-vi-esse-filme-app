import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/movie_copy.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/rating.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/shelf_mark.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/shelf_movie.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/watched_on.dart';

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

    group('nota e dia em que assistiu', () {
      final rating = Rating(7);
      final watchedOn = WatchedOn(year: 2026, month: 11, day: 1);

      test('deve começar sem nota', () {
        expect(movieWith({ShelfMark.watched: watchedAt}).rating, isNull);
      });

      test('deve guardar a nota do filme assistido', () {
        final movie = ShelfMovie(
          copy: copy,
          cachedAt: cachedAt,
          marks: {ShelfMark.watched: watchedAt},
          rating: rating,
        );

        expect(movie.rating, rating);
      });

      test('deve guardar o dia em que o filme foi assistido', () {
        final movie = ShelfMovie(
          copy: copy,
          cachedAt: cachedAt,
          marks: {ShelfMark.watched: watchedAt},
          watchedOn: watchedOn,
        );

        expect(movie.watchedOn, watchedOn);
      });

      test('deve recusar a nota sem a marca Assistido', () {
        expect(
          () => ShelfMovie(
            copy: copy,
            cachedAt: cachedAt,
            marks: {ShelfMark.favorite: watchedAt},
            rating: rating,
          ),
          throwsArgumentError,
        );
      });

      test('deve recusar o dia sem a marca Assistido', () {
        expect(
          () => ShelfMovie(
            copy: copy,
            cachedAt: cachedAt,
            marks: {ShelfMark.favorite: watchedAt},
            watchedOn: watchedOn,
          ),
          throwsArgumentError,
        );
      });

      test('deve dizer que tirar o Assistido apaga a nota', () {
        final movie = ShelfMovie(
          copy: copy,
          cachedAt: cachedAt,
          marks: {ShelfMark.watched: watchedAt, ShelfMark.favorite: watchedAt},
          rating: rating,
        );

        expect(movie.losesPersonalDataWithout(ShelfMark.watched), isTrue);
      });

      test('deve dizer que tirar o Assistido apaga o dia', () {
        final movie = ShelfMovie(
          copy: copy,
          cachedAt: cachedAt,
          marks: {ShelfMark.watched: watchedAt},
          watchedOn: watchedOn,
        );

        expect(movie.losesPersonalDataWithout(ShelfMark.watched), isTrue);
      });

      test(
        'não deve dizer que tirar o Assistido sem nota nem dia apaga algo',
        () {
          final movie = movieWith({ShelfMark.watched: watchedAt});

          expect(movie.losesPersonalDataWithout(ShelfMark.watched), isFalse);
        },
      );

      test('não deve dizer que tirar o Favorito apaga a nota', () {
        final movie = ShelfMovie(
          copy: copy,
          cachedAt: cachedAt,
          marks: {ShelfMark.watched: watchedAt, ShelfMark.favorite: watchedAt},
          rating: rating,
        );

        expect(movie.losesPersonalDataWithout(ShelfMark.favorite), isFalse);
      });

      test('deve ser diferente de outro filme com outra nota', () {
        ShelfMovie rated(Rating rating) => ShelfMovie(
          copy: copy,
          cachedAt: cachedAt,
          marks: {ShelfMark.watched: watchedAt},
          rating: rating,
        );

        expect(rated(Rating(7)), isNot(rated(Rating(8))));
      });

      test('deve ser diferente de outro filme com outro dia', () {
        ShelfMovie watchedOnDay(int day) => ShelfMovie(
          copy: copy,
          cachedAt: cachedAt,
          marks: {ShelfMark.watched: watchedAt},
          watchedOn: WatchedOn(year: 2026, month: 11, day: day),
        );

        expect(watchedOnDay(1), isNot(watchedOnDay(2)));
      });
    });

    test('deve ser igual a outro filme com os mesmos dados', () {
      expect(
        movieWith({ShelfMark.watched: watchedAt}),
        movieWith({ShelfMark.watched: watchedAt}),
      );
    });
  });
}

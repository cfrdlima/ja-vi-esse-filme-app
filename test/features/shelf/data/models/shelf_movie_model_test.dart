import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/features/shelf/data/gateways/shelf_gateway.dart';
import 'package:ja_vi_esse_filme/features/shelf/data/models/shelf_movie_model.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/movie_copy.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/shelf_entry.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/shelf_mark.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/shelf_movie.dart';

void main() {
  final cachedAt = DateTime.utc(2026, 11, 1);
  final watchedAt = DateTime.utc(2026, 11, 2);
  final favoriteAt = DateTime.utc(2026, 11, 3);

  Map<String, Object?> document() => {
    'title': 'Clube da Luta',
    'posterPath': '/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg',
    'cachedAt': cachedAt,
    'watchedAt': watchedAt,
    'favoriteAt': favoriteAt,
  };

  ShelfMovie onShelf(ShelfEntry entry) => switch (entry) {
    OnShelf(:final movie) => movie,
    NotOnShelf() => fail('esperava o filme na Estante'),
  };

  group('ShelfMovieModel.fromDocument', () {
    test('deve tratar o documento ausente como fora da Estante', () {
      expect(ShelfMovieModel.fromDocument(550, {}), const NotOnShelf());
    });

    test('deve ler o documento completo', () {
      final entry = ShelfMovieModel.fromDocument(550, document());

      expect(
        entry,
        OnShelf(
          ShelfMovie(
            copy: MovieCopy(
              movieId: 550,
              title: 'Clube da Luta',
              posterPath: '/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg',
            ),
            cachedAt: cachedAt,
            marks: {
              ShelfMark.watched: watchedAt,
              ShelfMark.favorite: favoriteAt,
            },
          ),
        ),
      );
    });

    test('deve ler o filme sem posterPath', () {
      final data = document()..remove('posterPath');

      final movie = onShelf(ShelfMovieModel.fromDocument(550, data));

      expect(movie.copy.posterPath, isNull);
    });

    test('deve ignorar uma marca que não é data', () {
      final data = document()..['watchlistAt'] = true;

      final movie = onShelf(ShelfMovieModel.fromDocument(550, data));

      expect(movie.isMarked(ShelfMark.watchlist), isFalse);
    });

    test('deve tratar o documento sem marca válida como fora da Estante', () {
      final data = document()
        ..remove('favoriteAt')
        ..['watchedAt'] = 'ontem';

      expect(ShelfMovieModel.fromDocument(550, data), const NotOnShelf());
    });

    test('deve tratar o cachedAt ausente como cópia vencida', () {
      final data = document()..remove('cachedAt');

      final movie = onShelf(ShelfMovieModel.fromDocument(550, data));

      expect(movie.isCopyExpired(DateTime.utc(2026, 11, 17)), isTrue);
    });

    test('deve tratar o cachedAt que não é data como cópia vencida', () {
      final data = document()..['cachedAt'] = 0;

      final movie = onShelf(ShelfMovieModel.fromDocument(550, data));

      expect(movie.isCopyExpired(DateTime.utc(2026, 11, 17)), isTrue);
    });

    test('deve recusar o documento sem title com FormatException', () {
      final data = document()..remove('title');

      expect(
        () => ShelfMovieModel.fromDocument(550, data),
        throwsFormatException,
      );
    });

    test('deve recusar o title que não é texto com FormatException', () {
      final data = document()..['title'] = 42;

      expect(
        () => ShelfMovieModel.fromDocument(550, data),
        throwsFormatException,
      );
    });

    test('deve recusar o title vazio com FormatException', () {
      final data = document()..['title'] = '  ';

      expect(
        () => ShelfMovieModel.fromDocument(550, data),
        throwsFormatException,
      );
    });

    test('deve descartar o posterPath que não é texto', () {
      final data = document()..['posterPath'] = 7;

      final movie = onShelf(ShelfMovieModel.fromDocument(550, data));

      expect(movie.copy.posterPath, isNull);
    });
  });

  group('ShelfMovieModel.markFields', () {
    test('deve marcar com a hora do servidor e renovar a cópia', () {
      final copy = MovieCopy(
        movieId: 550,
        title: 'Clube da Luta',
        posterPath: '/a.jpg',
      );

      expect(ShelfMovieModel.markFields(copy, ShelfMark.watchlist), {
        'watchlistAt': const ServerTime(),
        'title': const SetField('Clube da Luta'),
        'posterPath': const SetField('/a.jpg'),
        'cachedAt': const ServerTime(),
      });
    });

    test('deve apagar o posterPath salvo quando o filme não tem pôster', () {
      final copy = MovieCopy(movieId: 550, title: 'Clube da Luta');

      final fields = ShelfMovieModel.markFields(copy, ShelfMark.favorite);

      expect(fields['posterPath'], const DeleteField());
    });

    test('deve usar um campo por marca', () {
      final copy = MovieCopy(movieId: 550, title: 'Filme');

      final fields = {
        for (final mark in ShelfMark.values)
          ...ShelfMovieModel.markFields(copy, mark).keys,
      };

      expect(
        fields,
        containsAll(<String>['watchedAt', 'watchlistAt', 'favoriteAt']),
      );
    });
  });

  group('ShelfMovieModel.unmarkFields', () {
    test('deve apagar só o campo da marca', () {
      expect(ShelfMovieModel.unmarkFields(ShelfMark.favorite), {
        'favoriteAt': const DeleteField(),
      });
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/movie_copy.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/shelf_entry.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/shelf_mark.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/shelf_movie.dart';

void main() {
  ShelfMovie movie() => ShelfMovie(
    copy: MovieCopy(movieId: 550, title: 'Clube da Luta'),
    cachedAt: DateTime.utc(2026, 11, 1),
    marks: {ShelfMark.watched: DateTime.utc(2026, 11, 2)},
  );

  group('ShelfEntry', () {
    // Sem const, como o `map` do stream faria.
    test(
      'deve tratar duas ausências da Estante criadas sem const como iguais',
      () {
        const make = NotOnShelf.new;

        expect((make() == make(), make().hashCode), (true, make().hashCode));
      },
    );

    test('deve tratar o mesmo filme na Estante como igual', () {
      expect(OnShelf(movie()), OnShelf(movie()));
    });

    test('deve diferenciar o filme na Estante da ausência', () {
      expect(OnShelf(movie()), isNot(const NotOnShelf()));
    });
  });
}

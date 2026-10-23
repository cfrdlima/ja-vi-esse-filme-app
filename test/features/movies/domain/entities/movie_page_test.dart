import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/features/movies/domain/entities/movie.dart';
import 'package:ja_vi_esse_filme/features/movies/domain/entities/movie_page.dart';

void main() {
  const movie = Movie(id: 1, title: 'Filme');

  test('deve ter mais páginas quando a página atual é menor que o total', () {
    const page = MoviePage(movies: [movie], page: 1, totalPages: 3);

    expect(page.hasMore, isTrue);
  });

  test('não deve ter mais páginas na última página', () {
    const page = MoviePage(movies: [movie], page: 3, totalPages: 3);

    expect(page.hasMore, isFalse);
  });

  test('não deve ter mais páginas quando o total vem zerado', () {
    const page = MoviePage(movies: [], page: 1, totalPages: 0);

    expect(page.hasMore, isFalse);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/features/movies/domain/entities/movie.dart';

void main() {
  test('dois filmes com os mesmos dados devem ser iguais', () {
    final a = Movie(
      id: 603,
      title: 'Matrix',
      posterPath: '/p.jpg',
      releaseDate: DateTime(1999, 3, 31),
      voteAverage: 8.2,
    );
    final b = Movie(
      id: 603,
      title: 'Matrix',
      posterPath: '/p.jpg',
      releaseDate: DateTime(1999, 3, 31),
      voteAverage: 8.2,
    );

    expect(a, b);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/movie_copy.dart';

void main() {
  group('MovieCopy', () {
    test('deve guardar o id, o título e o pôster do TMDB', () {
      final copy = MovieCopy(
        movieId: 550,
        title: 'Clube da Luta',
        posterPath: '/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg',
      );

      expect(
        (copy.movieId, copy.title, copy.posterPath),
        (550, 'Clube da Luta', '/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg'),
      );
    });

    test('deve recusar um movieId menor que 1', () {
      expect(() => MovieCopy(movieId: 0, title: 'Filme'), throwsArgumentError);
    });

    test(
      'deve recusar um movieId com mais de 10 dígitos, o limite das regras',
      () {
        expect(
          () => MovieCopy(movieId: 10000000000, title: 'Filme'),
          throwsArgumentError,
        );
      },
    );

    test('deve aceitar o maior movieId com 10 dígitos', () {
      final copy = MovieCopy(movieId: MovieCopy.maxMovieId, title: 'Filme');

      expect(copy.movieId, 9999999999);
    });

    test('deve tirar os espaços das pontas do título', () {
      final copy = MovieCopy(movieId: 1, title: '  Filme  ');

      expect(copy.title, 'Filme');
    });

    test('deve recusar um título vazio ou só com espaços', () {
      expect(() => MovieCopy(movieId: 1, title: '   '), throwsArgumentError);
    });

    test('deve cortar o título em 300 unidades, o limite das regras', () {
      final copy = MovieCopy(movieId: 1, title: 'a' * 301);

      expect(copy.title.length, MovieCopy.maxTitleLength);
    });

    test('deve cortar o título sem partir um emoji ao meio', () {
      final copy = MovieCopy(movieId: 1, title: '${'a' * 299}🎬');

      expect(copy.title, 'a' * 299);
    });

    test('deve aceitar um título com exatamente 300 unidades', () {
      final copy = MovieCopy(movieId: 1, title: '🎬' * 150);

      expect(copy.title, '🎬' * 150);
    });

    test('deve aceitar o filme sem pôster', () {
      final copy = MovieCopy(movieId: 1, title: 'Filme');

      expect(copy.posterPath, isNull);
    });

    for (final path in [
      'sem-barra.jpg',
      '/../segredo.jpg',
      '/a.svg',
      '/a.jpg?x=1',
      'https://example.com/a.jpg',
      '/${'a' * 65}.jpg',
      '',
    ]) {
      test('deve descartar o pôster fora do formato das regras: "$path"', () {
        final copy = MovieCopy(movieId: 1, title: 'Filme', posterPath: path);

        expect(copy.posterPath, isNull);
      });
    }

    test('deve ser igual a outra cópia com os mesmos dados', () {
      expect(
        MovieCopy(movieId: 1, title: 'Filme', posterPath: '/a.jpg'),
        MovieCopy(movieId: 1, title: 'Filme', posterPath: '/a.jpg'),
      );
    });
  });

  group('canCopy', () {
    test('deve aceitar um filme com id e título válidos', () {
      expect(MovieCopy.canCopy(movieId: 550, title: 'Clube da Luta'), isTrue);
    });

    for (final title in ['', '   ']) {
      test('deve recusar o título vazio: "$title"', () {
        expect(MovieCopy.canCopy(movieId: 550, title: title), isFalse);
      });
    }

    for (final id in [0, -1, MovieCopy.maxMovieId + 1]) {
      test('deve recusar o id fora das regras: $id', () {
        expect(MovieCopy.canCopy(movieId: id, title: 'Filme'), isFalse);
      });
    }
  });
}

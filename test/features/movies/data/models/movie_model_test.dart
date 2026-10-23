import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/features/movies/data/models/movie_model.dart';
import 'package:ja_vi_esse_filme/features/movies/domain/entities/movie.dart';

import '../../../../helpers/fixtures.dart';

void main() {
  late List<Map<String, Object?>> results;

  setUp(() {
    final json =
        jsonDecode(readFixture('movie_popular_page1.json'))
            as Map<String, Object?>;
    results = (json['results']! as List<Object?>).cast();
  });

  test('deve converter um filme completo na entidade', () {
    final movie = MovieModel.fromJson(results[0]).toEntity();

    expect(
      movie,
      Movie(
        id: 693134,
        title: 'Duna: Parte Dois',
        posterPath: '/poster-duna.jpg',
        releaseDate: DateTime(2024, 2, 27),
        voteAverage: 8.1,
      ),
    );
  });

  test('deve aceitar pôster nulo, data vazia e nota inteira', () {
    final movie = MovieModel.fromJson(results[1]).toEntity();

    expect(
      movie,
      const Movie(id: 1184918, title: 'Filme Sem Pôster', voteAverage: 7),
    );
  });

  test('deve usar o título original e ignorar data inválida', () {
    final movie = MovieModel.fromJson(results[2]).toEntity();

    expect(
      movie,
      const Movie(
        id: 42,
        title: 'Only Original Title',
        posterPath: '/so-original.jpg',
      ),
    );
  });

  test('deve tratar caminho de pôster vazio como sem pôster', () {
    final movie = MovieModel.fromJson(const {
      'id': 1,
      'title': 'X',
      'poster_path': '',
    }).toEntity();

    expect(movie.posterPath, isNull);
  });

  test('deve tratar caminho de pôster malformado como sem pôster', () {
    final movie = MovieModel.fromJson(const {
      'id': 1,
      'title': 'X',
      'poster_path': 'https://outro.host/x.jpg',
    }).toEntity();

    expect(movie.posterPath, isNull);
  });

  test('deve recusar filme sem id', () {
    expect(
      () => MovieModel.fromJson(const {'title': 'Sem id'}),
      throwsA(isA<FormatException>()),
    );
  });
}

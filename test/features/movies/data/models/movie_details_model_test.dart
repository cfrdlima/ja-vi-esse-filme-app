import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/features/movies/data/models/movie_details_model.dart';
import 'package:ja_vi_esse_filme/features/movies/domain/entities/movie_details.dart';
import 'package:ja_vi_esse_filme/features/movies/domain/entities/trailer.dart';

import '../../../../helpers/fixtures.dart';

void main() {
  MovieDetails parseFixture(String name) => MovieDetailsModel.fromJson(
    jsonDecode(readFixture(name)) as Map<String, Object?>,
  ).toEntity();

  MovieDetails parse(Map<String, Object?> json) =>
      MovieDetailsModel.fromJson(json).toEntity();

  group('filme completo', () {
    late MovieDetails details;

    setUp(() => details = parseFixture('movie_details_full.json'));

    test('deve converter os campos do cabeçalho', () {
      expect(
        (
          details.id,
          details.title,
          details.posterPath,
          details.releaseDate,
          details.runtime,
          details.voteAverage,
        ),
        (
          693134,
          'Duna: Parte Dois',
          '/poster-duna.jpg',
          DateTime(2024, 2, 27),
          const Duration(minutes: 166),
          8.14,
        ),
      );
    });

    test('deve converter os gêneros na ordem do TMDB', () {
      expect(details.genres, ['Ficção científica', 'Aventura']);
    });

    test('deve usar a sinopse em pt-BR', () {
      expect(
        details.overview,
        'Paul Atreides se une a Chani e aos Fremen enquanto busca vingança.',
      );
    });

    test('deve ordenar o elenco pela order e cortar em 15', () {
      expect(details.cast.map((member) => member.id), [
        for (var i = 0; i < 15; i++) 1000 + i,
      ]);
    });

    test('deve converter nome, personagem e foto de cada pessoa', () {
      final member = details.cast.first;

      expect(
        (member.name, member.character, member.profilePath),
        ('Ator 0', 'Personagem 0', '/perfil-0.jpg'),
      );
    });

    test('deve ficar só com trailer e teaser do YouTube com key válida, '
        'na ordem de relevância', () {
      expect(details.trailers.map((trailer) => trailer.key), [
        'Way9Dexny3w',
        'U2Qp5pL3ovA',
        '_zXy-12AbC3',
      ]);
    });

    test('deve converter nome, tipo, oficial e idioma de cada trailer', () {
      final trailer = details.trailers.first;

      expect(
        (trailer.name, trailer.kind, trailer.official, trailer.language),
        ('Trailer oficial dublado', TrailerKind.trailer, true, 'pt'),
      );
    });

    test('deve converter o país de cada trailer', () {
      expect(details.trailers.map((trailer) => trailer.country), [
        'BR',
        'US',
        '',
      ]);
    });

    test('deve converter o teaser', () {
      expect(details.trailers[1].kind, TrailerKind.teaser);
    });

    test('deve tratar nome, oficial e idioma nulos como vazio, não oficial e '
        'sem idioma', () {
      final trailer = details.trailers.last;

      expect(
        (trailer.name, trailer.official, trailer.language),
        ('', false, ''),
      );
    });
  });

  group('sinopse original', () {
    test('deve usar a sinopse do idioma original quando a pt-BR vem vazia', () {
      final details = parseFixture('movie_details_no_pt_overview.json');

      expect(details.overview, '戦国時代の農村を野武士から守る七人の侍。');
    });

    test(
      'deve ficar sem sinopse quando não há tradução no idioma original',
      () {
        final details = parse(const {
          'id': 1,
          'title': 'Filme',
          'overview': '',
          'original_language': 'ko',
          'translations': {
            'translations': [
              {
                'iso_639_1': 'en',
                'data': {'overview': 'Only in English.'},
              },
            ],
          },
        });

        expect(details.overview, isEmpty);
      },
    );

    test('deve ignorar tradução quebrada', () {
      final details = parse(const {
        'id': 1,
        'title': 'Filme',
        'overview': '',
        'original_language': 'fr',
        'translations': {
          'translations': [
            'não é objeto',
            {'iso_639_1': 'fr', 'data': 'não é objeto'},
            {
              'iso_639_1': 'fr',
              'data': {'overview': 'Le synopsis.'},
            },
          ],
        },
      });

      expect(details.overview, 'Le synopsis.');
    });
  });

  group('campos nulos ou vazios', () {
    late MovieDetails details;

    setUp(() => details = parseFixture('movie_details_sparse.json'));

    test('deve usar o título original quando o traduzido vem vazio', () {
      expect(details.title, 'Filme Sem Pôster');
    });

    test('deve deixar sem pôster, data, duração e nota', () {
      expect(
        (
          details.posterPath,
          details.releaseDate,
          details.runtime,
          details.voteAverage,
        ),
        (null, null, null, 0),
      );
    });

    test('deve tratar sinopse nula e sem traduções como sem sinopse', () {
      expect(details.overview, isEmpty);
    });

    test('deve tratar gêneros nulos como lista vazia', () {
      expect(details.genres, isEmpty);
    });

    test('deve tratar vídeos ausentes como sem trailers', () {
      expect(details.trailers, isEmpty);
    });

    test('deve descartar pessoa sem id, sem nome ou que não é objeto', () {
      expect(details.cast.map((member) => member.id), [55, 57]);
    });

    test(
      'deve tratar personagem nulo como vazio e foto vazia como sem foto',
      () {
        final member = details.cast.first;

        expect((member.character, member.profilePath), ('', null));
      },
    );
  });

  test('deve manter a ordem recebida entre pessoas com a mesma order', () {
    final details = parse({
      'id': 1,
      'title': 'Filme',
      'credits': {
        'cast': [
          for (var i = 0; i < 40; i++)
            {'id': i, 'name': 'Pessoa $i', 'order': i < 20 ? 0 : 1},
        ],
      },
    });

    expect(details.cast.map((member) => member.id), [
      for (var i = 0; i < 15; i++) i,
    ]);
  });

  test('deve tratar duração 0 como desconhecida', () {
    final details = parse(const {'id': 1, 'title': 'Filme', 'runtime': 0});

    expect(details.runtime, isNull);
  });

  test('deve descartar gênero sem nome', () {
    final details = parse(const {
      'id': 1,
      'title': 'Filme',
      'genres': [
        {'id': 18, 'name': ''},
        {'id': 35, 'name': 'Comédia'},
        'não é objeto',
      ],
    });

    expect(details.genres, ['Comédia']);
  });

  test('deve tratar foto fora do formato do TMDB como sem foto', () {
    final details = parse(const {
      'id': 1,
      'title': 'Filme',
      'credits': {
        'cast': [
          {'id': 9, 'name': 'Pessoa', 'profile_path': '//outro.host/x.jpg'},
        ],
      },
    });

    expect(details.cast.single.profilePath, isNull);
  });

  test('deve lançar FormatException sem id', () {
    expect(
      () => MovieDetailsModel.fromJson(const {'title': 'Sem id'}),
      throwsFormatException,
    );
  });

  test('deve tratar vídeos fora do formato como sem trailers', () {
    final details = parse(const {
      'id': 1,
      'title': 'Filme',
      'videos': {'results': 'não é lista'},
    });

    expect(details.trailers, isEmpty);
  });
}

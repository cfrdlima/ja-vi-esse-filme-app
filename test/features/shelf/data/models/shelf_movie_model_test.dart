import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/features/shelf/data/gateways/shelf_gateway.dart';
import 'package:ja_vi_esse_filme/features/shelf/data/models/shelf_movie_model.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/movie_copy.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/rating.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/shelf_entry.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/shelf_mark.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/shelf_movie.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/shelf_page.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/watched_on.dart';

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

  // Parse defensivo da decisão 018: um valor estragado vira "sem nota" ou
  // "sem dia", sem derrubar o filme.
  group('ShelfMovieModel.fromDocument com a nota e o dia', () {
    test('deve ler a nota em meias estrelas', () {
      final data = document()..['rating'] = 7;

      final movie = onShelf(ShelfMovieModel.fromDocument(550, data));

      expect(movie.rating, Rating(7));
    });

    test('deve ler o dia em que assistiu', () {
      final data = document()..['watchedOn'] = '2026-11-01';

      final movie = onShelf(ShelfMovieModel.fromDocument(550, data));

      expect(movie.watchedOn, WatchedOn(year: 2026, month: 11, day: 1));
    });

    for (final rating in <Object?>[0, 11, 3.5, '7', null]) {
      test('deve ignorar a nota ${rating.runtimeType} $rating', () {
        final data = document()..['rating'] = rating;

        final movie = onShelf(ShelfMovieModel.fromDocument(550, data));

        expect(movie.rating, isNull);
      });
    }

    for (final watchedOn in <Object?>[
      '2026-02-30',
      '2026-13-01',
      '1887-12-31',
      '2026-1-1',
      '2026-11-01T00:00:00Z',
      20261101,
      null,
    ]) {
      test('deve ignorar o dia ${watchedOn.runtimeType} $watchedOn', () {
        final data = document()..['watchedOn'] = watchedOn;

        final movie = onShelf(ShelfMovieModel.fromDocument(550, data));

        expect(movie.watchedOn, isNull);
      });
    }

    test('deve ignorar a nota do filme sem a marca Assistido', () {
      final data = document()
        ..remove('watchedAt')
        ..['rating'] = 7;

      final movie = onShelf(ShelfMovieModel.fromDocument(550, data));

      expect(movie.rating, isNull);
    });

    test('deve ignorar o dia do filme sem a marca Assistido', () {
      final data = document()
        ..remove('watchedAt')
        ..['watchedOn'] = '2026-11-01';

      final movie = onShelf(ShelfMovieModel.fromDocument(550, data));

      expect(movie.watchedOn, isNull);
    });
  });

  group('ShelfMovieModel com a nota e o dia', () {
    test('deve gravar a nota em meias estrelas', () {
      expect(ShelfMovieModel.ratingFields(Rating(7)), {
        'rating': const SetField(7),
      });
    });

    test('deve apagar a nota', () {
      expect(ShelfMovieModel.noRatingFields(), {'rating': const DeleteField()});
    });

    test('deve gravar o dia no formato das regras', () {
      final day = WatchedOn(year: 1999, month: 3, day: 5);

      expect(ShelfMovieModel.watchedOnFields(day), {
        'watchedOn': const SetField('1999-03-05'),
      });
    });

    test('deve apagar o dia', () {
      expect(ShelfMovieModel.noWatchedOnFields(), {
        'watchedOn': const DeleteField(),
      });
    });

    test('deve ler o dia que gravou', () {
      final day = WatchedOn(year: 1999, month: 3, day: 5);
      final written = ShelfMovieModel.watchedOnFields(day)['watchedOn'];
      final data = document()..['watchedOn'] = (written! as SetField).value;

      final movie = onShelf(ShelfMovieModel.fromDocument(550, data));

      expect(movie.watchedOn, day);
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

  // As regras recusam a nota e o dia sem o watchedAt (decisão 018). O
  // apagamento vai sempre, mesmo que o aparelho não veja nota: ela pode ter
  // vindo de outro aparelho.
  test('deve apagar a nota e o dia junto com o Assistido', () {
    expect(ShelfMovieModel.unmarkFields(ShelfMark.watched), {
      'watchedAt': const DeleteField(),
      'rating': const DeleteField(),
      'watchedOn': const DeleteField(),
    });
  });

  group('ShelfMovieModel.copyFields', () {
    test('deve regravar a cópia e o cachedAt sem tocar nas marcas', () {
      final copy = MovieCopy(
        movieId: 550,
        title: 'Clube da Luta',
        posterPath: '/a.jpg',
      );

      expect(ShelfMovieModel.copyFields(copy), {
        'title': const SetField('Clube da Luta'),
        'posterPath': const SetField('/a.jpg'),
        'cachedAt': const ServerTime(),
      });
    });

    test('deve apagar o pôster salvo quando a cópia nova não tem', () {
      final copy = MovieCopy(movieId: 550, title: 'Clube da Luta');

      expect(
        ShelfMovieModel.copyFields(copy)['posterPath'],
        const DeleteField(),
      );
    });
  });

  group('ShelfMovieModel.fieldOf', () {
    test('deve usar o nome do campo das regras para cada marca', () {
      expect(ShelfMark.values.map(ShelfMovieModel.fieldOf), [
        'watchedAt',
        'watchlistAt',
        'favoriteAt',
      ]);
    });
  });

  group('ShelfMovieModel.pageFrom', () {
    ShelfDocument doc(String id, [Map<String, Object?>? fields]) =>
        (id: id, fields: fields ?? document());

    List<int> idsOf(ShelfPage page) =>
        page.movies.map((m) => m.copy.movieId).toList();

    test('deve montar os filmes na ordem da consulta', () {
      final page = ShelfMovieModel.pageFrom([doc('13'), doc('550')], limit: 20);

      expect(idsOf(page), [13, 550]);
    });

    test('deve ler o filme como no documento sozinho', () {
      final page = ShelfMovieModel.pageFrom([doc('550')], limit: 20);

      expect(
        page.movies.single,
        onShelf(ShelfMovieModel.fromDocument(550, document())),
      );
    });

    test('deve dizer que há mais quando veio o limite inteiro', () {
      final page = ShelfMovieModel.pageFrom([doc('13'), doc('550')], limit: 2);

      expect(page.hasMore, isTrue);
    });

    test('deve dizer que acabou quando veio menos que o limite', () {
      final page = ShelfMovieModel.pageFrom([doc('13')], limit: 2);

      expect(page.hasMore, isFalse);
    });

    test('deve pular o documento sem title legível', () {
      final page = ShelfMovieModel.pageFrom([
        doc('13', {...document(), 'title': 42}),
        doc('550'),
      ], limit: 20);

      expect(idsOf(page), [550]);
    });

    test('deve pular o documento com id fora das regras', () {
      final page = ShelfMovieModel.pageFrom([
        doc('abc'),
        doc('0'),
        doc('550'),
      ], limit: 20);

      expect(idsOf(page), [550]);
    });

    test('deve pular o documento sem nenhuma marca legível', () {
      final page = ShelfMovieModel.pageFrom([
        doc('13', {'title': 'Sem marca', 'cachedAt': cachedAt}),
        doc('550'),
      ], limit: 20);

      expect(idsOf(page), [550]);
    });

    test('deve contar o documento pulado para saber se há mais', () {
      final page = ShelfMovieModel.pageFrom([doc('abc'), doc('550')], limit: 2);

      expect(page.hasMore, isTrue);
    });
  });

  group('ShelfMovieModel com as listas (decisão 019)', () {
    const terror = 'Lst0aBcDeFgHiJkLmNoP';
    const comedy = 'Lst1aBcDeFgHiJkLmNoP';
    final addedAt = DateTime.utc(2026, 11, 4);

    Map<String, Object?> listsOnly(Object? lists) => {
      'title': 'Clube da Luta',
      'cachedAt': cachedAt,
      'lists': lists,
    };

    test('deve ler o filme só numa lista, sem marca', () {
      final movie = onShelf(
        ShelfMovieModel.fromDocument(550, listsOnly({terror: addedAt})),
      );

      expect(movie.addedToListAt(terror), addedAt);
    });

    test('deve ler as listas do filme marcado', () {
      final movie = onShelf(
        ShelfMovieModel.fromDocument(550, {
          ...document(),
          'lists': {terror: addedAt, comedy: addedAt},
        }),
      );

      expect(movie.listIds, {terror, comedy});
    });

    test('deve ignorar a chave fora do formato do id', () {
      final movie = onShelf(
        ShelfMovieModel.fromDocument(550, {
          ...document(),
          'lists': {'curta': addedAt, terror: addedAt},
        }),
      );

      expect(movie.listIds, {terror});
    });

    test('deve ignorar a lista cujo valor não é data', () {
      final movie = onShelf(
        ShelfMovieModel.fromDocument(550, {
          ...document(),
          'lists': {terror: 'ontem', comedy: addedAt},
        }),
      );

      expect(movie.listIds, {comedy});
    });

    test('deve ignorar lists que não é mapa', () {
      final movie = onShelf(
        ShelfMovieModel.fromDocument(550, {
          ...document(),
          'lists': [terror],
        }),
      );

      expect(movie.listIds, isEmpty);
    });

    test('deve tratar sem marca e sem lista legível como fora da Estante', () {
      expect(
        ShelfMovieModel.fromDocument(550, listsOnly({'curta': addedAt})),
        const NotOnShelf(),
      );
    });

    test('deve ordenar a lista pelo campo dela no mapa', () {
      expect(ShelfMovieModel.listOrderField(terror), 'lists.$terror');
    });

    // O id vira caminho de campo: um ponto abriria outro campo.
    test('deve recusar o id fora do formato no campo de ordem', () {
      expect(
        () => ShelfMovieModel.listOrderField('Lst0aBcDeFgHi.kLmNoP'),
        throwsArgumentError,
      );
    });

    test('deve pôr o filme na lista com a hora do servidor e a cópia', () {
      final copy = MovieCopy(movieId: 550, title: 'Clube da Luta');

      expect(ShelfMovieModel.addToListFields(copy, terror), {
        'lists': const MapFields({terror: ServerTime()}),
        ...ShelfMovieModel.copyFields(copy),
      });
    });

    test('deve tirar só a chave da lista quando sobra outra', () {
      final movie = onShelf(
        ShelfMovieModel.fromDocument(
          550,
          listsOnly({terror: addedAt, comedy: addedAt}),
        ),
      );

      expect(ShelfMovieModel.removeFromListFields(movie, terror), {
        'lists.$terror': const DeleteField(),
      });
    });

    // As regras recusam o mapa vazio.
    test('deve tirar o mapa inteiro com a última lista', () {
      final movie = onShelf(
        ShelfMovieModel.fromDocument(550, {
          ...document(),
          'lists': {terror: addedAt},
        }),
      );

      expect(ShelfMovieModel.removeFromListFields(movie, terror), {
        'lists': const DeleteField(),
      });
    });
  });
}

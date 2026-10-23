import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/features/movies/domain/entities/cast_member.dart';
import 'package:ja_vi_esse_filme/features/movies/domain/entities/movie_details.dart';
import 'package:ja_vi_esse_filme/features/movies/domain/entities/trailer.dart';

void main() {
  List<CastMember> castOf(int count) => [
    for (var i = 0; i < count; i++)
      CastMember(id: i, name: 'Pessoa $i', character: 'Papel $i'),
  ];

  MovieDetails detailsWith(List<CastMember> cast) =>
      MovieDetails(id: 1, title: 'Filme', overview: '', cast: cast);

  test('deve manter o elenco até o teto de 15 pessoas', () {
    final cast = castOf(MovieDetails.maxCast);

    final details = detailsWith(cast);

    expect(details.cast, cast);
  });

  test('deve cortar o elenco em 15 pessoas, mantendo a ordem recebida', () {
    final cast = castOf(20);

    final details = detailsWith(cast);

    expect(details.cast, cast.take(15).toList());
  });

  test('não deve deixar o elenco ser alterado depois de criado', () {
    final details = detailsWith(castOf(2));

    expect(() => details.cast.add(castOf(1).single), throwsUnsupportedError);
  });

  test('não deve refletir mudança na lista de elenco recebida', () {
    final cast = castOf(2);
    final details = detailsWith(cast);

    cast.clear();

    expect(details.cast, hasLength(2));
  });

  test('não deve deixar os gêneros serem alterados depois de criado', () {
    final details = MovieDetails(
      id: 1,
      title: 'Filme',
      overview: '',
      genres: ['Drama'],
    );

    expect(() => details.genres.add('Ação'), throwsUnsupportedError);
  });

  group('trailers', () {
    var nextKey = 0;

    Trailer trailer({
      TrailerKind kind = TrailerKind.trailer,
      bool official = true,
      String language = 'pt',
      String country = 'BR',
    }) => Trailer(
      key: 'video${nextKey++}'.padRight(11, 'x'),
      name: 'Vídeo',
      kind: kind,
      official: official,
      language: language,
      country: country,
    );

    MovieDetails detailsWithTrailers(List<Trailer> trailers) =>
        MovieDetails(id: 1, title: 'Filme', overview: '', trailers: trailers);

    test('deve pôr os oficiais antes dos outros', () {
      final unofficial = trailer(official: false);
      final official = trailer();

      final details = detailsWithTrailers([unofficial, official]);

      expect(details.trailers, [official, unofficial]);
    });

    test('deve pôr os em português antes dos em outro idioma', () {
      final english = trailer(language: 'en');
      final portuguese = trailer();

      final details = detailsWithTrailers([english, portuguese]);

      expect(details.trailers, [portuguese, english]);
    });

    test('deve pôr os do Brasil antes dos de Portugal', () {
      final portugal = trailer(country: 'PT');
      final brazil = trailer();

      final details = detailsWithTrailers([portugal, brazil]);

      expect(details.trailers, [brazil, portugal]);
    });

    test('deve dar ao idioma prioridade sobre o país', () {
      final englishFromBrazil = trailer(language: 'en');
      final portugueseFromPortugal = trailer(country: 'PT');

      final details = detailsWithTrailers([
        englishFromBrazil,
        portugueseFromPortugal,
      ]);

      expect(details.trailers, [portugueseFromPortugal, englishFromBrazil]);
    });

    test('deve dar ao país prioridade sobre o tipo', () {
      final portugalTrailer = trailer(country: 'PT');
      final brazilTeaser = trailer(kind: TrailerKind.teaser);

      final details = detailsWithTrailers([portugalTrailer, brazilTeaser]);

      expect(details.trailers, [brazilTeaser, portugalTrailer]);
    });

    test('deve pôr o trailer antes do teaser', () {
      final teaser = trailer(kind: TrailerKind.teaser);
      final fullTrailer = trailer();

      final details = detailsWithTrailers([teaser, fullTrailer]);

      expect(details.trailers, [fullTrailer, teaser]);
    });

    test('deve dar ao oficial prioridade sobre o idioma', () {
      final unofficialPortuguese = trailer(official: false);
      final officialEnglish = trailer(language: 'en');

      final details = detailsWithTrailers([
        unofficialPortuguese,
        officialEnglish,
      ]);

      expect(details.trailers, [officialEnglish, unofficialPortuguese]);
    });

    test('deve dar ao idioma prioridade sobre o tipo', () {
      final englishTrailer = trailer(language: 'en');
      final portugueseTeaser = trailer(kind: TrailerKind.teaser);

      final details = detailsWithTrailers([englishTrailer, portugueseTeaser]);

      expect(details.trailers, [portugueseTeaser, englishTrailer]);
    });

    // Abaixo de 32 itens o `sort` do Dart já sai estável, e o teste não
    // pegaria a falta do desempate pelo índice.
    test('deve manter a ordem recebida entre vídeos equivalentes', () {
      final trailers = [for (var i = 0; i < 40; i++) trailer()];

      final details = detailsWithTrailers(trailers);

      expect(details.trailers, trailers.take(MovieDetails.maxTrailers));
    });

    test('deve cortar os trailers em 5', () {
      final trailers = [for (var i = 0; i < 8; i++) trailer()];

      final details = detailsWithTrailers(trailers);

      expect(details.trailers, hasLength(MovieDetails.maxTrailers));
    });

    test('deve ordenar antes de cortar', () {
      final trailers = [
        for (var i = 0; i < 6; i++) trailer(official: false),
        trailer(),
      ];

      final details = detailsWithTrailers(trailers);

      expect(details.trailers.first, trailers.last);
    });

    test('deve ficar só com o mais relevante entre vídeos de mesma key', () {
      final english = Trailer(
        key: 'Way9Dexny3w',
        name: 'Em inglês',
        kind: TrailerKind.trailer,
        official: true,
        language: 'en',
      );
      final portuguese = Trailer(
        key: 'Way9Dexny3w',
        name: 'Em português',
        kind: TrailerKind.trailer,
        official: true,
        language: 'pt',
      );

      final details = detailsWithTrailers([english, portuguese]);

      expect(details.trailers, [portuguese]);
    });

    test('deve tirar as keys repetidas antes de cortar', () {
      final repeated = [for (var i = 0; i < 4; i++) trailer()];
      final duplicates = [
        for (final original in repeated)
          Trailer(
            key: original.key,
            name: 'Cópia',
            kind: original.kind,
            official: original.official,
            language: original.language,
          ),
      ];
      final last = trailer();

      final details = detailsWithTrailers([...repeated, ...duplicates, last]);

      expect(details.trailers.last, last);
    });

    test('não deve deixar os trailers serem alterados depois de criado', () {
      final details = detailsWithTrailers([trailer()]);

      expect(() => details.trailers.add(trailer()), throwsUnsupportedError);
    });

    test('deve começar sem trailers', () {
      final details = MovieDetails(id: 1, title: 'Filme', overview: '');

      expect(details.trailers, isEmpty);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/features/movies/domain/entities/cast_member.dart';
import 'package:ja_vi_esse_filme/features/movies/domain/entities/movie_details.dart';

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
}

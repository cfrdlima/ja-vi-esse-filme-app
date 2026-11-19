import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/list_name.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/movie_list.dart';

void main() {
  MovieList listNamed(String name, {String id = 'Lst0aBcDeFgHiJkLmNoP'}) =>
      MovieList(id: id, name: ListName(name));

  List<String> namesOf(List<MovieList> lists) => [
    for (final list in lists) list.name.value,
  ];

  group('MovieList', () {
    test('deve recusar o id vazio', () {
      expect(
        () => MovieList(id: '', name: ListName('Terror')),
        throwsArgumentError,
      );
    });

    test('deve recusar o id com barra', () {
      expect(
        () => MovieList(id: 'a/b', name: ListName('Terror')),
        throwsArgumentError,
      );
    });

    test('deve ser igual a outra com o mesmo id e o mesmo nome', () {
      expect(listNamed('Terror'), listNamed('Terror'));
    });

    test('deve ser diferente de outra com outro nome', () {
      expect(listNamed('Terror'), isNot(listNamed('Suspense')));
    });

    test('deve trocar só o nome', () {
      final renamed = listNamed('Terror').rename(ListName('Suspense'));

      expect(renamed, listNamed('Suspense'));
    });
  });

  group('MovieList.sortedByName', () {
    test('deve pôr em ordem alfabética', () {
      final sorted = MovieList.sortedByName([
        listNamed('casa'),
        listNamed('banana'),
        listNamed('abacate'),
      ]);

      expect(namesOf(sorted), ['abacate', 'banana', 'casa']);
    });

    test('deve ignorar maiúsculas', () {
      final sorted = MovieList.sortedByName([
        listNamed('Zebra'),
        listNamed('avião'),
      ]);

      expect(namesOf(sorted), ['avião', 'Zebra']);
    });

    test('deve ignorar acentos e cedilha', () {
      final sorted = MovieList.sortedByName([
        listNamed('Comédia'),
        listNamed('Ação'),
        listNamed('Animação'),
        listNamed('Clássicos'),
      ]);

      expect(namesOf(sorted), ['Ação', 'Animação', 'Clássicos', 'Comédia']);
    });

    test('deve desempatar nomes iguais pelo id', () {
      final sorted = MovieList.sortedByName([
        listNamed('Terror', id: 'Lst1aBcDeFgHiJkLmNoP'),
        listNamed('terror', id: 'Lst0aBcDeFgHiJkLmNoP'),
      ]);

      expect(
        [for (final list in sorted) list.id],
        ['Lst0aBcDeFgHiJkLmNoP', 'Lst1aBcDeFgHiJkLmNoP'],
      );
    });
  });
}

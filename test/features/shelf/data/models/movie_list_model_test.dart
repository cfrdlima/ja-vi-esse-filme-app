import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/features/shelf/data/gateways/shelf_gateway.dart';
import 'package:ja_vi_esse_filme/features/shelf/data/models/movie_list_model.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/list_name.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/movie_list.dart';

void main() {
  const terror = 'Lst0aBcDeFgHiJkLmNoP';
  const comedy = 'Lst1aBcDeFgHiJkLmNoP';

  ShelfDocument document(String id, Object? name) =>
      (id: id, fields: {'name': name});

  group('MovieListModel.listsFrom', () {
    test('deve ler as listas em ordem alfabética', () {
      final lists = MovieListModel.listsFrom([
        document(terror, 'Terror'),
        document(comedy, 'Comédia'),
      ]);

      expect(lists, [
        MovieList(id: comedy, name: ListName('Comédia')),
        MovieList(id: terror, name: ListName('Terror')),
      ]);
    });

    test('deve pular a lista sem nome legível', () {
      final lists = MovieListModel.listsFrom([
        document(terror, 7),
        document(comedy, 'Comédia'),
      ]);

      expect(lists.single.id, comedy);
    });

    test('deve pular a lista com o nome fora das regras', () {
      final lists = MovieListModel.listsFrom([document(terror, 'a' * 51)]);

      expect(lists, isEmpty);
    });

    test('deve pular a lista com o id fora do formato', () {
      final lists = MovieListModel.listsFrom([document('curta', 'Terror')]);

      expect(lists, isEmpty);
    });
  });

  group('MovieListModel.nameFields', () {
    test('deve gravar só o nome', () {
      expect(MovieListModel.nameFields(ListName(' Terror ')), {
        'name': const SetField('Terror'),
      });
    });
  });
}

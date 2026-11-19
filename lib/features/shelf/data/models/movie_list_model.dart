import '../../domain/entities/list_name.dart';
import '../../domain/entities/movie_list.dart';
import '../gateways/shelf_gateway.dart';
import 'list_id.dart';

/// Converte os documentos `users/{uid}/lists/{listId}` (decisão 019) nas
/// listas do domínio.
abstract final class MovieListModel {
  static const _name = 'name';

  /// As listas em ordem alfabética. Parse defensivo: uma lista com o id
  /// fora do formato ou o nome ilegível é pulada, para não derrubar a aba.
  static List<MovieList> listsFrom(List<ShelfDocument> documents) =>
      MovieList.sortedByName([
        for (final (:id, :fields) in documents)
          if (_listOf(id, fields[_name]) case final MovieList list) list,
      ]);

  static MovieList? _listOf(String id, Object? name) {
    if (!listIdPattern.hasMatch(id) || name is! String) return null;
    try {
      return MovieList(id: id, name: ListName(name));
    } on InvalidListNameException {
      return null;
    }
  }

  static Map<String, FieldWrite> nameFields(ListName name) => {
    _name: SetField(name.value),
  };
}

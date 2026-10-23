import '../../domain/entities/movie_page.dart';
import '../../domain/entities/search_query.dart';
import '../../domain/repositories/movie_repository.dart';
import 'paged_movies_notifier.dart';

/// Os resultados paginados de um termo de busca.
class SearchResultsNotifier extends PagedMoviesNotifier {
  SearchResultsNotifier({required this._repository, required this.query});

  final MovieRepository _repository;
  final SearchQuery query;

  @override
  Future<MoviePage> fetchPage(int page) =>
      _repository.search(query, page: page);
}

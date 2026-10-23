import '../../domain/entities/movie_category.dart';
import '../../domain/entities/movie_page.dart';
import '../../domain/entities/search_query.dart';
import '../../domain/repositories/movie_repository.dart';
import '../datasources/movie_remote_data_source.dart';

class TmdbMovieRepository implements MovieRepository {
  TmdbMovieRepository({required this._remote});

  final MovieRemoteDataSource _remote;

  @override
  Future<MoviePage> byCategory(MovieCategory category, {required int page}) {
    _checkPage(page);
    return _remote.byCategory(category, page: page);
  }

  @override
  Future<MoviePage> search(SearchQuery query, {required int page}) {
    _checkPage(page);
    return _remote.search(query, page: page);
  }

  // O TMDB responderia 400 a uma página inválida; pedir isso é bug do app.
  void _checkPage(int page) {
    if (page < 1) throw RangeError.range(page, 1, null, 'page');
  }
}

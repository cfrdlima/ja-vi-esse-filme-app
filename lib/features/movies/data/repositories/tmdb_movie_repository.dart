import '../../domain/entities/movie_page.dart';
import '../../domain/repositories/movie_repository.dart';
import '../datasources/movie_remote_data_source.dart';

class TmdbMovieRepository implements MovieRepository {
  TmdbMovieRepository({required this._remote});

  final MovieRemoteDataSource _remote;

  @override
  Future<MoviePage> popular({required int page}) {
    // O TMDB responderia 400 a uma página inválida; pedir isso é bug do app.
    if (page < 1) throw RangeError.range(page, 1, null, 'page');
    return _remote.popular(page: page);
  }
}

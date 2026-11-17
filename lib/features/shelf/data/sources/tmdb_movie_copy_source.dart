import '../../../../core/error/failures.dart';
import '../../../movies/domain/repositories/movie_repository.dart';
import '../../domain/entities/movie_copy.dart';
import '../../domain/repositories/movie_copy_source.dart';

/// A cópia atual de um filme a partir dos detalhes do TMDB, pelo
/// [MovieRepository] que os Detalhes já usam.
class TmdbMovieCopySource implements MovieCopySource {
  TmdbMovieCopySource({required this._movies});

  final MovieRepository _movies;

  @override
  Future<MovieCopy> fetchCopy(int movieId) async {
    final details = await _movies.details(movieId);
    // Sem título, o `MovieCopy` lançaria `ArgumentError`, que é bug, e não
    // um dado ruim do TMDB.
    if (!MovieCopy.canCopy(movieId: movieId, title: details.title)) {
      throw const UnexpectedFailure('detalhes do TMDB sem título');
    }
    return MovieCopy(
      movieId: movieId,
      title: details.title,
      posterPath: details.posterPath,
    );
  }
}

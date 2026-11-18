import '../entities/movie_copy.dart';

/// De onde vem a cópia atual de um filme (o TMDB), para renovar a cópia
/// vencida da Estante (decisão 013).
abstract interface class MovieCopySource {
  /// Pode falhar com as falhas de `core/error/failures.dart`: filme que
  /// sumiu do TMDB é `NotFoundFailure`.
  Future<MovieCopy> fetchCopy(int movieId);
}

import '../../../../core/error/failures.dart';
import '../../domain/entities/list_name.dart';
import '../../domain/entities/movie_copy.dart';
import '../../domain/entities/movie_list.dart';
import '../../domain/entities/shelf_movie.dart';
import '../../domain/entities/shelf_page.dart';
import '../../domain/repositories/movie_lists_repository.dart';

/// As listas quando o Firebase não subiu, como a
/// `UnavailableShelfRepository`: sempre deslogado.
final class UnavailableMovieListsRepository implements MovieListsRepository {
  const UnavailableMovieListsRepository();

  @override
  Stream<List<MovieList>> watchLists() =>
      Stream.error(const SignInRequiredFailure());

  @override
  Stream<ShelfPage> watchList(MovieList list, {required int limit}) =>
      Stream.error(const SignInRequiredFailure());

  @override
  MovieList newList(ListName name) => throw const SignInRequiredFailure();

  @override
  Future<int> countLists() async => throw const SignInRequiredFailure();

  @override
  Future<int> countMovies(MovieList list) async =>
      throw const SignInRequiredFailure();

  @override
  Future<void> createList(MovieList list) async =>
      throw const SignInRequiredFailure();

  @override
  Future<void> renameList(MovieList list, ListName name) async =>
      throw const SignInRequiredFailure();

  @override
  Future<void> deleteList(MovieList list) async =>
      throw const SignInRequiredFailure();

  @override
  Future<void> addToList(MovieCopy copy, MovieList list) async =>
      throw const SignInRequiredFailure();

  @override
  Future<void> removeFromList(ShelfMovie movie, MovieList list) async =>
      throw const SignInRequiredFailure();

  /// Os streams daqui já nascem com erro: não há o que fechar.
  @override
  Future<void> closeStreams() async {}
}

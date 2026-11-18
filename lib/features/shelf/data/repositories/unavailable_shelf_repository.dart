import '../../../../core/error/failures.dart';
import '../../domain/entities/movie_copy.dart';
import '../../domain/entities/shelf_entry.dart';
import '../../domain/entities/shelf_mark.dart';
import '../../domain/entities/shelf_movie.dart';
import '../../domain/entities/shelf_page.dart';
import '../../domain/repositories/shelf_repository.dart';

/// A Estante quando o Firebase não subiu. A conta, nesse caso, é a
/// `UnavailableAuthRepository`, sempre deslogada; por isso tudo falha como
/// o contrato manda sem ninguém logado.
final class UnavailableShelfRepository implements ShelfRepository {
  const UnavailableShelfRepository();

  @override
  Stream<ShelfEntry> watchMovie(int movieId) =>
      Stream.error(const SignInRequiredFailure());

  @override
  Stream<ShelfPage> watchShelf(ShelfMark mark, {required int limit}) =>
      Stream.error(const SignInRequiredFailure());

  @override
  Future<void> addMark(MovieCopy copy, ShelfMark mark) async =>
      throw const SignInRequiredFailure();

  @override
  Future<void> removeMark(ShelfMovie movie, ShelfMark mark) async =>
      throw const SignInRequiredFailure();

  @override
  Future<void> renewCopy(MovieCopy copy) async =>
      throw const SignInRequiredFailure();

  /// O [watchMovie] e o [watchShelf] daqui já nascem com erro: não há stream
  /// para fechar.
  @override
  Future<void> closeStreams() async {}
}

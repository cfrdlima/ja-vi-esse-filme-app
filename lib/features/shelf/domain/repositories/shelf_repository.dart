import '../entities/movie_copy.dart';
import '../entities/shelf_entry.dart';
import '../entities/shelf_mark.dart';
import '../entities/shelf_movie.dart';

/// As marcas do usuário logado em `users/{uid}/movies/{movieId}` (decisões
/// 010 e 013). As falhas são as de `core/error/failures.dart`; a camada
/// `data` traduz os erros do SDK sem repassar a `message` da exceção.
///
/// Sem ninguém logado, tudo falha com `SignInRequiredFailure`.
abstract interface class ShelfRepository {
  /// Emite se o filme [movieId] está na Estante ao assinar e a cada mudança,
  /// inclusive as feitas offline, que o Firestore aplica antes no aparelho.
  ///
  /// O stream pode emitir erro com `NetworkFailure` ou `UnexpectedFailure`.
  Stream<ShelfEntry> watchMovie(int movieId);

  /// Põe a [mark] no filme com a hora do servidor e regrava a [copy] do TMDB,
  /// o que renova o prazo dela. Cria o documento se ele não existir.
  ///
  /// Pode falhar com `NetworkFailure`, `RateLimitFailure` ou
  /// `UnexpectedFailure`.
  Future<void> addMark(MovieCopy copy, ShelfMark mark);

  /// Tira a [mark] do [movie]. Se ela for a única, apaga o documento, e o
  /// filme sai da Estante. Um documento que já não existe conta como
  /// sucesso.
  ///
  /// Pode falhar com `NetworkFailure`, `RateLimitFailure` ou
  /// `UnexpectedFailure`.
  Future<void> removeMark(ShelfMovie movie, ShelfMark mark);
}

import '../entities/movie_copy.dart';
import '../entities/shelf_entry.dart';
import '../entities/shelf_mark.dart';
import '../entities/shelf_movie.dart';

/// As marcas do usuário logado em `users/{uid}/movies/{movieId}` (decisões
/// 010 e 013). As falhas são as de `core/error/failures.dart`; a camada
/// `data` traduz os erros do SDK sem repassar a `message` da exceção.
///
/// Sem ninguém logado, tudo falha com `SignInRequiredFailure`.
///
/// **Offline, as escritas não falham:** o Firestore aplica a mudança no
/// aparelho, o [watchMovie] já a emite, e o future só completa quando o
/// servidor confirma, o que pode demorar horas. A UI mostra a marca pelo
/// [watchMovie] e não espera o future para sair do "carregando"; trata só
/// o erro dele, que chega quando o servidor recusa.
abstract interface class ShelfRepository {
  /// Emite se o filme [movieId] está na Estante ao assinar e a cada mudança,
  /// inclusive as feitas offline, que o Firestore aplica antes no aparelho.
  ///
  /// O stream pode emitir erro com `NetworkFailure` ou `UnexpectedFailure`.
  Stream<ShelfEntry> watchMovie(int movieId);

  /// Põe a [mark] no filme com a hora do servidor e regrava a [copy] do TMDB,
  /// o que renova o prazo dela. Cria o documento se ele não existir.
  ///
  /// Pode falhar com `RateLimitFailure` (cota esgotada), `NetworkFailure`
  /// (só se o servidor recusar por prazo, nunca por estar offline) ou
  /// `UnexpectedFailure`.
  Future<void> addMark(MovieCopy copy, ShelfMark mark);

  /// Tira a [mark] do [movie]. Se ela for a única, apaga o documento, e o
  /// filme sai da Estante. Um documento que já não existe conta como
  /// sucesso, e a [mark] que já era a única no servidor (o [movie] estava
  /// velho) também apaga o documento.
  ///
  /// As mesmas falhas do [addMark].
  Future<void> removeMark(ShelfMovie movie, ShelfMark mark);

  /// Regrava só a cópia do TMDB e o `cachedAt`, sem mexer nas marcas, para
  /// renovar o prazo de uma cópia vencida (decisão 013). Um documento que
  /// não existe mais conta como sucesso: o filme saiu da Estante.
  ///
  /// As mesmas falhas do [addMark].
  Future<void> renewCopy(MovieCopy copy);

  /// Encerra os streams do [watchMovie] ainda abertos: quem ouve recebe o
  /// fim. O logout chama isso antes de limpar o cache (decisão 010).
  Future<void> closeStreams();
}

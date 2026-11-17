import '../entities/auth_state.dart';
import '../entities/sign_in_outcome.dart';

/// Conta própria com login do Google no Firebase (decisão 010). As falhas são
/// as de `core/error/failures.dart`; a camada `data` traduz os erros do SDK
/// sem repassar a `message`, o e-mail nem a credencial da exceção original.
abstract interface class AuthRepository {
  /// Quanto o [syncPendingChanges] espera o servidor (sessão 022).
  static const syncTimeout = Duration(seconds: 5);

  /// Stream broadcast: aceita várias assinaturas, e cada uma recebe o estado
  /// atual ao assinar e de novo a cada login ou logout.
  Stream<AuthState> get authStateChanges;

  /// Abre o seletor de contas do Google, só com a identidade básica. Com
  /// alguém já logado, devolve [SignInCompleted] com esse usuário, sem abrir
  /// o seletor. Fechar o seletor é [SignInCancelled], e não falha.
  ///
  /// Pode falhar com `NetworkFailure`, `AccountDisabledFailure`,
  /// `RateLimitFailure` ou `UnexpectedFailure`.
  Future<SignInOutcome> signIn();

  /// Espera até [syncTimeout] as marcas feitas no aparelho chegarem ao
  /// servidor. Verdadeiro se chegaram; falso se o prazo acabou ou a espera
  /// falhou. O [signOut] apaga o que não chegou, e a UI pergunta antes
  /// (sessão 022).
  Future<bool> syncPendingChanges();

  /// Encerra a sessão e limpa o cache local, na ordem da decisão 010:
  /// cancela os streams, `terminate()` e `clearPersistence()` do Firestore,
  /// `signOut()` do Firebase e do Google, e recria a instância. As escritas
  /// que não chegaram ao servidor se perdem (ver [syncPendingChanges]).
  ///
  /// Os dois `signOut()` rodam sempre, mesmo se a limpeza falhar: a sessão
  /// nunca fica aberta. Nesse caso, [authStateChanges] emite [SignedOut]
  /// primeiro, e depois a falha sobe como `UnexpectedFailure`, para a UI
  /// mostrar o erro.
  Future<void> signOut();

  /// Exclui a conta, na ordem da decisão 010:
  /// 1. confere o login recente. Sem ele, falha com
  ///    `RecentLoginRequiredFailure` **antes** de apagar qualquer documento;
  /// 2. apaga os documentos das subcoleções da lista fixa em `users/{uid}` e
  ///    espera o servidor confirmar;
  /// 3. `user.delete()` no Firebase Auth;
  /// 4. `disconnect()` no Google;
  /// 5. a mesma limpeza local do [signOut].
  ///
  /// No sucesso, [authStateChanges] emite [SignedOut]. Pode falhar também
  /// com `NetworkFailure` ou `UnexpectedFailure`.
  ///
  /// Até o item da exclusão no `dev/PLANO.md`, sempre falha com
  /// `UnexpectedFailure` sem tocar em nada: apagar só o Auth deixaria os
  /// documentos órfãos em `users/{uid}`.
  Future<void> deleteAccount();
}

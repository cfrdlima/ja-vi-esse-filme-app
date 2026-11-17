import '../entities/auth_state.dart';
import '../entities/sign_in_outcome.dart';

/// Conta própria com login do Google no Firebase (decisão 010). As falhas são
/// as de `core/error/failures.dart`; a camada `data` traduz os erros do SDK.
abstract interface class AuthRepository {
  /// Emite o estado atual ao ser assinado e de novo a cada login ou logout.
  Stream<AuthState> get authStateChanges;

  /// Abre o seletor de contas do Google, só com a identidade básica.
  /// Pode falhar com `NetworkFailure`, `AccountDisabledFailure` ou
  /// `RateLimitFailure`. Fechar o seletor é [SignInCancelled], e não falha.
  Future<SignInOutcome> signIn();

  /// Encerra a sessão e limpa o cache local na ordem da decisão 010. Se a
  /// limpeza falhar, a sessão é encerrada mesmo assim e a falha é lançada,
  /// para a UI mostrar o erro.
  Future<void> signOut();

  /// Apaga os documentos do usuário e depois a conta (decisão 010). Pode
  /// falhar com `RecentLoginRequiredFailure` ou `NetworkFailure`.
  Future<void> deleteAccount();
}

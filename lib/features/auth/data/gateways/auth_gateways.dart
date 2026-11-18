import '../../domain/entities/app_user.dart';

/// Fachada fina sobre o `FirebaseAuth`, para o repositório ser testado com
/// fakes (sessão 019). Repassa as exceções do SDK (`FirebaseAuthException`)
/// sem traduzir: a tradução é do repositório.
abstract interface class FirebaseAuthGateway {
  /// Emite o usuário atual ao assinar, e de novo a cada login ou logout.
  Stream<AppUser?> authStateChanges();

  AppUser? get currentUser;

  Future<AppUser> signInWithGoogleIdToken(String idToken);

  Future<void> signOut();
}

/// Fachada fina sobre o `GoogleSignIn`. Repassa a `GoogleSignInException`
/// sem traduzir.
abstract interface class GoogleAccountGateway {
  /// Abre o seletor de contas, só com a identidade básica, e devolve o
  /// `idToken` da conta escolhida. Pode vir `null` se o Google não o mandar.
  Future<String?> authenticate();

  Future<void> signOut();
}

/// O cache da conta no aparelho (o do Firestore), que o logout limpa
/// (decisão 010). Repassa as exceções do SDK sem traduzir.
abstract interface class AccountCacheGateway {
  /// Completa quando as escritas feitas no aparelho chegam ao servidor.
  /// Offline, fica pendente até a rede voltar.
  Future<void> waitForPendingWrites();

  /// Fecha os streams abertos, `terminate()` e `clearPersistence()`, nessa
  /// ordem. As escritas ainda pendentes se perdem.
  Future<void> clear();

  /// Só o `clearPersistence()`, para o início do app, antes de qualquer
  /// leitura: com a instância já em uso, falha.
  Future<void> clearUnused();
}

/// Os documentos da conta em `users/{uid}`, que a exclusão apaga (decisões
/// 010 e 015). Repassa as exceções do SDK sem traduzir.
abstract interface class AccountDocumentsGateway {
  /// Apaga todos os documentos das subcoleções da lista fixa e só completa
  /// quando o servidor confirma. Cada passo tem o prazo de
  /// `AuthRepository.deleteStepTimeout`; passado o prazo, falha com
  /// `TimeoutException`.
  Future<void> deleteAll(String uid);
}

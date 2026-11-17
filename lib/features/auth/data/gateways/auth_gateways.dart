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

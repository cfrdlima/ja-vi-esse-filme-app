import '../../../../core/error/failures.dart';
import '../../domain/entities/auth_state.dart';
import '../../domain/entities/sign_in_outcome.dart';
import '../../domain/repositories/auth_repository.dart';

/// A conta quando o Firebase não subiu (falha no `initializeApp`). O app
/// continua de pé para Descobrir, Buscar e Detalhes, que não dependem da
/// conta, e o login mostra o erro em vez de derrubar tudo.
final class UnavailableAuthRepository implements AuthRepository {
  const UnavailableAuthRepository();

  static const _unavailable = UnexpectedFailure('auth: firebase indisponível');

  @override
  Stream<AuthState> get authStateChanges => Stream.value(const SignedOut());

  @override
  Future<SignInOutcome> signIn() async => throw _unavailable;

  /// Sem Firebase não há nada no aparelho esperando o servidor.
  @override
  Future<bool> syncPendingChanges() async => true;

  /// Sem Firebase não há sessão aberta para encerrar.
  @override
  Future<void> signOut() async {}

  @override
  Future<void> deleteAccount() async => throw _unavailable;
}

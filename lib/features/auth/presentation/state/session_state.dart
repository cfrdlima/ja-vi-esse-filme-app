import '../../../../core/error/failures.dart';
import '../../domain/entities/app_user.dart';

/// Estado da conta na UI. A tela faz `switch` exaustivo nele.
sealed class SessionState {
  const SessionState();
}

/// Ainda sem o primeiro estado da conta.
final class SessionLoading extends SessionState {
  const SessionLoading();
}

final class SessionSignedOut extends SessionState {
  const SessionSignedOut();
}

/// O seletor de contas do Google está aberto, ou a credencial está a caminho
/// do Firebase.
final class SessionSigningIn extends SessionState {
  const SessionSigningIn();
}

final class SessionSignedIn extends SessionState {
  const SessionSignedIn(this.user);

  final AppUser user;
}

/// O login ou o logout falhou. A sessão está fechada, e a UI oferece "tentar
/// de novo".
final class SessionFailed extends SessionState {
  const SessionFailed(this.failure);

  final Failure failure;
}

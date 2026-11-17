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

/// O logout espera até 5 s as marcas do aparelho chegarem ao servidor antes
/// de limpar o cache (sessão 022). A conta continua aberta.
final class SessionSigningOut extends SessionState {
  const SessionSigningOut(this.user);

  final AppUser user;
}

/// Sobraram marcas sem chegar ao servidor: sair apaga essas marcas. A pessoa
/// confirma ou cancela; a conta continua aberta até lá.
final class SessionUnsyncedSignOut extends SessionState {
  const SessionUnsyncedSignOut(this.user);

  final AppUser user;
}

/// O login ou o logout falhou, com a [failure] para a mensagem. A tela olha o
/// subtipo para saber o que o "tentar de novo" repete.
sealed class SessionFailed extends SessionState {
  const SessionFailed(this.failure);

  final Failure failure;
}

/// O login falhou, ou o estado da conta não pôde ser lido. A sessão não está
/// aberta, e tentar de novo é entrar.
final class SessionSignInFailed extends SessionFailed {
  const SessionSignInFailed(super.failure);
}

/// O logout falhou. Se foi a limpeza, a sessão já fechou (o stream emitiu
/// `SignedOut` antes); se foi o `signOut` do Firebase, ela pode continuar
/// aberta. Tentar de novo é sair.
final class SessionSignOutFailed extends SessionFailed {
  const SessionSignOutFailed(super.failure);
}

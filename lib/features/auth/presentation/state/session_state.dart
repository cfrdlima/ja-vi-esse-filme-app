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

/// Sem conta. Não é `final` por causa do [SessionAccountDeleted], que é um
/// deslogado com o aviso da exclusão: os `switch` das telas continuam
/// tratando os dois como deslogados.
class SessionSignedOut extends SessionState {
  const SessionSignedOut();
}

/// A conta acabou de ser excluída (decisão 015). O Perfil mostra o aviso
/// até o próximo estado.
final class SessionAccountDeleted extends SessionSignedOut {
  const SessionAccountDeleted();
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

/// A reautenticação no seletor do Google e a exclusão estão em andamento
/// (decisão 015). A conta continua aberta até o `user.delete()`.
final class SessionDeletingAccount extends SessionState {
  const SessionDeletingAccount(this.user);

  final AppUser user;
}

/// A exclusão falhou antes do `user.delete()`: a conta continua aberta, e
/// tentar de novo termina o que faltou. Fica fora do [SessionFailed], que
/// trata a sessão como possivelmente fechada.
final class SessionDeleteAccountFailed extends SessionState {
  const SessionDeleteAccountFailed(this.user, this.failure);

  final AppUser user;
  final Failure failure;
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

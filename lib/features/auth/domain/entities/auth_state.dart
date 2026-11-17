import 'app_user.dart';

/// Quem está usando o app agora. É estado explícito, e não `AppUser?`, para
/// a UI tratar os dois casos com `switch` exaustivo (CLAUDE.md, sem `null`
/// como controle de fluxo).
sealed class AuthState {
  const AuthState();
}

/// Ninguém logado. Descobrir, Buscar e Detalhes funcionam assim (decisão 010).
final class SignedOut extends AuthState {
  const SignedOut();
}

final class SignedIn extends AuthState {
  const SignedIn(this.user);

  final AppUser user;

  @override
  bool operator ==(Object other) => other is SignedIn && other.user == user;

  @override
  int get hashCode => user.hashCode;

  @override
  String toString() => 'SignedIn($user)';
}

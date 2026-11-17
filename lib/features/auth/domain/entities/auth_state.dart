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

  // Igual por tipo: uma instância criada sem `const` (num `map` do stream,
  // por exemplo) não quebra o `distinct()` nem o `emits` dos testes.
  @override
  bool operator ==(Object other) => other is SignedOut;

  @override
  int get hashCode => (SignedOut).hashCode;
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

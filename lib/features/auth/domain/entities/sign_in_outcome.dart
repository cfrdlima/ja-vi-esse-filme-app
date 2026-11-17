import 'app_user.dart';

/// Como terminou um pedido de login. O cancelamento pela pessoa é um
/// resultado esperado, e não uma falha: a UI só volta ao estado anterior.
sealed class SignInOutcome {
  const SignInOutcome();
}

final class SignInCompleted extends SignInOutcome {
  const SignInCompleted(this.user);

  final AppUser user;

  @override
  bool operator ==(Object other) =>
      other is SignInCompleted && other.user == user;

  @override
  int get hashCode => user.hashCode;

  @override
  String toString() => 'SignInCompleted($user)';
}

/// A pessoa fechou o seletor de contas do Google.
final class SignInCancelled extends SignInOutcome {
  const SignInCancelled();
}

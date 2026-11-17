import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/core/error/failures.dart';
import 'package:ja_vi_esse_filme/features/auth/data/repositories/unavailable_auth_repository.dart';
import 'package:ja_vi_esse_filme/features/auth/domain/entities/auth_state.dart';

void main() {
  const repository = UnavailableAuthRepository();

  test('deve emitir SignedOut a cada assinatura', () async {
    final first = await repository.authStateChanges.first;
    final second = await repository.authStateChanges.first;

    expect([first, second], [const SignedOut(), const SignedOut()]);
  });

  test('deve falhar o login com UnexpectedFailure', () async {
    await expectLater(repository.signIn(), throwsA(isA<UnexpectedFailure>()));
  });

  test('deve concluir o logout, porque ninguém está logado', () async {
    await expectLater(repository.signOut(), completes);
  });

  test('deve falhar a exclusão com UnexpectedFailure', () async {
    await expectLater(
      repository.deleteAccount(),
      throwsA(isA<UnexpectedFailure>()),
    );
  });
}

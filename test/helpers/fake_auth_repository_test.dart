import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/features/auth/domain/entities/auth_state.dart';

import 'fake_auth_repository.dart';

void main() {
  late FakeAuthRepository repository;

  setUp(() => repository = FakeAuthRepository());

  tearDown(() => repository.close());

  test('deve reemitir o estado atual para quem assina depois', () async {
    repository.emit(const SignedOut());

    final first = await repository.authStateChanges.first;

    expect(first, isA<SignedOut>());
  });

  test('deve falhar o deleteAccount pelo future, sem lançar na chamada', () {
    final result = repository.deleteAccount();

    expect(result, throwsUnimplementedError);
  });

  test('não deve emitir SignedOut de novo quando a conta já saiu', () async {
    repository.emit(const SignedOut());
    final emitted = <AuthState>[];
    final subscription = repository.authStateChanges.listen(emitted.add);
    addTearDown(subscription.cancel);
    await pumpEventQueue();

    await repository.signOut();
    await pumpEventQueue();

    expect(emitted, hasLength(1));
  });
}

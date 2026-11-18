import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/features/auth/domain/entities/account_deletion_outcome.dart';
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

  test('deve deixar a exclusão pendente até o teste responder', () async {
    unawaited(repository.deleteAccount());

    expect(repository.pendingDeletions, 1);
  });

  test('deve devolver o resultado da exclusão que o teste der', () async {
    final result = repository.deleteAccount();

    repository.completeDeletion(const AccountDeleted());

    expect(await result, const AccountDeleted());
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

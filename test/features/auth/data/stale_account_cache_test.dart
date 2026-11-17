import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/features/auth/data/gateways/auth_gateways.dart';
import 'package:ja_vi_esse_filme/features/auth/data/stale_account_cache.dart';
import 'package:ja_vi_esse_filme/features/auth/domain/entities/app_user.dart';
import 'package:ja_vi_esse_filme/features/auth/domain/entities/auth_state.dart';

class _FakeCache implements AccountCacheGateway {
  var clearUnusedCalls = 0;
  Object? clearUnusedError;

  @override
  Future<void> clearUnused() async {
    clearUnusedCalls++;
    if (clearUnusedError case final Object error) throw error;
  }

  @override
  Future<void> clear() async => throw UnimplementedError();

  @override
  Future<void> waitForPendingWrites() async => throw UnimplementedError();
}

void main() {
  late _FakeCache cache;

  setUp(() => cache = _FakeCache());

  test('deve limpar o cache quando o app abre deslogado', () async {
    await clearStaleAccountCache(
      account: Stream.value(const SignedOut()),
      cache: cache,
    );

    expect(cache.clearUnusedCalls, 1);
  });

  test('não deve limpar o cache quando o app abre logado', () async {
    await clearStaleAccountCache(
      account: Stream.value(SignedIn(AppUser(uid: 'ana123'))),
      cache: cache,
    );

    expect(cache.clearUnusedCalls, 0);
  });

  test('não deve limpar quando a conta não pôde ser lida', () async {
    await clearStaleAccountCache(
      account: Stream.error(Exception('conta')),
      cache: cache,
    );

    expect(cache.clearUnusedCalls, 0);
  });

  test('deve olhar só o primeiro estado da conta', () async {
    final account = StreamController<AuthState>();
    final done = clearStaleAccountCache(account: account.stream, cache: cache);

    account
      ..add(SignedIn(AppUser(uid: 'ana123')))
      ..add(const SignedOut());
    await done;
    await account.close();

    expect(cache.clearUnusedCalls, 0);
  });

  // O Firestore pode ter começado (login rápido); a limpeza fica para o
  // próximo início, e o app segue.
  test('deve engolir a falha da limpeza', () async {
    cache.clearUnusedError = Exception('failed-precondition');

    await expectLater(
      clearStaleAccountCache(
        account: Stream.value(const SignedOut()),
        cache: cache,
      ),
      completes,
    );
  });
}

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/core/error/failures.dart';
import 'package:ja_vi_esse_filme/features/auth/domain/entities/account_deletion_outcome.dart';
import 'package:ja_vi_esse_filme/features/auth/domain/entities/app_user.dart';
import 'package:ja_vi_esse_filme/features/auth/domain/entities/auth_state.dart';
import 'package:ja_vi_esse_filme/features/auth/presentation/state/account_photo_cleaner.dart';
import 'package:ja_vi_esse_filme/features/auth/presentation/state/session_notifier.dart';

import '../../../../helpers/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository repository;
  late SessionNotifier session;
  late List<String> evicted;

  const anaPhoto = 'https://lh3.googleusercontent.com/a/ana';
  final ana = AppUser(uid: 'ana1', displayName: 'Ana', photoUrl: anaPhoto);

  setUp(() {
    repository = FakeAuthRepository();
    session = SessionNotifier(repository: repository);
    evicted = [];
    AccountPhotoCleaner(session: session, evict: evicted.add);
  });

  tearDown(() async {
    session.dispose();
    await repository.close();
  });

  Future<void> emit(AuthState state) async {
    repository.emit(state);
    await pumpEventQueue();
  }

  test('deve apagar a foto do cache quando a sessão fecha', () async {
    await emit(SignedIn(ana));

    await emit(const SignedOut());

    expect(evicted, [anaPhoto]);
  });

  group('exclusão da conta', () {
    Future<void> startDeletion() async {
      await emit(SignedIn(ana));
      unawaited(session.deleteAccount());
      await pumpEventQueue();
    }

    test('não deve apagar a foto enquanto exclui', () async {
      await startDeletion();

      expect(evicted, isEmpty);
    });

    // O `SessionAccountDeleted` é um deslogado: um `switch` que o tratasse
    // à parte deixaria a foto no cache.
    test('deve apagar a foto do cache quando a conta é excluída', () async {
      await startDeletion();

      repository.completeDeletion(const AccountDeleted());
      await pumpEventQueue();

      expect(evicted, [anaPhoto]);
    });

    test('não deve apagar a foto quando a exclusão falha', () async {
      await startDeletion();

      repository.failDeletion(const NetworkFailure());
      await pumpEventQueue();

      expect(evicted, isEmpty);
    });
  });

  test('deve apagar a foto da conta anterior quando a conta troca', () async {
    await emit(SignedIn(ana));

    await emit(
      SignedIn(
        AppUser(uid: 'bia2', photoUrl: 'https://x.googleusercontent.com/b'),
      ),
    );

    expect(evicted, [anaPhoto]);
  });

  test('não deve apagar a foto enquanto a sessão continua aberta', () async {
    await emit(SignedIn(ana));

    await emit(SignedIn(ana));

    expect(evicted, isEmpty);
  });

  test('não deve apagar nada quando a conta não tem foto', () async {
    await emit(SignedIn(AppUser(uid: 'ana1')));

    await emit(const SignedOut());

    expect(evicted, isEmpty);
  });

  test('não deve apagar a foto quando o stream da conta dá erro', () async {
    await emit(SignedIn(ana));

    repository.emitError(StateError('stream'));
    await pumpEventQueue();

    expect(evicted, isEmpty);
  });
}

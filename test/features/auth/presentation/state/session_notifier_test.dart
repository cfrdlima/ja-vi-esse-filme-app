import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/core/error/failures.dart';
import 'package:ja_vi_esse_filme/features/auth/domain/entities/app_user.dart';
import 'package:ja_vi_esse_filme/features/auth/domain/entities/auth_state.dart';
import 'package:ja_vi_esse_filme/features/auth/domain/entities/sign_in_outcome.dart';
import 'package:ja_vi_esse_filme/features/auth/presentation/state/session_notifier.dart';
import 'package:ja_vi_esse_filme/features/auth/presentation/state/session_state.dart';

import '../../../../helpers/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository repository;
  late SessionNotifier notifier;

  final ana = AppUser(uid: 'abc123', displayName: 'Ana');

  setUp(() {
    repository = FakeAuthRepository();
    notifier = SessionNotifier(repository: repository);
  });

  tearDown(() async {
    notifier.dispose();
    await repository.close();
  });

  test('deve começar carregando, antes do primeiro estado da conta', () {
    expect(notifier.state, isA<SessionLoading>());
  });

  test('deve ficar deslogado quando a conta emite SignedOut', () async {
    repository.emit(const SignedOut());
    await pumpEventQueue();

    expect(notifier.state, isA<SessionSignedOut>());
  });

  test(
    'deve ficar logado com o usuário quando a conta emite SignedIn',
    () async {
      repository.emit(SignedIn(ana));
      await pumpEventQueue();

      expect(
        notifier.state,
        isA<SessionSignedIn>().having((s) => s.user, 'user', ana),
      );
    },
  );

  test('deve avisar os ouvintes quando a conta muda', () async {
    var notified = 0;
    notifier.addListener(() => notified++);

    repository.emit(const SignedOut());
    await pumpEventQueue();

    expect(notified, 1);
  });

  test('deve mostrar a falha quando o stream da conta dá erro', () async {
    repository.emitError(const NetworkFailure());
    await pumpEventQueue();

    expect(
      notifier.state,
      isA<SessionFailed>().having(
        (s) => s.failure,
        'failure',
        isA<NetworkFailure>(),
      ),
    );
  });

  test('deve parar de ouvir a conta no dispose', () async {
    final other = FakeAuthRepository();
    addTearDown(other.close);
    SessionNotifier(repository: other).dispose();

    expect(other.hasListener, isFalse);
  });

  group('signIn', () {
    setUp(() async {
      repository.emit(const SignedOut());
      await pumpEventQueue();
    });

    test('deve mostrar que está entrando enquanto o login não termina', () {
      unawaited(notifier.signIn());

      expect(notifier.state, isA<SessionSigningIn>());
    });

    test('deve ficar logado com o usuário do login concluído', () async {
      final signingIn = notifier.signIn();

      repository.completeSignIn(SignInCompleted(ana));
      await signingIn;

      expect(
        notifier.state,
        isA<SessionSignedIn>().having((s) => s.user, 'user', ana),
      );
    });

    test('deve voltar a deslogado quando o login é cancelado', () async {
      final signingIn = notifier.signIn();

      repository.completeSignIn(const SignInCancelled());
      await signingIn;

      expect(notifier.state, isA<SessionSignedOut>());
    });

    test('deve mostrar a falha do login', () async {
      final signingIn = notifier.signIn();

      repository.failSignIn(const NetworkFailure());
      await signingIn;

      expect(
        notifier.state,
        isA<SessionFailed>().having(
          (s) => s.failure,
          'failure',
          isA<NetworkFailure>(),
        ),
      );
    });

    test(
      'deve tratar exceção fora das falhas tipadas como inesperada',
      () async {
        final signingIn = notifier.signIn();

        repository.failSignIn(const FormatException('resposta estranha'));
        await signingIn;

        expect(
          notifier.state,
          isA<SessionFailed>().having(
            (s) => s.failure,
            'failure',
            isA<UnexpectedFailure>(),
          ),
        );
      },
    );

    test('deve limpar a falha ao tentar de novo', () async {
      final firstTry = notifier.signIn();
      repository.failSignIn(const NetworkFailure());
      await firstTry;

      unawaited(notifier.signIn());

      expect(notifier.state, isA<SessionSigningIn>());
    });

    test('deve ignorar um segundo login enquanto o primeiro não termina', () {
      unawaited(notifier.signIn());
      unawaited(notifier.signIn());

      expect(repository.pendingSignIns, 1);
    });

    test('deve manter a falha se a conta emitir SignedOut depois', () async {
      final signingIn = notifier.signIn();
      repository.failSignIn(const NetworkFailure());
      await signingIn;

      repository.emit(const SignedOut());
      await pumpEventQueue();

      expect(notifier.state, isA<SessionFailed>());
    });

    test(
      'deve continuar entrando se a conta emitir SignedOut no meio',
      () async {
        unawaited(notifier.signIn());

        repository.emit(const SignedOut());
        await pumpEventQueue();

        expect(notifier.state, isA<SessionSigningIn>());
      },
    );
  });

  group('signOut', () {
    setUp(() async {
      repository.emit(SignedIn(ana));
      await pumpEventQueue();
    });

    test('deve pedir o logout à conta', () async {
      await notifier.signOut();

      expect(repository.signOutCalls, 1);
    });

    test('deve ficar deslogado depois do logout', () async {
      await notifier.signOut();
      await pumpEventQueue();

      expect(notifier.state, isA<SessionSignedOut>());
    });

    test('deve mostrar a falha do logout mesmo depois do SignedOut', () async {
      repository.signOutError = const UnexpectedFailure('cache');

      await notifier.signOut();
      await pumpEventQueue();

      expect(notifier.state, isA<SessionFailed>());
    });
  });
}

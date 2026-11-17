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

    test('deve dizer que a falha foi no login', () async {
      final signingIn = notifier.signIn();

      repository.failSignIn(const NetworkFailure());
      await signingIn;

      expect(notifier.state, isA<SessionSignInFailed>());
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

    test('deve sair do "entrando" mesmo quando um bug sobe do login', () async {
      final signingIn = notifier.signIn();

      repository.failSignIn(StateError('bug'));
      await signingIn.then<void>((_) {}, onError: (Object _) {});

      expect(notifier.state, isA<SessionFailed>());
    });

    test('deve deixar o bug do login subir', () async {
      final signingIn = notifier.signIn();

      repository.failSignIn(StateError('bug'));

      await expectLater(signingIn, throwsStateError);
    });

    test(
      'deve terminar logado se a conta entrou no meio e o login falhou',
      () async {
        final signingIn = notifier.signIn();
        repository.emit(SignedIn(ana));
        await pumpEventQueue();

        repository.failSignIn(const NetworkFailure());
        await signingIn;

        expect(
          notifier.state,
          isA<SessionSignedIn>().having((s) => s.user, 'user', ana),
        );
      },
    );

    test(
      'deve terminar logado se a conta entrou no meio e o login cancelou',
      () async {
        final signingIn = notifier.signIn();
        repository.emit(SignedIn(ana));
        await pumpEventQueue();

        repository.completeSignIn(const SignInCancelled());
        await signingIn;

        expect(notifier.state, isA<SessionSignedIn>());
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

  group('signOut com marcas sem sincronizar', () {
    setUp(() async {
      repository.emit(SignedIn(ana));
      await pumpEventQueue();
    });

    test('deve conferir a sincronização antes de sair', () async {
      await notifier.signOut();

      expect(repository.syncCalls, 1);
    });

    test('deve mostrar a conta saindo enquanto confere', () {
      repository.syncGate = Completer<void>();
      addTearDown(() => repository.syncGate?.complete());

      unawaited(notifier.signOut());

      expect(
        notifier.state,
        isA<SessionSigningOut>().having((s) => s.user, 'user', ana),
      );
    });

    test('deve perguntar quando sobram marcas sem sincronizar', () async {
      repository.synced = false;

      await notifier.signOut();

      expect(
        notifier.state,
        isA<SessionUnsyncedSignOut>().having((s) => s.user, 'user', ana),
      );
    });

    test('não deve sair antes de a pessoa confirmar', () async {
      repository.synced = false;

      await notifier.signOut();

      expect(repository.signOutCalls, 0);
    });

    test('deve sair ao confirmar', () async {
      repository.synced = false;
      await notifier.signOut();

      notifier.confirmSignOut();
      await pumpEventQueue();

      expect(repository.signOutCalls, 1);
    });

    test('não deve conferir de novo ao confirmar', () async {
      repository.synced = false;
      await notifier.signOut();

      notifier.confirmSignOut();
      await pumpEventQueue();

      expect(repository.syncCalls, 1);
    });

    test('deve ficar deslogado depois de confirmar', () async {
      repository.synced = false;
      await notifier.signOut();

      notifier.confirmSignOut();
      await pumpEventQueue();

      expect(notifier.state, isA<SessionSignedOut>());
    });

    test('deve voltar à conta ao cancelar', () async {
      repository.synced = false;
      await notifier.signOut();

      notifier.cancelSignOut();

      expect(
        notifier.state,
        isA<SessionSignedIn>().having((s) => s.user, 'user', ana),
      );
    });

    test('deve deixar sair de novo depois de cancelar', () async {
      repository.synced = false;
      await notifier.signOut();
      notifier.cancelSignOut();
      repository.synced = true;

      await notifier.signOut();

      expect(repository.signOutCalls, 1);
    });

    test('deve ignorar o confirmar sem a pergunta aberta', () async {
      notifier.confirmSignOut();
      await pumpEventQueue();

      expect(repository.signOutCalls, 0);
    });

    test('deve ignorar o cancelar sem a pergunta aberta', () async {
      notifier.cancelSignOut();

      expect(notifier.state, isA<SessionSignedIn>());
    });

    // Depois da falha, a limpeza já começou: conferir de novo não protege
    // mais nada, e a conta do Firebase pode já ter saído.
    test('deve tentar de novo sem conferir depois de uma falha', () async {
      repository.signOutError = const UnexpectedFailure('cache');
      await notifier.signOut();
      repository.signOutError = null;

      await notifier.signOut();

      expect(repository.syncCalls, 1);
    });

    test('deve ignorar o login enquanto pergunta', () async {
      repository.synced = false;
      await notifier.signOut();

      unawaited(notifier.signIn());

      expect(repository.pendingSignIns, 0);
    });
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

    test('deve dizer que a falha foi no logout', () async {
      repository.signOutError = const UnexpectedFailure('cache');

      await notifier.signOut();

      expect(notifier.state, isA<SessionSignOutFailed>());
    });

    test(
      'deve voltar a deslogado quando o logout dá certo depois de uma falha',
      () async {
        repository.signOutError = const UnexpectedFailure('cache');
        await notifier.signOut();
        repository.signOutError = null;

        await notifier.signOut();
        await pumpEventQueue();

        expect(notifier.state, isA<SessionSignedOut>());
      },
    );

    test('deve ignorar o login enquanto um logout não termina', () {
      repository.signOutGate = Completer<void>();
      addTearDown(() => repository.signOutGate?.complete());
      unawaited(notifier.signOut());

      unawaited(notifier.signIn());

      expect(repository.pendingSignIns, 0);
    });

    test('deve ignorar o logout enquanto um login não termina', () async {
      unawaited(notifier.signIn());

      await notifier.signOut();

      expect(repository.signOutCalls, 0);
    });

    test(
      'deve ignorar um segundo logout enquanto o primeiro não termina',
      () async {
        repository.signOutGate = Completer<void>();
        addTearDown(() => repository.signOutGate?.complete());
        unawaited(notifier.signOut());

        unawaited(notifier.signOut());
        await pumpEventQueue();

        expect(repository.signOutCalls, 1);
      },
    );

    test(
      'deve mostrar a falha do logout quando sobe exceção não tipada',
      () async {
        repository.signOutError = Exception('fora do contrato');

        await notifier.signOut();

        expect(
          notifier.state,
          isA<SessionSignOutFailed>().having(
            (state) => state.failure,
            'failure',
            isA<UnexpectedFailure>(),
          ),
        );
      },
    );
  });

  test('deve ignorar um login que termina depois do dispose', () async {
    final other = FakeAuthRepository();
    addTearDown(other.close);
    final disposed = SessionNotifier(repository: other);
    final signingIn = disposed.signIn();
    disposed.dispose();

    other.completeSignIn(SignInCompleted(ana));

    await expectLater(signingIn, completes);
  });

  test('não deve pedir login à conta depois do dispose', () async {
    final other = FakeAuthRepository();
    addTearDown(other.close);
    final disposed = SessionNotifier(repository: other)..dispose();

    await disposed.signIn();

    expect(other.pendingSignIns, 0);
  });
}

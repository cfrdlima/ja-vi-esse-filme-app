import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/core/error/failures.dart';
import 'package:ja_vi_esse_filme/features/auth/domain/entities/account_deletion_outcome.dart';
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

    // A segunda pega as marcas feitas durante a primeira espera, que o
    // `waitForPendingWrites` de antes não cobre.
    test('deve conferir a sincronização duas vezes antes de sair', () async {
      await notifier.signOut();

      expect(repository.syncCalls, 2);
    });

    test('deve perguntar quando a segunda conferência acha marcas', () async {
      repository.syncResults = [true, false];

      await notifier.signOut();

      expect(notifier.state, isA<SessionUnsyncedSignOut>());
    });

    test('deve mostrar a conta saindo ao confirmar', () async {
      repository.synced = false;
      await notifier.signOut();
      repository.signOutGate = Completer<void>();
      addTearDown(() => repository.signOutGate?.complete());

      notifier.confirmSignOut();

      expect(notifier.state, isA<SessionSigningOut>());
    });

    test('deve ignorar o cancelar enquanto a conta sai', () async {
      repository.synced = false;
      await notifier.signOut();
      repository.signOutGate = Completer<void>();
      addTearDown(() => repository.signOutGate?.complete());
      notifier.confirmSignOut();

      notifier.cancelSignOut();

      expect(notifier.state, isA<SessionSigningOut>());
    });

    test('deve ficar deslogado quando a conta cai durante a espera', () async {
      repository
        ..synced = false
        ..syncGate = Completer<void>();
      unawaited(notifier.signOut());
      await pumpEventQueue();

      repository.emit(const SignedOut());
      await pumpEventQueue();
      repository.syncGate!.complete();
      await pumpEventQueue();

      expect(notifier.state, isA<SessionSignedOut>());
    });

    // A conta saiu por fora, mas o cache dela continua no aparelho.
    test(
      'deve limpar o aparelho quando a conta cai durante a espera',
      () async {
        repository
          ..synced = false
          ..syncGate = Completer<void>();
        unawaited(notifier.signOut());
        await pumpEventQueue();

        repository.emit(const SignedOut());
        await pumpEventQueue();
        repository.syncGate!.complete();
        await pumpEventQueue();

        expect(repository.signOutCalls, 1);
      },
    );

    // A espera fica pendente: completá-la no fim rodaria o logout com o
    // fake já fechado.
    test('deve mostrar a conta saindo enquanto confere', () {
      repository.syncGate = Completer<void>();

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

      // As duas conferências são da primeira tentativa.
      expect(repository.syncCalls, 2);
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

  group('deleteAccount', () {
    const offline = NetworkFailure();

    Future<void> signInAs(AppUser user) async {
      repository.emit(SignedIn(user));
      await pumpEventQueue();
    }

    // Começa a exclusão e deixa a resposta do repositório pendente.
    Future<void> startDeletion() async {
      unawaited(notifier.deleteAccount());
      await pumpEventQueue();
    }

    Future<void> answer(AccountDeletionOutcome outcome) async {
      repository.completeDeletion(outcome);
      await pumpEventQueue();
    }

    Future<void> fail(Object error) async {
      repository.failDeletion(error);
      await pumpEventQueue();
    }

    setUp(() => signInAs(ana));

    test('deve mostrar a exclusão em andamento com o usuário', () async {
      await startDeletion();

      expect(
        notifier.state,
        isA<SessionDeletingAccount>().having((s) => s.user, 'user', ana),
      );
    });

    test(
      'deve terminar em SessionAccountDeleted quando a conta é excluída',
      () async {
        await startDeletion();

        await answer(const AccountDeleted());

        expect(notifier.state, isA<SessionAccountDeleted>());
      },
    );

    test('deve voltar à conta quando a pessoa fecha o seletor', () async {
      await startDeletion();

      await answer(const AccountDeletionCancelled());

      expect(
        notifier.state,
        isA<SessionSignedIn>().having((s) => s.user, 'user', ana),
      );
    });

    test(
      'deve mostrar a falha com o usuário, porque a conta continua',
      () async {
        await startDeletion();

        await fail(offline);

        expect(
          notifier.state,
          isA<SessionDeleteAccountFailed>()
              .having((s) => s.user, 'user', ana)
              .having((s) => s.failure, 'failure', offline),
        );
      },
    );

    test('deve tentar de novo a partir da falha', () async {
      await startDeletion();
      await fail(offline);

      await startDeletion();

      expect(repository.pendingDeletions, 1);
    });

    test('deve tratar a exceção fora das falhas tipadas como falha', () async {
      await startDeletion();

      await fail(const FormatException('inesperado'));

      expect(
        notifier.state,
        isA<SessionDeleteAccountFailed>().having(
          (s) => s.failure,
          'failure',
          isA<UnexpectedFailure>(),
        ),
      );
    });

    test('não deve excluir sem conta aberta', () async {
      repository.emit(const SignedOut());
      await pumpEventQueue();

      await startDeletion();

      expect(repository.pendingDeletions, 0);
    });

    test('não deve excluir duas vezes ao mesmo tempo', () async {
      await startDeletion();

      await startDeletion();

      expect(repository.pendingDeletions, 1);
    });

    test('não deve sair da conta durante a exclusão', () async {
      await startDeletion();

      unawaited(notifier.signOut());
      await pumpEventQueue();

      expect(repository.syncCalls + repository.signOutCalls, 0);
    });

    test('não deve abrir o login durante a exclusão', () async {
      await startDeletion();

      unawaited(notifier.signIn());
      await pumpEventQueue();

      expect(repository.pendingSignIns, 0);
    });

    test('não deve excluir durante o logout', () async {
      repository.syncGate = Completer<void>();
      unawaited(notifier.signOut());
      await pumpEventQueue();

      await startDeletion();

      expect(repository.pendingDeletions, 0);
    });

    // O `user.delete()` encerra a sessão no Firebase antes de o
    // repositório terminar o `disconnect()` e a limpeza.
    test('deve continuar excluindo quando o SignedOut chega no meio', () async {
      await startDeletion();

      repository.emit(const SignedOut());
      await pumpEventQueue();

      expect(notifier.state, isA<SessionDeletingAccount>());
    });

    test(
      'deve manter o aviso da exclusão quando o SignedOut chega depois',
      () async {
        await startDeletion();
        await answer(const AccountDeleted());

        repository.emit(const SignedOut());
        await pumpEventQueue();

        expect(notifier.state, isA<SessionAccountDeleted>());
      },
    );

    test(
      'deve ficar deslogado quando a conta sai por fora e a pessoa cancela',
      () async {
        await startDeletion();
        repository.emit(const SignedOut());
        await pumpEventQueue();

        await answer(const AccountDeletionCancelled());

        expect(notifier.state, isA<SessionSignedOut>());
      },
    );

    test(
      'deve ficar deslogado quando a conta sai por fora e a exclusão falha',
      () async {
        await startDeletion();
        repository.emit(const SignedOut());
        await pumpEventQueue();

        await fail(offline);

        expect(notifier.state, isA<SessionSignedOut>());
      },
    );

    // A conta continua aberta depois da falha, e sair segue o caminho do
    // logado: espera as marcas chegarem ao servidor antes de limpar.
    // A conta trocou por fora durante a exclusão: vale o que a conta disse.
    test(
      'deve ficar na conta que chegou durante a exclusão que falha',
      () async {
        final bia = AppUser(uid: 'bia456', displayName: 'Bia');
        await startDeletion();
        repository.emit(SignedIn(bia));
        await pumpEventQueue();

        await fail(offline);

        expect(
          notifier.state,
          isA<SessionSignedIn>().having((s) => s.user, 'user', bia),
        );
      },
    );

    test(
      'deve ficar na conta que chegou durante a exclusão cancelada',
      () async {
        final bia = AppUser(uid: 'bia456', displayName: 'Bia');
        await startDeletion();
        repository.emit(SignedIn(bia));
        await pumpEventQueue();

        await answer(const AccountDeletionCancelled());

        expect(
          notifier.state,
          isA<SessionSignedIn>().having((s) => s.user, 'user', bia),
        );
      },
    );

    test(
      'deve esperar o servidor ao sair depois da exclusão que falhou',
      () async {
        await startDeletion();
        await fail(offline);

        unawaited(notifier.signOut());
        await pumpEventQueue();

        expect(repository.syncCalls, greaterThan(0));
      },
    );

    test('deve deixar entrar de novo depois da exclusão', () async {
      await startDeletion();
      await answer(const AccountDeleted());

      unawaited(notifier.signIn());
      await pumpEventQueue();

      expect(repository.pendingSignIns, 1);
    });
  });
}

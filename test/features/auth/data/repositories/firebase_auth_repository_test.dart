import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:ja_vi_esse_filme/core/error/failures.dart';
import 'package:ja_vi_esse_filme/core/firestore/user_data_write_lock.dart';
import 'package:ja_vi_esse_filme/features/auth/data/gateways/auth_gateways.dart';
import 'package:ja_vi_esse_filme/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:ja_vi_esse_filme/features/auth/domain/entities/account_deletion_outcome.dart';
import 'package:ja_vi_esse_filme/features/auth/domain/entities/app_user.dart';
import 'package:ja_vi_esse_filme/features/auth/domain/entities/auth_state.dart';
import 'package:ja_vi_esse_filme/features/auth/domain/entities/sign_in_outcome.dart';
import 'package:ja_vi_esse_filme/features/auth/domain/repositories/auth_repository.dart';

/// Ordem das chamadas da exclusão, compartilhada pelos fakes.
typedef _Log = List<String>;

class _FakeFirebaseAuthGateway implements FirebaseAuthGateway {
  _FakeFirebaseAuthGateway(this._log);

  final _Log _log;
  final _users = StreamController<AppUser?>.broadcast();

  /// Usuário que o login devolve.
  AppUser signInResult = AppUser(uid: 'abc123', displayName: 'Ana');
  String? receivedIdToken;
  Object? signInError;

  void emit(AppUser? user) => _users.add(user);

  void emitError(Object error) => _users.addError(error);

  Future<void> close() => _users.close();

  @override
  Stream<AppUser?> authStateChanges() => _users.stream;

  AppUser? signedInUser;
  Object? currentUserError;

  @override
  AppUser? get currentUser {
    if (currentUserError case final error?) throw error;
    return signedInUser;
  }

  @override
  Future<AppUser> signInWithGoogleIdToken(String idToken) async {
    receivedIdToken = idToken;
    if (signInError case final error?) throw error;
    return signInResult;
  }

  Object? signOutError;
  var signOutCalls = 0;

  @override
  Future<void> signOut() async {
    signOutCalls++;
    if (signOutError case final error?) throw error;
  }

  String? reauthenticatedIdToken;
  Object? reauthenticateError;

  @override
  Future<void> reauthenticateWithGoogleIdToken(String idToken) async {
    _log.add('reauthenticate');
    reauthenticatedIdToken = idToken;
    if (reauthenticateError case final error?) throw error;
  }

  Object? deleteError;

  @override
  Future<void> deleteCurrentUser() async {
    _log.add('deleteUser');
    if (deleteError case final error?) throw error;
  }
}

class _FakeGoogleAccountGateway implements GoogleAccountGateway {
  _FakeGoogleAccountGateway(this._log);

  final _Log _log;
  String? idToken = 'id-token-do-google';
  Object? authenticateError;
  var authenticateCalls = 0;
  var signOutCalls = 0;
  Object? signOutError;

  /// Chamado ao abrir o seletor, para o teste olhar o estado nessa hora.
  void Function()? onAuthenticate;

  @override
  Future<String?> authenticate() async {
    _log.add('authenticate');
    onAuthenticate?.call();
    authenticateCalls++;
    if (authenticateError case final error?) throw error;
    return idToken;
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    if (signOutError case final error?) throw error;
  }

  Object? disconnectError;

  /// Com um completer aqui, o `disconnect()` fica pendente.
  Completer<void>? disconnectGate;

  @override
  Future<void> disconnect() async {
    _log.add('disconnect');
    await disconnectGate?.future;
    if (disconnectError case final error?) throw error;
  }
}

class _FakeAccountDocuments implements AccountDocumentsGateway {
  _FakeAccountDocuments(this._log, this._writeLock);

  final _Log _log;
  final UserDataWriteLock _writeLock;
  String? deletedUid;
  Object? deleteError;

  /// Se as escritas da Estante estavam travadas quando os documentos foram
  /// apagados.
  bool? lockedWhileDeleting;

  @override
  Future<void> deleteAll(String uid) async {
    _log.add('deleteDocuments');
    lockedWhileDeleting = _writeLock.isLocked;
    deletedUid = uid;
    if (deleteError case final error?) throw error;
  }
}

class _FakeAccountCache implements AccountCacheGateway {
  _FakeAccountCache(this._firebase, this._log);

  final _FakeFirebaseAuthGateway _firebase;
  final _Log _log;
  Object? clearError;
  var clearCalls = 0;

  /// Quantos logouts do Firebase já tinham rodado quando o cache foi limpo.
  int? firebaseSignOutsWhenCleared;

  /// Pendente até o teste completar; nulo completa na hora.
  Completer<void>? pendingWrites;
  Object? waitError;

  /// Com um completer aqui, a limpeza fica pendente.
  Completer<void>? clearGate;

  @override
  Future<void> clear() async {
    _log.add('clearCache');
    clearCalls++;
    await clearGate?.future;
    firebaseSignOutsWhenCleared = _firebase.signOutCalls;
    if (clearError case final Object error) throw error;
  }

  @override
  Future<void> clearUnused() async => throw UnimplementedError();

  @override
  Future<void> waitForPendingWrites() async {
    _log.add('waitPendingWrites');
    if (waitError case final Object error) throw error;
    await pendingWrites?.future;
  }
}

void main() {
  late _FakeFirebaseAuthGateway firebase;
  late _FakeAccountCache cache;
  late _FakeGoogleAccountGateway google;
  late _FakeAccountDocuments documents;
  late FirebaseAuthRepository repository;
  late _Log log;
  late List<Object> reported;
  late UserDataWriteLock writeLock;

  final ana = AppUser(uid: 'abc123', displayName: 'Ana');

  setUp(() {
    log = [];
    reported = [];
    firebase = _FakeFirebaseAuthGateway(log);
    google = _FakeGoogleAccountGateway(log);
    cache = _FakeAccountCache(firebase, log);
    writeLock = UserDataWriteLock();
    documents = _FakeAccountDocuments(log, writeLock);
    repository = FirebaseAuthRepository(
      firebase: firebase,
      google: google,
      cache: cache,
      documents: documents,
      reportError: (error, _) => reported.add(error),
      writeLock: writeLock,
    );
  });

  tearDown(() => firebase.close());

  group('authStateChanges', () {
    test('deve emitir SignedIn com o usuário logado no Firebase', () async {
      final states = repository.authStateChanges.first;

      firebase.emit(ana);

      expect(await states, SignedIn(ana));
    });

    test('deve emitir SignedOut quando não há usuário no Firebase', () async {
      final states = repository.authStateChanges.first;

      firebase.emit(null);

      expect(await states, const SignedOut());
    });
    test('deve traduzir um erro do stream em Failure', () async {
      final states = repository.authStateChanges.first;

      firebase.emitError(FirebaseAuthException(code: 'network-request-failed'));

      await expectLater(states, throwsA(isA<NetworkFailure>()));
    });

    test(
      'deve traduzir um erro desconhecido do stream em UnexpectedFailure',
      () async {
        final states = repository.authStateChanges.first;

        firebase.emitError(ArgumentError('uid inválido'));

        await expectLater(states, throwsA(isA<UnexpectedFailure>()));
      },
    );
  });

  group('signIn', () {
    test('deve devolver o usuário que entrou no Firebase', () async {
      final outcome = await repository.signIn();

      expect(outcome, SignInCompleted(ana));
    });

    test('deve passar ao Firebase o idToken do Google', () async {
      await repository.signIn();

      expect(firebase.receivedIdToken, 'id-token-do-google');
    });

    test('deve devolver quem já está logado sem abrir o seletor', () async {
      firebase.signedInUser = AppUser(uid: 'outro');

      await repository.signIn();

      expect(google.authenticateCalls, 0);
    });

    test('deve devolver o usuário que já está logado', () async {
      final bia = AppUser(uid: 'outro');
      firebase.signedInUser = bia;

      expect(await repository.signIn(), SignInCompleted(bia));
    });

    test('deve devolver SignInCancelled quando o seletor é fechado', () async {
      google.authenticateError = const GoogleSignInException(
        code: GoogleSignInExceptionCode.canceled,
      );

      expect(await repository.signIn(), const SignInCancelled());
    });

    test(
      'deve falhar com UnexpectedFailure se o Google não mandar o idToken',
      () async {
        google.idToken = null;

        await expectLater(
          repository.signIn(),
          throwsA(isA<UnexpectedFailure>()),
        );
      },
    );
  });

  group('signIn traduz os erros', () {
    Future<Object?> failureFromFirebase(String code) async {
      firebase.signInError = FirebaseAuthException(code: code);
      try {
        await repository.signIn();
      } on Object catch (e) {
        return e;
      }
      return null;
    }

    test('deve traduzir user-disabled em AccountDisabledFailure', () async {
      expect(
        await failureFromFirebase('user-disabled'),
        isA<AccountDisabledFailure>(),
      );
    });

    test('deve traduzir network-request-failed em NetworkFailure', () async {
      expect(
        await failureFromFirebase('network-request-failed'),
        isA<NetworkFailure>(),
      );
    });

    test('deve traduzir too-many-requests em RateLimitFailure', () async {
      expect(
        await failureFromFirebase('too-many-requests'),
        isA<RateLimitFailure>(),
      );
    });

    test(
      'deve traduzir outro código do Firebase em UnexpectedFailure',
      () async {
        expect(
          await failureFromFirebase('invalid-credential'),
          isA<UnexpectedFailure>(),
        );
      },
    );

    test('deve traduzir outro código do Google em UnexpectedFailure', () async {
      google.authenticateError = const GoogleSignInException(
        code: GoogleSignInExceptionCode.clientConfigurationError,
      );

      await expectLater(repository.signIn(), throwsA(isA<UnexpectedFailure>()));
    });

    test('deve traduzir erro desconhecido em UnexpectedFailure', () async {
      firebase.signInError = StateError('canal fechado');

      await expectLater(repository.signIn(), throwsA(isA<UnexpectedFailure>()));
    });

    test('deve esconder a mensagem e o e-mail do erro do Firebase', () async {
      firebase.signInError = FirebaseAuthException(
        code: 'account-exists-with-different-credential',
        message: 'conta ana@example.com já existe',
        email: 'ana@example.com',
      );

      final failure = await repository.signIn().then<Object?>(
        (_) => null,
        onError: (Object e) => e,
      );

      expect('$failure', isNot(contains('ana@example.com')));
    });

    test('deve esconder a descrição do erro do Google', () async {
      google.authenticateError = const GoogleSignInException(
        code: GoogleSignInExceptionCode.unknownError,
        description: 'falhou para ana@example.com',
      );

      final failure = await repository.signIn().then<Object?>(
        (_) => null,
        onError: (Object e) => e,
      );

      expect('$failure', isNot(contains('ana@example.com')));
    });

    test('deve traduzir um erro ao ler o usuário atual', () async {
      firebase.currentUserError = ArgumentError('uid inválido');

      await expectLater(repository.signIn(), throwsA(isA<UnexpectedFailure>()));
    });

    test(
      'deve manter o erro do Firebase se sair do Google também falhar',
      () async {
        firebase.signInError = FirebaseAuthException(code: 'user-disabled');
        google.signOutError = const GoogleSignInException(
          code: GoogleSignInExceptionCode.unknownError,
        );

        await expectLater(
          repository.signIn(),
          throwsA(isA<AccountDisabledFailure>()),
        );
      },
    );

    test('deve sair do Google se o Firebase recusar a credencial', () async {
      firebase.signInError = FirebaseAuthException(code: 'invalid-credential');

      await repository.signIn().then<void>((_) {}, onError: (Object _) {});

      expect(google.signOutCalls, 1);
    });
  });

  group('signOut', () {
    test('deve limpar o cache antes de sair do Firebase', () async {
      await repository.signOut();

      expect(cache.firebaseSignOutsWhenCleared, 0);
    });

    test('deve sair do Firebase mesmo se a limpeza falhar', () async {
      cache.clearError = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'failed-precondition',
      );

      await repository.signOut().then<void>((_) {}, onError: (Object _) {});

      expect(firebase.signOutCalls, 1);
    });

    test('deve sair do Google mesmo se a limpeza falhar', () async {
      cache.clearError = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'failed-precondition',
      );

      await repository.signOut().then<void>((_) {}, onError: (Object _) {});

      expect(google.signOutCalls, 1);
    });

    test('deve subir a falha da limpeza só com o código', () async {
      cache.clearError = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'failed-precondition',
        message: 'users/abc123/movies/550',
      );

      await expectLater(
        repository.signOut(),
        throwsA(
          isA<UnexpectedFailure>().having(
            (f) => f.reason,
            'reason',
            'cloud_firestore: failed-precondition',
          ),
        ),
      );
    });

    test('deve sair do Firebase', () async {
      await repository.signOut();

      expect(firebase.signOutCalls, 1);
    });

    test('deve sair do Google', () async {
      await repository.signOut();

      expect(google.signOutCalls, 1);
    });

    test('deve sair do Google mesmo se o Firebase falhar', () async {
      firebase.signOutError = FirebaseAuthException(code: 'internal-error');

      await repository.signOut().then<void>((_) {}, onError: (Object _) {});

      expect(google.signOutCalls, 1);
    });

    test('deve sair do Firebase mesmo se o Google falhar', () async {
      google.signOutError = const GoogleSignInException(
        code: GoogleSignInExceptionCode.unknownError,
      );

      await repository.signOut().then<void>((_) {}, onError: (Object _) {});

      expect(firebase.signOutCalls, 1);
    });

    test('deve subir a falha do Google como Failure', () async {
      google.signOutError = const GoogleSignInException(
        code: GoogleSignInExceptionCode.unknownError,
      );

      await expectLater(
        repository.signOut(),
        throwsA(isA<UnexpectedFailure>()),
      );
    });

    test('deve subir a falha do Firebase como Failure', () async {
      firebase.signOutError = FirebaseAuthException(code: 'internal-error');

      await expectLater(
        repository.signOut(),
        throwsA(isA<UnexpectedFailure>()),
      );
    });
  });

  group('syncPendingChanges', () {
    test('deve confirmar quando as escritas chegam ao servidor', () async {
      expect(await repository.syncPendingChanges(), isTrue);
    });

    test('deve desistir depois de 5 s sem o servidor', () {
      fakeAsync((async) {
        cache.pendingWrites = Completer<void>();
        bool? synced;
        unawaited(repository.syncPendingChanges().then((v) => synced = v));

        async.elapse(const Duration(seconds: 5));

        expect(synced, isFalse);
      });
    });

    test('deve esperar até os 5 s antes de desistir', () {
      fakeAsync((async) {
        cache.pendingWrites = Completer<void>();
        bool? synced;
        unawaited(repository.syncPendingChanges().then((v) => synced = v));

        async.elapse(const Duration(milliseconds: 4999));

        expect(synced, isNull);
      });
    });

    // Sem saber se chegou, a pessoa decide: sair perdendo ou ficar.
    test('deve tratar a espera que falha como não sincronizado', () async {
      cache.waitError = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'unavailable',
      );

      expect(await repository.syncPendingChanges(), isFalse);
    });
  });

  group('deleteAccount', () {
    setUp(() => firebase.signedInUser = ana);

    // Ignora a falha, para o teste olhar só o efeito.
    Future<void> deleteIgnoringFailure() =>
        repository.deleteAccount().then<void>((_) {}, onError: (Object _) {});

    test('deve devolver AccountDeleted quando tudo termina', () async {
      expect(await repository.deleteAccount(), const AccountDeleted());
    });

    test('deve seguir a ordem das decisões 010 e 015', () async {
      await repository.deleteAccount();

      expect(log, [
        'authenticate',
        'reauthenticate',
        'waitPendingWrites',
        'deleteDocuments',
        'deleteUser',
        'disconnect',
        'clearCache',
      ]);
    });

    test('deve reautenticar com o idToken novo do Google', () async {
      await repository.deleteAccount();

      expect(firebase.reauthenticatedIdToken, 'id-token-do-google');
    });

    test('deve apagar os documentos da conta logada', () async {
      await repository.deleteAccount();

      expect(documents.deletedUid, 'abc123');
    });

    group('antes de apagar qualquer coisa', () {
      test('deve falhar com SignInRequiredFailure sem conta', () async {
        firebase.signedInUser = null;

        await expectLater(
          repository.deleteAccount(),
          throwsA(isA<SignInRequiredFailure>()),
        );
      });

      test('não deve abrir o seletor sem conta', () async {
        firebase.signedInUser = null;

        await deleteIgnoringFailure();

        expect(log, isEmpty);
      });

      test(
        'deve devolver AccountDeletionCancelled quando o seletor é fechado',
        () async {
          google.authenticateError = const GoogleSignInException(
            code: GoogleSignInExceptionCode.canceled,
          );

          expect(
            await repository.deleteAccount(),
            const AccountDeletionCancelled(),
          );
        },
      );

      test('não deve apagar nada quando o seletor é fechado', () async {
        google.authenticateError = const GoogleSignInException(
          code: GoogleSignInExceptionCode.canceled,
        );

        await repository.deleteAccount();

        expect(log, ['authenticate']);
      });

      test(
        'deve falhar sem apagar nada quando o Google não manda idToken',
        () async {
          google.idToken = null;

          await expectLater(
            repository.deleteAccount(),
            throwsA(isA<UnexpectedFailure>()),
          );
          expect(log, ['authenticate']);
        },
      );

      test(
        'deve falhar com AccountMismatchFailure quando a conta escolhida é outra',
        () async {
          firebase.reauthenticateError = FirebaseAuthException(
            code: 'user-mismatch',
          );

          await expectLater(
            repository.deleteAccount(),
            throwsA(isA<AccountMismatchFailure>()),
          );
        },
      );

      test('não deve apagar nada quando a reautenticação falha', () async {
        firebase.reauthenticateError = FirebaseAuthException(
          code: 'user-mismatch',
        );

        await deleteIgnoringFailure();

        expect(log, ['authenticate', 'reauthenticate']);
      });

      // A conta foi apagada ou desativada por fora (console, outro app).
      test(
        'deve falhar com AccountDisabledFailure quando a conta já não existe',
        () async {
          firebase.reauthenticateError = FirebaseAuthException(
            code: 'user-not-found',
          );

          await expectLater(
            repository.deleteAccount(),
            throwsA(isA<AccountDisabledFailure>()),
          );
        },
      );

      test('deve pedir login de novo quando a sessão expirou', () async {
        firebase.reauthenticateError = FirebaseAuthException(
          code: 'user-token-expired',
        );

        await expectLater(
          repository.deleteAccount(),
          throwsA(isA<RecentLoginRequiredFailure>()),
        );
      });

      test(
        'deve falhar com NetworkFailure quando a reautenticação fica sem rede',
        () async {
          firebase.reauthenticateError = FirebaseAuthException(
            code: 'network-request-failed',
          );

          await expectLater(
            repository.deleteAccount(),
            throwsA(isA<NetworkFailure>()),
          );
        },
      );
    });

    group('ao apagar os documentos', () {
      test('deve falhar com NetworkFailure quando o prazo acaba', () async {
        documents.deleteError = TimeoutException('lote');

        await expectLater(
          repository.deleteAccount(),
          throwsA(isA<NetworkFailure>()),
        );
      });

      test(
        'deve falhar com NetworkFailure quando o Firestore está offline',
        () async {
          documents.deleteError = FirebaseException(
            plugin: 'cloud_firestore',
            code: 'unavailable',
          );

          await expectLater(
            repository.deleteAccount(),
            throwsA(isA<NetworkFailure>()),
          );
        },
      );

      test('deve falhar com NetworkFailure no deadline-exceeded', () async {
        documents.deleteError = FirebaseException(
          plugin: 'cloud_firestore',
          code: 'deadline-exceeded',
        );

        await expectLater(
          repository.deleteAccount(),
          throwsA(isA<NetworkFailure>()),
        );
      });

      test('deve traduzir a recusa das regras em UnexpectedFailure', () async {
        documents.deleteError = FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
        );

        await expectLater(
          repository.deleteAccount(),
          throwsA(isA<UnexpectedFailure>()),
        );
      });

      // Sem os documentos apagados, excluir o Auth os deixaria órfãos.
      test(
        'não deve excluir a conta no Auth quando a exclusão falha',
        () async {
          documents.deleteError = TimeoutException('lote');

          await deleteIgnoringFailure();

          expect(log, [
            'authenticate',
            'reauthenticate',
            'waitPendingWrites',
            'deleteDocuments',
          ]);
        },
      );
    });

    // Uma marca que chegasse ao servidor depois da última leitura vazia
    // ficaria órfã (`/revisar` da sessão 024).
    group('escritas da Estante', () {
      test('deve travar as escritas enquanto apaga os documentos', () async {
        await repository.deleteAccount();

        expect(documents.lockedWhileDeleting, isTrue);
      });

      test('deve destravar as escritas depois da exclusão', () async {
        await repository.deleteAccount();

        expect(writeLock.isLocked, isFalse);
      });

      test('deve destravar as escritas quando a exclusão falha', () async {
        documents.deleteError = TimeoutException('lote');

        await deleteIgnoringFailure();

        expect(writeLock.isLocked, isFalse);
      });

      test('não deve travar as escritas quando o seletor é fechado', () async {
        google.authenticateError = const GoogleSignInException(
          code: GoogleSignInExceptionCode.canceled,
        );
        var lockedAtSomePoint = false;
        google.onAuthenticate = () => lockedAtSomePoint |= writeLock.isLocked;

        await repository.deleteAccount();

        expect([lockedAtSomePoint, writeLock.isLocked], [false, false]);
      });

      test(
        'deve falhar com NetworkFailure sem apagar quando as escritas pendentes passam do prazo',
        () {
          fakeAsync((async) {
            cache.pendingWrites = Completer<void>();
            Object? error;
            unawaited(
              repository.deleteAccount().then<void>(
                (_) {},
                onError: (Object e) => error = e,
              ),
            );

            async.elapse(AuthRepository.deleteStepTimeout);

            expect(
              [error, log.contains('deleteDocuments')],
              [isA<NetworkFailure>(), false],
            );
          });
        },
      );
    });

    group('ao excluir no Auth', () {
      test(
        'deve falhar com RecentLoginRequiredFailure quando o Auth ainda pede',
        () async {
          firebase.deleteError = FirebaseAuthException(
            code: 'requires-recent-login',
          );

          await expectLater(
            repository.deleteAccount(),
            throwsA(isA<RecentLoginRequiredFailure>()),
          );
        },
      );

      test('não deve desconectar nem limpar quando o Auth falha', () async {
        firebase.deleteError = FirebaseAuthException(
          code: 'network-request-failed',
        );

        await deleteIgnoringFailure();

        expect(log.last, 'deleteUser');
      });
    });

    // Depois do `user.delete()`, a conta já não existe (decisão 015).
    group('depois de excluir no Auth', () {
      test('deve terminar quando o disconnect falha', () async {
        google.disconnectError = const GoogleSignInException(
          code: GoogleSignInExceptionCode.unknownError,
        );

        expect(await repository.deleteAccount(), const AccountDeleted());
      });

      test('deve limpar o cache mesmo quando o disconnect falha', () async {
        google.disconnectError = const GoogleSignInException(
          code: GoogleSignInExceptionCode.unknownError,
        );

        await repository.deleteAccount();

        expect(log.last, 'clearCache');
      });

      test('deve terminar quando a limpeza do cache falha', () async {
        cache.clearError = FirebaseException(
          plugin: 'cloud_firestore',
          code: 'failed-precondition',
        );

        expect(await repository.deleteAccount(), const AccountDeleted());
      });

      // Sem prazo, a tela ficaria em "Excluindo a conta" com a conta já
      // apagada (`/revisar` da sessão 024).
      group('quando um passo não responde', () {
        AccountDeletionOutcome? deleteAndWait(
          FakeAsync async,
          Duration elapsed,
        ) {
          AccountDeletionOutcome? outcome;
          unawaited(repository.deleteAccount().then((o) => outcome = o));
          async.elapse(elapsed);
          return outcome;
        }

        test('deve terminar quando o disconnect não responde', () {
          fakeAsync((async) {
            google.disconnectGate = Completer<void>();

            final outcome = deleteAndWait(
              async,
              AuthRepository.deleteStepTimeout,
            );

            expect(outcome, const AccountDeleted());
          });
        });

        test('deve limpar o cache quando o disconnect não responde', () {
          fakeAsync((async) {
            google.disconnectGate = Completer<void>();

            deleteAndWait(async, AuthRepository.deleteStepTimeout);

            expect(log.last, 'clearCache');
          });
        });

        test('deve terminar quando a limpeza não responde', () {
          fakeAsync((async) {
            cache.clearGate = Completer<void>();

            final outcome = deleteAndWait(
              async,
              AuthRepository.deleteStepTimeout,
            );

            expect(outcome, const AccountDeleted());
          });
        });

        test('deve registrar o prazo esgotado como NetworkFailure', () {
          fakeAsync((async) {
            google.disconnectGate = Completer<void>();

            deleteAndWait(async, AuthRepository.deleteStepTimeout);

            expect(reported, [isA<NetworkFailure>()]);
          });
        });
      });

      test('deve registrar as falhas já traduzidas', () async {
        google.disconnectError = const GoogleSignInException(
          code: GoogleSignInExceptionCode.unknownError,
        );
        cache.clearError = FirebaseException(
          plugin: 'cloud_firestore',
          code: 'failed-precondition',
        );

        await repository.deleteAccount();

        expect(reported, [isA<UnexpectedFailure>(), isA<UnexpectedFailure>()]);
      });
    });
  });
}

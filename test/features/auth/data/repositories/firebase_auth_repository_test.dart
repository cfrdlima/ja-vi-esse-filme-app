import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:ja_vi_esse_filme/core/error/failures.dart';
import 'package:ja_vi_esse_filme/features/auth/data/gateways/auth_gateways.dart';
import 'package:ja_vi_esse_filme/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:ja_vi_esse_filme/features/auth/domain/entities/app_user.dart';
import 'package:ja_vi_esse_filme/features/auth/domain/entities/auth_state.dart';
import 'package:ja_vi_esse_filme/features/auth/domain/entities/sign_in_outcome.dart';

class _FakeFirebaseAuthGateway implements FirebaseAuthGateway {
  final _users = StreamController<AppUser?>.broadcast();

  /// Usuário que o login devolve.
  AppUser signInResult = AppUser(uid: 'abc123', displayName: 'Ana');
  String? receivedIdToken;
  Object? signInError;

  void emit(AppUser? user) => _users.add(user);

  Future<void> close() => _users.close();

  @override
  Stream<AppUser?> authStateChanges() => _users.stream;

  @override
  AppUser? currentUser;

  @override
  Future<AppUser> signInWithGoogleIdToken(String idToken) async {
    receivedIdToken = idToken;
    if (signInError case final error?) throw error;
    return signInResult;
  }

  @override
  Future<void> signOut() => throw UnimplementedError();
}

class _FakeGoogleAccountGateway implements GoogleAccountGateway {
  String? idToken = 'id-token-do-google';
  Object? authenticateError;
  var authenticateCalls = 0;
  var signOutCalls = 0;

  @override
  Future<String?> authenticate() async {
    authenticateCalls++;
    if (authenticateError case final error?) throw error;
    return idToken;
  }

  @override
  Future<void> signOut() async => signOutCalls++;
}

void main() {
  late _FakeFirebaseAuthGateway firebase;
  late _FakeGoogleAccountGateway google;
  late FirebaseAuthRepository repository;

  final ana = AppUser(uid: 'abc123', displayName: 'Ana');

  setUp(() {
    firebase = _FakeFirebaseAuthGateway();
    google = _FakeGoogleAccountGateway();
    repository = FirebaseAuthRepository(firebase: firebase, google: google);
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
      firebase.currentUser = AppUser(uid: 'outro');

      await repository.signIn();

      expect(google.authenticateCalls, 0);
    });

    test('deve devolver o usuário que já está logado', () async {
      final bia = AppUser(uid: 'outro');
      firebase.currentUser = bia;

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

    test('deve sair do Google se o Firebase recusar a credencial', () async {
      firebase.signInError = FirebaseAuthException(code: 'invalid-credential');

      await repository.signIn().then<void>((_) {}, onError: (Object _) {});

      expect(google.signOutCalls, 1);
    });
  });
}

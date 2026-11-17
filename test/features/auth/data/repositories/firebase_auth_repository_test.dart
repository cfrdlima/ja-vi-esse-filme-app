import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/features/auth/data/gateways/auth_gateways.dart';
import 'package:ja_vi_esse_filme/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:ja_vi_esse_filme/features/auth/domain/entities/app_user.dart';
import 'package:ja_vi_esse_filme/features/auth/domain/entities/auth_state.dart';

class _FakeFirebaseAuthGateway implements FirebaseAuthGateway {
  final users = StreamController<AppUser?>.broadcast();

  @override
  Stream<AppUser?> authStateChanges() => users.stream;

  @override
  AppUser? currentUser;

  @override
  Future<AppUser> signInWithGoogleIdToken(String idToken) =>
      throw UnimplementedError();

  @override
  Future<void> signOut() => throw UnimplementedError();
}

class _FakeGoogleAccountGateway implements GoogleAccountGateway {
  @override
  Future<String?> authenticate() => throw UnimplementedError();

  @override
  Future<void> signOut() => throw UnimplementedError();
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

  group('authStateChanges', () {
    test('deve emitir SignedIn com o usuário logado no Firebase', () {
      final states = repository.authStateChanges;

      expectLater(states, emits(SignedIn(ana)));
      firebase.users.add(ana);
    });

    test('deve emitir SignedOut quando não há usuário no Firebase', () {
      final states = repository.authStateChanges;

      expectLater(states, emits(const SignedOut()));
      firebase.users.add(null);
    });
  });
}

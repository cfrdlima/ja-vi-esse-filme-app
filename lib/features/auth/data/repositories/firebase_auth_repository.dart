import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/auth_state.dart';
import '../../domain/entities/sign_in_outcome.dart';
import '../../domain/repositories/auth_repository.dart';
import '../gateways/auth_gateways.dart';

final class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({required this._firebase, required this._google});

  final FirebaseAuthGateway _firebase;
  final GoogleAccountGateway _google;

  @override
  Stream<AuthState> get authStateChanges => _firebase.authStateChanges().map(
    (user) => user == null ? const SignedOut() : SignedIn(user),
  );

  @override
  Future<SignInOutcome> signIn() async {
    if (_firebase.currentUser case final user?) return SignInCompleted(user);
    try {
      return await _signInWithGoogle();
    } on Failure {
      rethrow;
    } on Object catch (error) {
      throw _toFailure(error);
    }
  }

  Future<SignInOutcome> _signInWithGoogle() async {
    final String? idToken;
    try {
      idToken = await _google.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return const SignInCancelled();
      }
      rethrow;
    }
    if (idToken == null) throw const UnexpectedFailure('google: sem idToken');

    try {
      return SignInCompleted(await _firebase.signInWithGoogleIdToken(idToken));
    } on Object {
      await _signOutOfGoogleQuietly();
      rethrow;
    }
  }

  // Sem isso, o Google lembraria a conta recusada pelo Firebase, e a próxima
  // tentativa não mostraria o seletor. Um erro aqui não esconde o original.
  Future<void> _signOutOfGoogleQuietly() async {
    try {
      await _google.signOut();
    } on Object {
      return;
    }
  }

  @override
  Future<void> signOut() => throw UnimplementedError();

  @override
  Future<void> deleteAccount() => throw UnimplementedError();
}

// Só o código vai para a falha: a `message`, o `email` e a `credential` da
// `FirebaseAuthException` e a `description` da `GoogleSignInException` podem
// ter dados pessoais ou tokens (CLAUDE.md, segurança).
Failure _toFailure(Object error) => switch (error) {
  FirebaseAuthException(code: 'user-disabled') =>
    const AccountDisabledFailure(),
  FirebaseAuthException(code: 'network-request-failed') =>
    const NetworkFailure(),
  FirebaseAuthException(code: 'too-many-requests') => const RateLimitFailure(),
  FirebaseAuthException(:final code) => UnexpectedFailure(
    'firebase_auth: $code',
  ),
  GoogleSignInException(:final code) => UnexpectedFailure(
    'google_sign_in: ${code.name}',
  ),
  _ => UnexpectedFailure('auth: ${error.runtimeType}'),
};

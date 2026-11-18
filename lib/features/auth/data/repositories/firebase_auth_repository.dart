import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/error/error_handlers.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/firestore/user_data_write_lock.dart';
import '../../domain/entities/account_deletion_outcome.dart';
import '../../domain/entities/auth_state.dart';
import '../../domain/entities/sign_in_outcome.dart';
import '../../domain/repositories/auth_repository.dart';
import '../gateways/auth_gateways.dart';

final class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    required this._firebase,
    required this._google,
    required this._cache,
    required this._documents,
    required this._reportError,
    required this._writeLock,
  });

  final FirebaseAuthGateway _firebase;
  final GoogleAccountGateway _google;
  final AccountCacheGateway _cache;
  final AccountDocumentsGateway _documents;
  final ErrorReporter _reportError;

  /// Compartilhada com a Estante: travada enquanto os documentos são
  /// apagados (decisão 015).
  final UserDataWriteLock _writeLock;

  @override
  Future<bool> syncPendingChanges() async {
    try {
      await _cache.waitForPendingWrites().timeout(AuthRepository.syncTimeout);
      return true;
    } on Exception {
      // Prazo esgotado (`TimeoutException`) ou erro do SDK: sem saber se
      // chegou, a pessoa decide se sai.
      return false;
    }
  }

  @override
  Stream<AuthState> get authStateChanges => _firebase
      .authStateChanges()
      .map((user) => user == null ? const SignedOut() : SignedIn(user))
      .handleError(_rethrowAsFailure);

  @override
  Future<SignInOutcome> signIn() async {
    try {
      if (_firebase.currentUser case final user?) return SignInCompleted(user);
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
  Future<void> signOut() async {
    // Todos rodam sempre, para a sessão nunca ficar aberta pela metade, nem
    // quando a limpeza do cache falha. A primeira falha sobe depois, já
    // traduzida.
    Object? firstError;
    for (final step in [_cache.clear, _firebase.signOut, _google.signOut]) {
      try {
        await step();
      } on Object catch (error) {
        firstError ??= error;
      }
    }
    if (firstError != null) throw _toFailure(firstError);
  }

  @override
  Future<AccountDeletionOutcome> deleteAccount() async {
    try {
      final user = _firebase.currentUser;
      if (user == null) throw const SignInRequiredFailure();
      if (!await _reauthenticate()) return const AccountDeletionCancelled();
      await _deleteWithWritesLocked(user.uid);
    } on Failure {
      rethrow;
    } on Object catch (error) {
      throw _toFailure(error);
    }
    await _finishDeletion();
    return const AccountDeleted();
  }

  // Com as escritas da Estante travadas e as pendentes já no servidor, a
  // última leitura vazia do `deleteAll` é mesmo a última (`/revisar` da
  // sessão 024). Depois do `delete()`, sem conta, a Estante já recusa.
  Future<void> _deleteWithWritesLocked(String uid) async {
    _writeLock.lock();
    try {
      await _cache.waitForPendingWrites().timeout(
        AuthRepository.deleteStepTimeout,
      );
      await _documents.deleteAll(uid);
      await _firebase.deleteCurrentUser();
    } finally {
      _writeLock.unlock();
    }
  }

  // Antes de apagar qualquer documento (decisão 015): sem isso, um
  // `requires-recent-login` no `user.delete()` viria com os documentos já
  // apagados. Falso quando a pessoa fecha o seletor.
  Future<bool> _reauthenticate() async {
    final String? idToken;
    try {
      idToken = await _google.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return false;
      rethrow;
    }
    if (idToken == null) throw const UnexpectedFailure('google: sem idToken');
    await _firebase.reauthenticateWithGoogleIdToken(idToken);
    return true;
  }

  // A conta já não existe: uma falha aqui não a reabre, e só é registrada.
  // A limpeza roda mesmo se o `disconnect()` falhar. O prazo evita a tela
  // presa em "Excluindo a conta" com a conta já apagada.
  Future<void> _finishDeletion() async {
    for (final step in [_google.disconnect, _cache.clear]) {
      try {
        await step().timeout(AuthRepository.deleteStepTimeout);
      } on Object catch (error, stack) {
        _reportError(_toFailure(error), stack);
      }
    }
  }
}

// No stream, o erro também chega já traduzido, como nos outros métodos.
Never _rethrowAsFailure(Object error) =>
    throw error is Failure ? error : _toFailure(error);

// Só o código vai para a falha: a `message`, o `email` e a `credential` da
// `FirebaseAuthException` e a `description` da `GoogleSignInException` podem
// ter dados pessoais ou tokens (CLAUDE.md, segurança).
Failure _toFailure(Object error) => switch (error) {
  // Na reautenticação, `user-not-found` é a conta apagada por fora.
  FirebaseAuthException(code: 'user-disabled' || 'user-not-found') =>
    const AccountDisabledFailure(),
  FirebaseAuthException(code: 'network-request-failed') =>
    const NetworkFailure(),
  FirebaseAuthException(code: 'too-many-requests') => const RateLimitFailure(),
  FirebaseAuthException(code: 'user-mismatch') =>
    const AccountMismatchFailure(),
  FirebaseAuthException(
    code: 'requires-recent-login' || 'user-token-expired',
  ) =>
    const RecentLoginRequiredFailure(),
  FirebaseAuthException(:final code) => UnexpectedFailure(
    'firebase_auth: $code',
  ),
  // Os lotes da exclusão da conta: sem rede ou sem a confirmação do servidor
  // no prazo (decisão 015).
  TimeoutException() => const NetworkFailure(),
  FirebaseException(
    plugin: 'cloud_firestore',
    code: 'unavailable' || 'deadline-exceeded',
  ) =>
    const NetworkFailure(),
  // A limpeza do cache, no logout, e a recusa das regras na exclusão.
  FirebaseException(:final plugin, :final code) => UnexpectedFailure(
    '$plugin: $code',
  ),
  GoogleSignInException(:final code) => UnexpectedFailure(
    'google_sign_in: ${code.name}',
  ),
  _ => UnexpectedFailure('auth: ${error.runtimeType}'),
};

import 'dart:async';

import 'package:ja_vi_esse_filme/features/auth/domain/entities/account_deletion_outcome.dart';
import 'package:ja_vi_esse_filme/features/auth/domain/entities/auth_state.dart';
import 'package:ja_vi_esse_filme/features/auth/domain/entities/sign_in_outcome.dart';
import 'package:ja_vi_esse_filme/features/auth/domain/repositories/auth_repository.dart';

/// Conta controlada pelo teste: o estado chega por [emit], e cada login fica
/// pendente até o teste responder com [completeSignIn] ou [failSignIn].
class FakeAuthRepository implements AuthRepository {
  final _states = StreamController<AuthState>.broadcast();
  final List<Completer<SignInOutcome>> _pendingSignIns = [];
  AuthState? _current;

  var signOutCalls = 0;
  Object? signOutError;

  /// Com um completer aqui, o logout fica pendente até o teste completá-lo.
  Completer<void>? signOutGate;

  bool get hasListener => _states.hasListener;

  void emit(AuthState state) {
    _current = state;
    _states.add(state);
  }

  void emitError(Object error) => _states.addError(error);

  Future<void> close() => _states.close();

  /// Como o contrato manda, quem assina recebe primeiro o estado atual (o
  /// último [emit]). Antes do primeiro [emit], não há estado: a conta ainda
  /// está carregando.
  @override
  Stream<AuthState> get authStateChanges => Stream.multi((controller) {
    if (_current case final current?) controller.add(current);
    final subscription = _states.stream.listen(
      controller.add,
      onError: controller.addError,
      onDone: controller.close,
    );
    controller.onCancel = subscription.cancel;
  }, isBroadcast: true);

  @override
  Future<SignInOutcome> signIn() {
    final completer = Completer<SignInOutcome>();
    _pendingSignIns.add(completer);
    return completer.future;
  }

  int get pendingSignIns => _pendingSignIns.length;

  void completeSignIn(SignInOutcome outcome) =>
      _pendingSignIns.removeAt(0).complete(outcome);

  void failSignIn(Object error) =>
      _pendingSignIns.removeAt(0).completeError(error);

  /// Como o contrato manda: emite [SignedOut] antes de a falha subir. Como
  /// o Firebase, não emite de novo quando a conta já saiu.
  @override
  Future<void> signOut() async {
    signOutCalls++;
    await signOutGate?.future;
    if (_current is! SignedOut) emit(const SignedOut());
    if (signOutError case final error?) throw error;
  }

  /// O que o [syncPendingChanges] responde.
  var synced = true;
  var syncCalls = 0;

  /// Com um completer aqui, a espera fica pendente até o teste completá-lo.
  Completer<void>? syncGate;

  /// Respostas em ordem, uma por chamada; vazia, vale o [synced].
  List<bool> syncResults = [];

  @override
  Future<bool> syncPendingChanges() async {
    syncCalls++;
    await syncGate?.future;
    if (syncResults.isNotEmpty) return syncResults.removeAt(0);
    return synced;
  }

  final List<Completer<AccountDeletionOutcome>> _pendingDeletions = [];

  /// Cada exclusão fica pendente até o teste responder com
  /// [completeDeletion] ou [failDeletion].
  @override
  Future<AccountDeletionOutcome> deleteAccount() {
    final completer = Completer<AccountDeletionOutcome>();
    _pendingDeletions.add(completer);
    return completer.future;
  }

  int get pendingDeletions => _pendingDeletions.length;

  void completeDeletion(AccountDeletionOutcome outcome) =>
      _pendingDeletions.removeAt(0).complete(outcome);

  void failDeletion(Object error) =>
      _pendingDeletions.removeAt(0).completeError(error);
}

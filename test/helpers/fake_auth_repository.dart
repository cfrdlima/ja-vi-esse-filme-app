import 'dart:async';

import 'package:ja_vi_esse_filme/features/auth/domain/entities/auth_state.dart';
import 'package:ja_vi_esse_filme/features/auth/domain/entities/sign_in_outcome.dart';
import 'package:ja_vi_esse_filme/features/auth/domain/repositories/auth_repository.dart';

/// Conta controlada pelo teste: o estado chega por [emit], e cada login fica
/// pendente até o teste responder com [completeSignIn] ou [failSignIn].
class FakeAuthRepository implements AuthRepository {
  final _states = StreamController<AuthState>.broadcast();
  final List<Completer<SignInOutcome>> _pendingSignIns = [];

  var signOutCalls = 0;
  Object? signOutError;

  bool get hasListener => _states.hasListener;

  void emit(AuthState state) => _states.add(state);

  void emitError(Object error) => _states.addError(error);

  Future<void> close() => _states.close();

  @override
  Stream<AuthState> get authStateChanges => _states.stream;

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

  /// Como o contrato manda: emite [SignedOut] antes de a falha subir.
  @override
  Future<void> signOut() async {
    signOutCalls++;
    emit(const SignedOut());
    if (signOutError case final error?) throw error;
  }

  @override
  Future<void> deleteAccount() => throw UnimplementedError();
}

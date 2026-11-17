import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/auth_state.dart';
import '../../domain/entities/sign_in_outcome.dart';
import '../../domain/repositories/auth_repository.dart';
import 'session_state.dart';

/// A conta do usuário para a UI: espelha o `authStateChanges` e conduz o
/// login e o logout. O estado logado vem só do stream da conta, nunca de uma
/// flag guardada no aparelho (sessão 018, `security-auditor`).
class SessionNotifier extends ChangeNotifier {
  SessionNotifier({required this._repository}) {
    _subscription = _repository.authStateChanges.listen(_onAuthState);
  }

  final AuthRepository _repository;
  late final StreamSubscription<AuthState> _subscription;

  SessionState _state = const SessionLoading();
  SessionState get state => _state;

  bool _signingIn = false;
  bool _disposed = false;

  /// Abre o login do Google. Serve também para "tentar de novo".
  Future<void> signIn() async {
    if (_disposed || _signingIn) return;
    _signingIn = true;
    _emit(const SessionSigningIn());
    try {
      _emit(switch (await _repository.signIn()) {
        SignInCompleted(:final user) => SessionSignedIn(user),
        SignInCancelled() => const SessionSignedOut(),
      });
    } on Failure catch (failure) {
      _emit(SessionFailed(failure));
    } on Exception {
      // O repositório só lança Failure; outra exceção não pode deixar a tela
      // entrando para sempre. `Error` (bug) continua subindo.
      _emit(
        const SessionFailed(
          UnexpectedFailure('exceção fora das falhas tipadas'),
        ),
      );
    } finally {
      _signingIn = false;
    }
  }

  // Durante o login, quem decide o estado é o resultado dele: um SignedOut que
  // chegue no meio não pode esconder o "entrando".
  void _onAuthState(AuthState authState) {
    if (_signingIn) return;
    _emit(switch (authState) {
      SignedOut() => const SessionSignedOut(),
      SignedIn(:final user) => SessionSignedIn(user),
    });
  }

  void _emit(SessionState state) {
    if (_disposed) return;
    _state = state;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_subscription.cancel());
    super.dispose();
  }
}

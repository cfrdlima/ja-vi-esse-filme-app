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
    _subscription = _repository.authStateChanges.listen(
      _onAuthState,
      onError: _onAuthError,
    );
  }

  final AuthRepository _repository;
  late final StreamSubscription<AuthState> _subscription;

  SessionState _state = const SessionLoading();
  SessionState get state => _state;

  bool _signingIn = false;

  /// O último estado da conta que chegou durante o login, guardado para o
  /// fim dele. `null` quando não chegou nenhum.
  AuthState? _arrivedDuringSignIn;
  bool _disposed = false;

  /// Abre o login do Google. Serve também para "tentar de novo".
  Future<void> signIn() async {
    if (_disposed || _signingIn) return;
    _signingIn = true;
    _arrivedDuringSignIn = null;
    _emit(const SessionSigningIn());
    try {
      _emit(switch (await _repository.signIn()) {
        SignInCompleted(:final user) => SessionSignedIn(user),
        SignInCancelled() => _reconcile(const SessionSignedOut()),
      });
    } on Failure catch (failure) {
      _emit(_reconcile(SessionFailed(failure)));
    } on Exception {
      // O repositório só lança Failure; outra exceção não pode deixar a tela
      // entrando para sempre.
      _emit(
        _reconcile(
          const SessionFailed(
            UnexpectedFailure('exceção fora das falhas tipadas'),
          ),
        ),
      );
    } on Error {
      // Um bug continua subindo, mas sem deixar a tela presa em "entrando".
      _emit(const SessionFailed(UnexpectedFailure('erro no login')));
      rethrow;
    } finally {
      _signingIn = false;
    }
  }

  /// Encerra a sessão. O deslogado chega pelo stream da conta; uma falha na
  /// limpeza fica visível, porque o usuário precisa saber.
  Future<void> signOut() async {
    if (_disposed) return;
    try {
      await _repository.signOut();
    } on Failure catch (failure) {
      _emit(SessionFailed(failure));
    }
  }

  // A conta pode ter entrado de verdade no nativo mesmo com o login do Dart
  // cancelado ou com falha: nesse caso, vale o que a conta disse.
  SessionState _reconcile(SessionState fallback) =>
      switch (_arrivedDuringSignIn) {
        SignedIn(:final user) => SessionSignedIn(user),
        _ => fallback,
      };

  // Durante o login, quem decide o estado é o resultado dele: um SignedOut que
  // chegue no meio não pode esconder o "entrando". O estado fica guardado para
  // o fim dele. Uma falha já significa
  // sessão fechada, e o SignedOut que vem depois dela não a esconde.
  void _onAuthState(AuthState authState) {
    if (_signingIn) {
      _arrivedDuringSignIn = authState;
      return;
    }
    if (_state is SessionFailed && authState is SignedOut) return;
    _emit(switch (authState) {
      SignedOut() => const SessionSignedOut(),
      SignedIn(:final user) => SessionSignedIn(user),
    });
  }

  // Sem isso, um erro no stream deixaria a tela carregando para sempre.
  void _onAuthError(Object error) {
    if (_signingIn) return;
    _emit(
      SessionFailed(
        error is Failure
            ? error
            : const UnexpectedFailure('erro fora das falhas tipadas'),
      ),
    );
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

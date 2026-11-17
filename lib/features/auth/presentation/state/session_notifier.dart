import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/entities/auth_state.dart';
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

  void _onAuthState(AuthState authState) => _emit(switch (authState) {
    SignedOut() => const SessionSignedOut(),
    SignedIn(:final user) => SessionSignedIn(user),
  });

  void _emit(SessionState state) {
    _state = state;
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}

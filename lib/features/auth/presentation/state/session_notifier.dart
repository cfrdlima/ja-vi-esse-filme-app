import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/account_deletion_outcome.dart';
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

  static const _untypedException = UnexpectedFailure(
    'exceção fora das falhas tipadas',
  );

  final AuthRepository _repository;
  late final StreamSubscription<AuthState> _subscription;

  SessionState _state = const SessionLoading();
  SessionState get state => _state;

  bool _signingIn = false;
  bool _signingOut = false;
  bool _deleting = false;

  /// O último estado da conta que chegou durante o login ou a exclusão,
  /// guardado para o fim deles. `null` quando não chegou nenhum.
  AuthState? _arrivedWhileBusy;

  bool get _busy => _signingIn || _signingOut || _deleting;
  bool _disposed = false;

  /// Abre o login do Google. Serve também para "tentar de novo". Com um
  /// logout em andamento, não faz nada: o Firebase sai antes do Google, e o
  /// seletor abriria com a limpeza ainda rodando.
  Future<void> signIn() async {
    if (_disposed || _busy) return;
    // A conta já está aberta, esperando a resposta da pergunta do logout.
    if (_state is SessionUnsyncedSignOut) return;
    _signingIn = true;
    _arrivedWhileBusy = null;
    _emit(const SessionSigningIn());
    try {
      _emit(switch (await _repository.signIn()) {
        SignInCompleted(:final user) => SessionSignedIn(user),
        SignInCancelled() => _reconcile(const SessionSignedOut()),
      });
    } on Failure catch (failure) {
      _emit(_reconcile(SessionSignInFailed(failure)));
    } on Exception {
      // O repositório só lança Failure; outra exceção não pode deixar a tela
      // entrando para sempre.
      _emit(_reconcile(const SessionSignInFailed(_untypedException)));
    } on Error {
      // Um bug continua subindo, mas sem deixar a tela presa em "entrando".
      _emit(const SessionSignInFailed(UnexpectedFailure('erro no login')));
      rethrow;
    } finally {
      _signingIn = false;
    }
  }

  /// Encerra a sessão. Com a conta aberta, primeiro espera as marcas do
  /// aparelho chegarem ao servidor, duas vezes: a segunda pega as marcas
  /// feitas durante a primeira espera. Se sobrar alguma, pergunta antes
  /// ([SessionUnsyncedSignOut]), porque sair as apaga. Depois de uma falha
  /// no logout, tenta de novo sem perguntar: a limpeza já começou.
  ///
  /// Uma falha na limpeza fica visível, porque o usuário precisa saber. Com
  /// um login em andamento, não faz nada: o resultado dele ainda vai decidir
  /// o estado.
  Future<void> signOut() async {
    if (_disposed || _busy) return;
    _signingOut = true;
    try {
      // Depois de uma exclusão que falhou, a conta continua aberta.
      if (_state
          case SessionSignedIn(:final user) ||
              SessionDeleteAccountFailed(:final user)) {
        _emit(SessionSigningOut(user));
        final synced =
            await _repository.syncPendingChanges() &&
            await _repository.syncPendingChanges();
        // A conta mudou durante a espera. Se ela saiu por fora, o cache
        // dela continua no aparelho e precisa ser limpo.
        if (_state is! SessionSigningOut) {
          if (_state is SessionSignedOut) await _runSignOut();
          return;
        }
        if (!synced) {
          _emit(SessionUnsyncedSignOut(user));
          return;
        }
      }
      await _runSignOut();
    } finally {
      _signingOut = false;
    }
  }

  /// Exclui a conta (decisão 015). Serve também para "tentar de novo", a
  /// partir da falha. Só com a conta aberta e nada mais em andamento.
  Future<void> deleteAccount() async {
    if (_disposed || _busy) return;
    final user = switch (_state) {
      SessionSignedIn(:final user) ||
      SessionDeleteAccountFailed(:final user) => user,
      _ => null,
    };
    if (user == null) return;
    _deleting = true;
    _arrivedWhileBusy = null;
    _emit(SessionDeletingAccount(user));
    try {
      _emit(switch (await _repository.deleteAccount()) {
        AccountDeleted() => const SessionAccountDeleted(),
        AccountDeletionCancelled() => _reconcile(SessionSignedIn(user)),
      });
    } on Failure catch (failure) {
      _emit(_reconcile(SessionDeleteAccountFailed(user, failure)));
    } on Exception {
      _emit(_reconcile(SessionDeleteAccountFailed(user, _untypedException)));
    } on Error {
      _emit(
        SessionDeleteAccountFailed(
          user,
          const UnexpectedFailure('erro na exclusão'),
        ),
      );
      rethrow;
    } finally {
      _deleting = false;
    }
  }

  /// Sai mesmo com marcas sem sincronizar, depois da pergunta.
  void confirmSignOut() {
    if (_disposed || _signingOut || _deleting) return;
    if (_state case SessionUnsyncedSignOut(:final user)) {
      _signingOut = true;
      _emit(SessionSigningOut(user));
      unawaited(_runSignOut().whenComplete(() => _signingOut = false));
    }
  }

  /// Desiste de sair, e a conta continua aberta. Com a saída já em
  /// andamento, não há mais como desistir.
  void cancelSignOut() {
    if (_signingOut) return;
    if (_state case SessionUnsyncedSignOut(:final user)) {
      _emit(SessionSignedIn(user));
    }
  }

  Future<void> _runSignOut() async {
    try {
      await _repository.signOut();
      // Não espera o stream: depois de uma falha, o Firebase já saiu na
      // primeira tentativa e não emite SignedOut de novo, e a tela ficaria
      // presa no erro.
      _emit(const SessionSignedOut());
    } on Failure catch (failure) {
      _emit(SessionSignOutFailed(failure));
    } on Exception {
      // Mesmo motivo do signIn: a tela precisa ver o erro e o "tentar de novo".
      _emit(const SessionSignOutFailed(_untypedException));
    }
  }

  // A conta pode ter entrado de verdade no nativo mesmo com o login do Dart
  // cancelado ou com falha: nesse caso, vale o que a conta disse. Na
  // exclusão cancelada ou com falha, a conta pode ter saído por fora.
  SessionState _reconcile(SessionState fallback) => switch (_arrivedWhileBusy) {
    SignedIn(:final user) => SessionSignedIn(user),
    SignedOut() when _deleting => const SessionSignedOut(),
    _ => fallback,
  };

  // Durante o login, quem decide o estado é o resultado dele: um SignedOut que
  // chegue no meio não pode esconder o "entrando". O estado fica guardado para
  // o fim dele. Depois de uma falha, o SignedOut que vem em seguida não a
  // esconde: a pessoa precisa ver o erro e o "tentar de novo".
  //
  // Na exclusão, o `user.delete()` emite SignedOut antes de o repositório
  // terminar, e o "excluindo" fica até o fim. Depois, um SignedOut repetido
  // não apaga o aviso de conta excluída.
  void _onAuthState(AuthState authState) {
    if (_signingIn || _deleting) {
      _arrivedWhileBusy = authState;
      return;
    }
    if (_state is SessionFailed && authState is SignedOut) return;
    if (_state is SessionSignedOut && authState is SignedOut) return;
    _emit(switch (authState) {
      SignedOut() => const SessionSignedOut(),
      SignedIn(:final user) => SessionSignedIn(user),
    });
  }

  // Sem isso, um erro no stream deixaria a tela carregando para sempre.
  void _onAuthError(Object error) {
    if (_signingIn || _deleting) return;
    _emit(
      SessionSignInFailed(
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

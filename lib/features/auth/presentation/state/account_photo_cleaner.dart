import 'session_notifier.dart';
import 'session_state.dart';

/// Tira a foto da conta do cache de imagens quando a sessão fecha: a foto é
/// dado pessoal, e o logout limpa o aparelho (decisão 010). O [evict] vem da
/// composição, para o estado não depender do pacote de imagens.
class AccountPhotoCleaner {
  AccountPhotoCleaner({required this._session, required this._evict}) {
    _session.addListener(_onSessionChanged);
  }

  final SessionNotifier _session;
  final void Function(String url) _evict;

  /// A foto da conta logada por último, até a sessão fechar.
  String? _photoUrl;

  // Só quando a conta sai (deslogado) ou troca (outro usuário). Um erro no
  // stream ou uma falha não fecham a sessão, e a foto continua em uso.
  void _onSessionChanged() {
    final current = switch (_session.state) {
      SessionSignedOut() => null,
      SessionSignedIn(:final user) => user.photoUrl,
      _ => _photoUrl,
    };
    final previous = _photoUrl;
    _photoUrl = current;
    if (previous != null && previous != current) _evict(previous);
  }
}

/// Quais URLs o app aceita abrir fora dele (decisão 009).
///
/// A lista de hosts é própria, e não o `AppConfig.allowedHosts`: aquela
/// recebe o token Bearer, e um host de link externo nela mandaria o token
/// para fora do TMDB (decisões 001 e 006).
final class ExternalLinkPolicy {
  const ExternalLinkPolicy._(this._pathsByHost);

  /// Só os caminhos que o app monta: o trailer (`/watch`) e a política
  /// publicada. Um prefixo deixaria passar `/redirect?q=` no YouTube e
  /// `..%2F` no Pages, onde cada repositório da conta é um site no mesmo
  /// host (revisão da sessão 014).
  static const app = ExternalLinkPolicy._({
    'www.youtube.com': {'/watch'},
    'cfrdlima.github.io': {'/ja-vi-esse-filme-suporte/'},
  });

  final Map<String, Set<String>> _pathsByHost;

  /// Host comparado por igualdade, sem `endsWith`: `evil.www.youtube.com`
  /// não passa. O [Uri] já põe o host em minúsculas e resolve `..` no
  /// caminho antes da comparação.
  bool allows(Uri url) {
    final paths = _pathsByHost[url.host];
    return url.scheme == 'https' &&
        paths != null &&
        paths.contains(url.path) &&
        url.userInfo.isEmpty &&
        !url.hasPort;
  }
}

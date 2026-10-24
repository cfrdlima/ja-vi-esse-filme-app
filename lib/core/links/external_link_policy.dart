/// Quais URLs o app aceita abrir fora dele (decisão 009).
///
/// A lista de hosts é própria, e não o `AppConfig.allowedHosts`: aquela
/// recebe o token Bearer, e um host de link externo nela mandaria o token
/// para fora do TMDB (decisões 001 e 006).
final class ExternalLinkPolicy {
  const ExternalLinkPolicy._(this._pathPrefixByHost);

  /// No `cfrdlima.github.io`, cada repositório da conta é um site; o prefixo
  /// limita o link ao repositório de suporte (decisão 006).
  static const app = ExternalLinkPolicy._({
    'www.youtube.com': '/',
    'cfrdlima.github.io': '/ja-vi-esse-filme-suporte/',
  });

  final Map<String, String> _pathPrefixByHost;

  /// Host comparado por igualdade, sem `endsWith`: `evil.www.youtube.com`
  /// não passa. O [Uri] já põe o host em minúsculas e resolve `..` no
  /// caminho, então o prefixo não é contornado por `/suporte/../outro/`.
  bool allows(Uri url) {
    final pathPrefix = _pathPrefixByHost[url.host];
    return url.scheme == 'https' &&
        pathPrefix != null &&
        url.path.startsWith(pathPrefix) &&
        url.userInfo.isEmpty &&
        !url.hasPort;
  }
}

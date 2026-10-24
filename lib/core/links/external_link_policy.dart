/// Quais URLs o app aceita abrir fora dele (decisão 009).
///
/// A lista de hosts é própria, e não o `AppConfig.allowedHosts`: aquela
/// recebe o token Bearer, e um host de link externo nela mandaria o token
/// para fora do TMDB (decisões 001 e 006).
final class ExternalLinkPolicy {
  const ExternalLinkPolicy._(this._hosts);

  static const app = ExternalLinkPolicy._({'www.youtube.com'});

  final Set<String> _hosts;

  /// Host comparado por igualdade, sem `endsWith`: `evil.www.youtube.com`
  /// não passa. O [Uri] já põe o host em minúsculas.
  bool allows(Uri url) =>
      url.scheme == 'https' &&
      _hosts.contains(url.host) &&
      url.userInfo.isEmpty &&
      !url.hasPort;
}

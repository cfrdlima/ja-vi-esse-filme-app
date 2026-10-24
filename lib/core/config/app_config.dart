/// Configuração do app vinda de `--dart-define-from-file=env/<ambiente>.json`.
///
/// É o único lugar que lê `String.fromEnvironment`. O token embutido no APK
/// pode ser extraído (decisão 001), então nunca aparece em mensagem ou log.
class AppConfig {
  AppConfig({required this.tmdbReadToken, required this.tmdbBaseUrl}) {
    if (tmdbReadToken.isEmpty) {
      throw const ConfigException('TMDB_READ_ACCESS_TOKEN vazio');
    }
    _validateBaseUrl(tmdbBaseUrl);
  }

  factory AppConfig.parse({
    required String tmdbReadToken,
    required String tmdbBaseUrl,
  }) {
    final baseUrl = Uri.tryParse(tmdbBaseUrl);
    if (baseUrl == null) {
      throw const ConfigException('TMDB_BASE_URL malformada');
    }
    return AppConfig(tmdbReadToken: tmdbReadToken.trim(), tmdbBaseUrl: baseUrl);
  }

  factory AppConfig.fromEnvironment() {
    const token = String.fromEnvironment('TMDB_READ_ACCESS_TOKEN');
    const baseUrl = String.fromEnvironment('TMDB_BASE_URL');
    if (baseUrl.isEmpty) {
      throw const ConfigException('TMDB_BASE_URL ausente');
    }
    return AppConfig.parse(tmdbReadToken: token, tmdbBaseUrl: baseUrl);
  }

  /// Versão do app para a tela Sobre, passada no build com
  /// `--dart-define=APP_VERSION=...` a partir do `pubspec.yaml`. Vazia quando
  /// o build não a informa, e aí a tela não mostra a versão.
  static const appVersion = String.fromEnvironment('APP_VERSION');

  /// O token vai no header de toda requisição para este host. Um proxy
  /// (decisão 001) entra aqui quando existir.
  static const allowedHosts = {'api.themoviedb.org'};

  final String tmdbReadToken;
  final Uri tmdbBaseUrl;

  static void _validateBaseUrl(Uri url) {
    if (url.scheme != 'https') {
      throw const ConfigException('TMDB_BASE_URL precisa usar HTTPS');
    }
    if (!allowedHosts.contains(url.host)) {
      throw const ConfigException('TMDB_BASE_URL com host não permitido');
    }
    if (url.userInfo.isNotEmpty || url.hasQuery || url.hasFragment) {
      throw const ConfigException(
        'TMDB_BASE_URL não aceita usuário, query nem fragment',
      );
    }
  }
}

class ConfigException implements Exception {
  const ConfigException(this.message);

  final String message;

  @override
  String toString() => 'ConfigException: $message';
}

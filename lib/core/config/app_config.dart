/// Configuração do app vinda de `--dart-define-from-file=env/<ambiente>.json`.
///
/// É o único lugar que lê `String.fromEnvironment`. O token embutido no APK
/// pode ser extraído (decisão 001), então nunca aparece em mensagem ou log.
class AppConfig {
  AppConfig({required this.tmdbReadToken, required this.tmdbBaseUrl}) {
    if (tmdbReadToken.isEmpty) {
      throw const ConfigException('TMDB_READ_ACCESS_TOKEN vazio');
    }
    if (tmdbBaseUrl.scheme != 'https') {
      throw const ConfigException('TMDB_BASE_URL precisa usar HTTPS');
    }
  }

  factory AppConfig.fromEnvironment() {
    const token = String.fromEnvironment('TMDB_READ_ACCESS_TOKEN');
    const baseUrl = String.fromEnvironment('TMDB_BASE_URL');
    if (baseUrl.isEmpty) {
      throw const ConfigException('TMDB_BASE_URL ausente');
    }
    return AppConfig(tmdbReadToken: token, tmdbBaseUrl: Uri.parse(baseUrl));
  }

  final String tmdbReadToken;
  final Uri tmdbBaseUrl;
}

class ConfigException implements Exception {
  const ConfigException(this.message);

  final String message;

  @override
  String toString() => 'ConfigException: $message';
}

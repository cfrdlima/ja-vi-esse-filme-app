/// Tipo de vídeo do TMDB que a tela mostra como trailer.
enum TrailerKind { trailer, teaser }

/// Trailer de um filme hospedado no YouTube.
final class Trailer {
  /// Recusa com [FormatException] a [key] fora do formato do YouTube: ela vem
  /// do TMDB, que é editado pela comunidade, e vira parte de uma URL.
  Trailer({
    required this.key,
    required this.name,
    required this.kind,
    required this.official,
    required this.language,
    this.country = '',
  }) {
    if (!_youtubeKey.hasMatch(key)) {
      throw FormatException('key fora do formato do YouTube', key);
    }
  }

  static final _youtubeKey = RegExp(r'^[A-Za-z0-9_-]{11}$');

  final String key;
  final String name;
  final TrailerKind kind;
  final bool official;

  /// Código ISO 639-1 do idioma do vídeo, ou vazio quando o TMDB não informa.
  final String language;

  /// Código ISO 3166-1 do país do vídeo, ou vazio quando o TMDB não informa.
  /// Separa a dublagem do Brasil da de Portugal, que dividem o idioma `pt`.
  final String country;

  /// A URL sai de um molde fixo, e não do TMDB (decisão 009).
  Uri get youtubeUrl => Uri.https('www.youtube.com', '/watch', {'v': key});
}

/// URLs de imagem do TMDB (`https://image.tmdb.org/t/p/<tamanho><caminho>`).
/// O host é fixo aqui, e não vem do JSON, para que um caminho malformado não
/// leve a imagem para outro servidor.
abstract final class TmdbImageUrl {
  static const _host = 'image.tmdb.org';

  /// Tamanho de pôster em grade (`tela-4-estados`).
  static Uri poster(String path) => _build('w342', path);

  /// Um caminho do TMDB começa com `/` e não tem segmento vazio, `.` nem
  /// `..` (o que impede `//outro.host` e subida de pasta).
  static bool isValidPath(String path) =>
      path.startsWith('/') &&
      path
          .split('/')
          .skip(1)
          .every((s) => s.isNotEmpty && s != '.' && s != '..');

  static Uri _build(String size, String path) {
    if (!isValidPath(path)) {
      throw ArgumentError.value(path, 'path', 'caminho inválido');
    }
    return Uri.https(_host, '/t/p/$size$path');
  }
}

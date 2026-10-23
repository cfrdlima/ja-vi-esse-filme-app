import '../../../../core/network/tmdb_image_url.dart';

/// Leituras defensivas de campos do JSON do TMDB, que manda `null`, string
/// vazia e número inteiro onde se espera outro tipo.
abstract final class TmdbJson {
  static String? nonEmpty(Object? value) =>
      value is String && value.isNotEmpty ? value : null;

  // Caminho fora do formato do TMDB vira "sem imagem", e não exceção na
  // hora de montar a URL.
  static String? imagePath(Object? value) => switch (nonEmpty(value)) {
    final path? when TmdbImageUrl.isValidPath(path) => path,
    _ => null,
  };

  static double voteAverage(Object? value) => switch (value) {
    final num number => number.toDouble(),
    _ => 0,
  };

  // `DateTime.tryParse` aceita "2023-13-45" e rola para outra data; só vale
  // a data que volta igual ao texto.
  static DateTime? date(Object? value) {
    if (value is! String) return null;
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
    if (match == null) return null;
    final [year, month, day] = [
      1,
      2,
      3,
    ].map((group) => int.parse(match.group(group)!)).toList();
    final date = DateTime(year, month, day);
    final valid = date.year == year && date.month == month && date.day == day;
    return valid ? date : null;
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/features/movies/domain/entities/trailer.dart';

void main() {
  Trailer trailerWithKey(String key) => Trailer(
    key: key,
    name: 'Trailer oficial',
    kind: TrailerKind.trailer,
    official: true,
    language: 'pt',
  );

  test('deve montar a URL do YouTube a partir da key', () {
    final trailer = trailerWithKey('Way9Dexny3w');

    expect(
      trailer.youtubeUrl,
      Uri.parse('https://www.youtube.com/watch?v=Way9Dexny3w'),
    );
  });

  test('deve aceitar key com hífen e sublinhado', () {
    final trailer = trailerWithKey('a-b_C1d2E3f');

    expect(trailer.key, 'a-b_C1d2E3f');
  });

  for (final key in [
    '',
    'curta',
    'Way9Dexny3wX',
    'Way9Dexny3',
    'Way9Dex/y3w',
    'Way9Dex?y3w',
    'Way9Dex&y3w',
    'Way9Dex y3w',
    'Way9Dexny3ç',
  ]) {
    test('deve recusar a key "$key", fora do formato do YouTube', () {
      expect(() => trailerWithKey(key), throwsFormatException);
    });
  }
}

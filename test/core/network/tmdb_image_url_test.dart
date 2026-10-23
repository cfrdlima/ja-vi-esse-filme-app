import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/core/network/tmdb_image_url.dart';

void main() {
  test('deve montar a URL do pôster em w342', () {
    final url = TmdbImageUrl.poster('/abc.jpg');

    expect(url.toString(), 'https://image.tmdb.org/t/p/w342/abc.jpg');
  });

  test('deve recusar caminho que não começa com barra', () {
    expect(
      () => TmdbImageUrl.poster('https://outro.host/x.jpg'),
      throwsArgumentError,
    );
  });

  test('deve recusar caminho com subida de pasta', () {
    expect(() => TmdbImageUrl.poster('/../x.jpg'), throwsArgumentError);
  });

  test('deve aceitar caminho de imagem do TMDB como válido', () {
    expect(TmdbImageUrl.isValidPath('/abc.jpg'), isTrue);
  });

  test('não deve aceitar caminho de outro host como válido', () {
    expect(TmdbImageUrl.isValidPath('//outro.host/x.jpg'), isFalse);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/rating.dart';

void main() {
  group('Rating', () {
    test('deve aceitar meia estrela', () {
      expect(Rating(1).stars, 0.5);
    });

    test('deve aceitar cinco estrelas', () {
      expect(Rating(10).stars, 5);
    });

    test('deve recusar nota zero', () {
      expect(() => Rating(0), throwsArgumentError);
    });

    test('deve recusar mais de cinco estrelas', () {
      expect(() => Rating(11), throwsArgumentError);
    });

    test('deve guardar a nota em meias estrelas', () {
      expect(Rating(7).halfStars, 7);
    });

    test('deve ser igual a outra nota com as mesmas meias estrelas', () {
      expect(Rating(7), Rating(7));
    });
  });
}

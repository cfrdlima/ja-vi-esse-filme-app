/// A nota pessoal de um filme assistido, de meia em meia estrela (decisão
/// 018). Em meias estrelas, para as regras do Firestore compararem inteiros.
final class Rating {
  /// Recusa com [ArgumentError] o [halfStars] fora de 1 a [maxHalfStars].
  Rating(this.halfStars) {
    if (halfStars < 1 || halfStars > maxHalfStars) {
      throw ArgumentError.value(halfStars, 'halfStars', 'deve ser de 1 a 10');
    }
  }

  /// Cinco estrelas.
  static const maxHalfStars = 10;

  final int halfStars;

  double get stars => halfStars / 2;

  @override
  bool operator ==(Object other) =>
      other is Rating && other.halfStars == halfStars;

  @override
  int get hashCode => halfStars.hashCode;
}

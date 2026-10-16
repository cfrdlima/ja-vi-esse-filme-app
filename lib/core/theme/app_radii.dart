/// Raios de borda em dp (seção 4 do `MASTER.md`).
class AppRadii {
  const AppRadii({required this.sm, required this.md, required this.lg});

  static const standard = AppRadii(sm: 8, md: 12, lg: 16);

  /// Botões, chips e campos.
  final double sm;

  /// Pôsteres e cards.
  final double md;

  /// Bottom sheets e diálogos.
  final double lg;
}

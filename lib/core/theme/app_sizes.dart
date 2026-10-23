/// Tamanhos de layout em dp que não são espaçamento nem raio.
abstract final class AppSizes {
  /// Largura máxima da célula da grade de pôsteres (override `descobrir.md`).
  static const posterGridMaxExtent = 180.0;

  /// Ícone ilustrativo dos estados de tela (inicial da Buscar).
  static const stateIcon = 64.0;

  /// Largura do pôster no cabeçalho dos detalhes (override `detalhes.md`).
  static const detailsPosterWidth = 120.0;

  /// Largura da foto de cada pessoa do elenco (override `detalhes.md`).
  static const castPhotoWidth = 96.0;

  /// Largura máxima do texto corrido, para a linha não passar de ~75
  /// caracteres no tablet (override `detalhes.md`).
  static const readableWidth = 640.0;
}

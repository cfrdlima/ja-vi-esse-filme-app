/// Caminhos do app. Ficam fora do `app_router.dart` para as telas poderem
/// navegar sem importar o router, que importa as telas.
abstract final class AppRoutes {
  static const discover = '/descobrir';
  static const search = '/buscar';
  static const shelf = '/estante';
  static const profile = '/perfil';
  static const about = '$profile/sobre';

  /// Detalhes do filme [id] dentro da aba [tabPath] ([discover] ou [search]),
  /// com a barra das abas visível e o voltar devolvendo a grade.
  static String movieDetails(String tabPath, int id) => '$tabPath/filme/$id';
}

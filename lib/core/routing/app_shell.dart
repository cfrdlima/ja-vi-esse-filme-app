import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Estrutura das abas principais. A ordem dos destinos segue a ordem dos
/// branches do `StatefulShellRoute`.
class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    // Quem leva o voltar para a primeira aba é o [_BackToFirstTab]. Este
    // PopScope só avisa o Android na troca de aba, que não mexe na pilha de
    // nenhum navigator e por isso não gera aviso sozinha. Ele não navega de
    // propósito: um _BackToFirstTab esquecido vira um voltar sem efeito, que os
    // testes pegam, em vez de ser mascarado aqui.
    return PopScope(
      canPop: navigationShell.currentIndex == firstTab,
      child: Scaffold(
        body: navigationShell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: _goToTab,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.explore_outlined),
              selectedIcon: Icon(Icons.explore),
              label: 'Descobrir',
            ),
            NavigationDestination(icon: Icon(Icons.search), label: 'Buscar'),
            NavigationDestination(
              icon: Icon(Icons.video_library_outlined),
              selectedIcon: Icon(Icons.video_library),
              label: 'Estante',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }

  static const firstTab = 0;

  // Tocar a aba já selecionada volta para a raiz dela, como no Material.
  void _goToTab(int index) => navigationShell.goBranch(
    index,
    initialLocation: index == navigationShell.currentIndex,
  );
}

/// Rota das abas principais. A primeira branch vem de [firstTabBranch] e as
/// demais de [tabBranch], na ordem dos destinos da barra.
StatefulShellRoute appShellRoute(List<StatefulShellBranch> branches) =>
    StatefulShellRoute.indexedStack(
      builder: (_, _, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: branches,
    );

/// Branch da primeira aba: nela o voltar na raiz fecha o app.
StatefulShellBranch firstTabBranch({
  required String path,
  required Widget root,
  List<RouteBase> routes = const [],
}) => _branch(path: path, root: root, routes: routes);

/// Branch de uma aba que não é a primeira: o voltar na raiz leva à primeira
/// aba. A tela da feature não precisa saber dessa regra.
StatefulShellBranch tabBranch({
  required String path,
  required Widget root,
  List<RouteBase> routes = const [],
}) => _branch(
  path: path,
  root: _BackToFirstTab(child: root),
  routes: routes,
);

StatefulShellBranch _branch({
  required String path,
  required Widget root,
  required List<RouteBase> routes,
}) => StatefulShellBranch(
  routes: [GoRoute(path: path, builder: (_, _) => root, routes: routes)],
);

/// Raiz de uma aba que não é a primeira: o voltar do Android leva à primeira
/// aba em vez de fechar o app.
///
/// O PopScope precisa ficar dentro do navigator da aba. É ele que avisa o
/// Android, a cada mudança na pilha da aba, se o app trata o voltar; sem isso,
/// com predictive back, o sistema fecha o app sem chamar o Flutter.
class _BackToFirstTab extends StatelessWidget {
  const _BackToFirstTab({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          StatefulNavigationShell.of(context).goBranch(AppShell.firstTab);
        }
      },
      child: child,
    );
  }
}

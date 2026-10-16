import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Estrutura das abas principais. A ordem dos destinos segue a ordem dos
/// branches do `StatefulShellRoute`.
class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    // Fora da primeira aba, o voltar do Android leva a ela em vez de fechar o
    // app. A sub-rota de uma aba é desempilhada antes, pelo navigator dela.
    return PopScope(
      canPop: navigationShell.currentIndex == _firstTab,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) navigationShell.goBranch(_firstTab);
      },
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

  static const _firstTab = 0;

  // Tocar a aba já selecionada volta para a raiz dela, como no Material.
  void _goToTab(int index) => navigationShell.goBranch(
    index,
    initialLocation: index == navigationShell.currentIndex,
  );
}

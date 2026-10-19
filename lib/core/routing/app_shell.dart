import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Estrutura das abas principais. A ordem dos destinos segue a ordem dos
/// branches do `StatefulShellRoute`.
class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    // Quem leva o voltar para a primeira aba é o [BackToFirstTab]. Este
    // PopScope só avisa o Android na troca de aba, que não mexe na pilha de
    // nenhum navigator e por isso não gera aviso sozinha. Ele não navega de
    // propósito: um BackToFirstTab esquecido vira um voltar sem efeito, que os
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

/// Raiz de uma aba que não é a primeira: o voltar do Android leva à primeira
/// aba em vez de fechar o app.
///
/// O PopScope precisa ficar dentro do navigator da aba. É ele que avisa o
/// Android, a cada mudança na pilha da aba, se o app trata o voltar; sem isso,
/// com predictive back, o sistema fecha o app sem chamar o Flutter.
class BackToFirstTab extends StatelessWidget {
  const BackToFirstTab({required this.child, super.key});

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

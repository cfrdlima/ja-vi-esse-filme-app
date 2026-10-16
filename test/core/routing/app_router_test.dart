import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ja_vi_esse_filme/core/routing/app_router.dart';
import 'package:ja_vi_esse_filme/core/theme/app_theme.dart';

Future<GoRouter> pumpAppRouter(WidgetTester tester) async {
  final router = createAppRouter();
  addTearDown(router.dispose);
  await tester.pumpWidget(
    MaterialApp.router(theme: AppTheme.dark(), routerConfig: router),
  );
  await tester.pumpAndSettle();
  return router;
}

Future<void> tapDestination(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label)),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('shell de navegação', () {
    testWidgets('deve abrir na aba Descobrir', (tester) async {
      final router = await pumpAppRouter(tester);

      expect(router.state.matchedLocation, AppRoutes.discover);
    });

    testWidgets('deve mostrar a barra com as 4 abas em PT-BR', (tester) async {
      await pumpAppRouter(tester);

      final labels = tester
          .widgetList<NavigationDestination>(find.byType(NavigationDestination))
          .map((destination) => destination.label);
      expect(labels, ['Descobrir', 'Buscar', 'Minha estante', 'Perfil']);
    });
  });

  group('troca de aba', () {
    for (final (label, route, index) in [
      ('Descobrir', AppRoutes.discover, 0),
      ('Buscar', AppRoutes.search, 1),
      ('Minha estante', AppRoutes.shelf, 2),
      ('Perfil', AppRoutes.profile, 3),
    ]) {
      testWidgets('deve ir para $route ao tocar em $label', (tester) async {
        final router = await pumpAppRouter(tester);
        if (index == 0) router.go(AppRoutes.profile);
        await tester.pumpAndSettle();

        await tapDestination(tester, label);

        expect(router.state.matchedLocation, route);
      });
    }

    testWidgets('deve marcar o destino tocado como selecionado', (
      tester,
    ) async {
      await pumpAppRouter(tester);

      await tapDestination(tester, 'Minha estante');

      final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(bar.selectedIndex, 2);
    });

    testWidgets('deve mostrar a tela da aba tocada', (tester) async {
      await pumpAppRouter(tester);

      await tapDestination(tester, 'Perfil');

      expect(
        find.descendant(of: find.byType(AppBar), matching: find.text('Perfil')),
        findsOneWidget,
      );
    });
  });
}

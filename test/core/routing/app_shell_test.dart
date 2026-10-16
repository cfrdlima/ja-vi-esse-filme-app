import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ja_vi_esse_filme/core/routing/app_shell.dart';
import 'package:ja_vi_esse_filme/core/theme/app_theme.dart';

/// Router de teste com uma sub-rota em cada aba, que o router real ainda não
/// tem, para exercitar a pilha de navegação dentro da aba.
GoRouter createTestRouter() => GoRouter(
  initialLocation: '/a',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (_, _, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: [
        for (final tab in ['a', 'b', 'c', 'd'])
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/$tab',
                builder: (_, _) => Text('raiz $tab'),
                routes: [
                  GoRoute(
                    path: 'detalhe',
                    builder: (_, _) => Text('detalhe $tab'),
                  ),
                ],
              ),
            ],
          ),
      ],
    ),
  ],
);

Future<GoRouter> pumpShell(WidgetTester tester) async {
  final router = createTestRouter();
  addTearDown(router.dispose);
  await tester.pumpWidget(
    MaterialApp.router(theme: AppTheme.dark(), routerConfig: router),
  );
  await tester.pumpAndSettle();
  return router;
}

Future<void> tapDestination(WidgetTester tester, int index) async {
  await tester.tap(find.byType(NavigationDestination).at(index));
  await tester.pumpAndSettle();
}

void main() {
  group('aba ativa', () {
    testWidgets('deve voltar para a raiz ao tocar na aba já selecionada', (
      tester,
    ) async {
      final router = await pumpShell(tester);
      router.go('/a/detalhe');
      await tester.pumpAndSettle();

      await tapDestination(tester, 0);

      expect(router.state.matchedLocation, '/a');
    });

    testWidgets(
      'deve voltar para a sub-rota ao tocar em outra aba e retornar',
      (tester) async {
        final router = await pumpShell(tester);
        router.go('/a/detalhe');
        await tester.pumpAndSettle();

        await tapDestination(tester, 1);
        await tapDestination(tester, 0);

        expect(router.state.matchedLocation, '/a/detalhe');
      },
    );
  });
}

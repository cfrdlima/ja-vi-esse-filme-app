import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ja_vi_esse_filme/core/routing/app_shell.dart';
import 'package:ja_vi_esse_filme/core/theme/app_theme.dart';

import '../../helpers/back_navigation.dart';

/// Router de teste com uma sub-rota em cada aba, que o router real ainda não
/// tem, para exercitar a pilha de navegação dentro da aba. Usa os mesmos
/// helpers de branch do router real.
GoRouter createTestRouter() => GoRouter(
  initialLocation: '/a',
  routes: [
    appShellRoute([
      firstTabBranch(
        path: '/a',
        root: const Text('raiz a'),
        routes: detail('a'),
      ),
      for (final tab in ['b', 'c', 'd'])
        tabBranch(path: '/$tab', root: Text('raiz $tab'), routes: detail(tab)),
    ]),
  ],
);

List<RouteBase> detail(String tab) => [
  GoRoute(path: 'detalhe', builder: (_, _) => Text('detalhe $tab')),
];

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

/// Simula o botão voltar do Android; `false` significa que o sistema fecharia
/// o app.
Future<bool> pressBack(WidgetTester tester, GoRouter router) async {
  final handled = await router.routerDelegate.popRoute();
  await tester.pumpAndSettle();
  return handled;
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

  group('botão voltar', () {
    testWidgets('deve levar para a primeira aba quando está na raiz de outra', (
      tester,
    ) async {
      final router = await pumpShell(tester);
      await tapDestination(tester, 2);

      await pressBack(tester, router);

      expect(router.state.matchedLocation, '/a');
    });

    testWidgets('deve tratar o voltar na raiz de outra aba', (tester) async {
      final router = await pumpShell(tester);
      await tapDestination(tester, 2);

      final handled = await pressBack(tester, router);

      expect(handled, isTrue);
    });

    testWidgets('deve desempilhar a sub-rota antes de trocar de aba', (
      tester,
    ) async {
      final router = await pumpShell(tester);
      router.go('/b/detalhe');
      await tester.pumpAndSettle();

      await pressBack(tester, router);

      expect(router.state.matchedLocation, '/b');
    });

    testWidgets('deve deixar o sistema fechar o app na raiz da primeira aba', (
      tester,
    ) async {
      final router = await pumpShell(tester);

      final handled = await pressBack(tester, router);

      expect(handled, isFalse);
    });
  });

  group('aviso de voltar ao Android', () {
    testWidgets('deve avisar que trata o voltar ao abrir outra aba', (
      tester,
    ) async {
      final frameworkHandlesBack = recordFrameworkHandlesBack(tester);
      await pumpShell(tester);

      await tapDestination(tester, 2);

      expect(frameworkHandlesBack(), isTrue);
    });

    testWidgets(
      'deve avisar que não trata o voltar ao retornar à primeira aba',
      (tester) async {
        final frameworkHandlesBack = recordFrameworkHandlesBack(tester);
        await pumpShell(tester);
        await tapDestination(tester, 2);

        await tapDestination(tester, 0);

        expect(frameworkHandlesBack(), isFalse);
      },
    );

    testWidgets(
      'deve avisar que trata o voltar ao revisitar uma aba carregada',
      (tester) async {
        final frameworkHandlesBack = recordFrameworkHandlesBack(tester);
        await pumpShell(tester);
        await tapDestination(tester, 2);
        await tapDestination(tester, 0);

        await tapDestination(tester, 2);

        expect(frameworkHandlesBack(), isTrue);
      },
    );

    testWidgets(
      'deve avisar que trata o voltar ao desempilhar até a raiz de outra aba',
      (tester) async {
        final frameworkHandlesBack = recordFrameworkHandlesBack(tester);
        final router = await pumpShell(tester);
        router.go('/b/detalhe');
        await tester.pumpAndSettle();

        await pressBack(tester, router);

        expect(frameworkHandlesBack(), isTrue);
      },
    );
  });
}

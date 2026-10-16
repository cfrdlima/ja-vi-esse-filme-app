import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ja_vi_esse_filme/core/routing/app_router.dart';
import 'package:ja_vi_esse_filme/core/theme/app_theme.dart';

Future<GoRouter> pumpAppRouter(
  WidgetTester tester, {
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  final router = createAppRouter();
  addTearDown(router.dispose);
  await tester.pumpWidget(
    MaterialApp.router(
      theme: AppTheme.dark(),
      routerConfig: router,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: child!,
      ),
    ),
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

/// O `Scaffold` da tela de Descobrir, que só mantém o mesmo `State` se a aba
/// não for reconstruída do zero.
ScaffoldState discoverScaffoldState(WidgetTester tester) => tester.state(
  find
      .ancestor(
        of: find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Descobrir'),
        ),
        matching: find.byType(Scaffold),
      )
      .first,
);

Rect _globalRect(RenderBox box) => box.localToGlobal(Offset.zero) & box.size;

bool _contains(Rect outer, Rect inner) =>
    inner.left >= outer.left &&
    inner.top >= outer.top &&
    inner.right <= outer.right &&
    inner.bottom <= outer.bottom;

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

  group('rota desconhecida', () {
    testWidgets('deve mostrar que a página não foi encontrada', (tester) async {
      final router = await pumpAppRouter(tester);

      router.go('/nao-existe');
      await tester.pumpAndSettle();

      expect(find.text('Página não encontrada'), findsOneWidget);
    });

    testWidgets('deve voltar para Descobrir pela ação da tela', (tester) async {
      final router = await pumpAppRouter(tester);
      router.go('/nao-existe');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ir para Descobrir'));
      await tester.pumpAndSettle();

      expect(router.state.matchedLocation, AppRoutes.discover);
    });
  });

  group('pilha por aba', () {
    testWidgets('deve manter o estado da aba ao trocar e voltar', (
      tester,
    ) async {
      await pumpAppRouter(tester);
      final before = discoverScaffoldState(tester);

      await tapDestination(tester, 'Buscar');
      await tapDestination(tester, 'Descobrir');

      expect(discoverScaffoldState(tester), same(before));
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

  group('acessibilidade', () {
    testWidgets('deve ter alvos de toque de 48dp na barra', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpAppRouter(tester);

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      semantics.dispose();
    });

    testWidgets('deve ter rótulo em todo alvo de toque', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpAppRouter(tester);

      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      semantics.dispose();
    });

    testWidgets('deve ter contraste AA nos textos', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpAppRouter(tester);

      await expectLater(tester, meetsGuideline(textContrastGuideline));
      semantics.dispose();
    });

    // O `NavigationBar` limita os rótulos a 1.3x, mas o texto quebra em
    // linhas e vaza da barra sem gerar erro de overflow; por isso a checagem
    // é pela posição de cada rótulo e ícone.
    for (final width in [320.0, 411.0]) {
      testWidgets('deve caber na barra com fonte 1.5x em ${width.toInt()}dp', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await pumpAppRouter(tester, textScaler: const TextScaler.linear(1.5));

        final bar = tester.getRect(find.byType(NavigationBar));
        final contents = find.descendant(
          of: find.byType(NavigationDestination),
          matching: find.byWidgetPredicate((w) => w is Text || w is Icon),
        );
        final outside = contents
            .evaluate()
            .map((element) => _globalRect(element.renderObject! as RenderBox))
            .where((rect) => !_contains(bar, rect));
        expect(outside, isEmpty);
      });
    }
  });
}

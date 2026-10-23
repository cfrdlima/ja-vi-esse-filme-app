import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ja_vi_esse_filme/core/routing/app_router.dart';
import 'package:ja_vi_esse_filme/features/movies/presentation/screens/discover_screen.dart';
import 'package:ja_vi_esse_filme/features/movies/presentation/screens/search_screen.dart';

import '../../helpers/back_navigation.dart';
import '../../helpers/stub_movie_repository.dart';
import '../../helpers/test_app.dart';

Future<GoRouter> pumpAppRouter(
  WidgetTester tester, {
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  final router = createAppRouter(movieRepository: StubMovieRepository());
  addTearDown(router.dispose);
  await tester.pumpWidget(
    testRouterApp(
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

    testWidgets('a aba Descobrir deve carregar a primeira categoria', (
      tester,
    ) async {
      await pumpAppRouter(tester);

      // O stub responde lista vazia: ver o vazio prova que o load() rodou.
      expect(
        find.descendant(
          of: find.byType(DiscoverScreen),
          matching: find.text('Nenhum filme por aqui agora.'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('deve mostrar a barra com as 4 abas em PT-BR', (tester) async {
      await pumpAppRouter(tester);

      final labels = tester
          .widgetList<NavigationDestination>(find.byType(NavigationDestination))
          .map((destination) => destination.label);
      expect(labels, ['Descobrir', 'Buscar', 'Estante', 'Perfil']);
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

  group('aba Buscar', () {
    testWidgets('deve mostrar a tela de busca', (tester) async {
      await pumpAppRouter(tester);

      await tapDestination(tester, 'Buscar');

      expect(find.byType(SearchScreen), findsOneWidget);
    });

    testWidgets('deve guardar o termo ao trocar de aba e voltar', (
      tester,
    ) async {
      await pumpAppRouter(tester);
      await tapDestination(tester, 'Buscar');
      await tester.enterText(find.byType(TextField), 'matrix');
      await tester.pumpAndSettle();

      await tapDestination(tester, 'Descobrir');
      await tapDestination(tester, 'Buscar');

      expect(
        find.descendant(
          of: find.byType(SearchScreen),
          matching: find.text('matrix'),
        ),
        findsOneWidget,
      );
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
    for (final (label, from, to) in [
      ('Descobrir', AppRoutes.profile, AppRoutes.discover),
      ('Buscar', AppRoutes.discover, AppRoutes.search),
      ('Estante', AppRoutes.discover, AppRoutes.shelf),
      ('Perfil', AppRoutes.discover, AppRoutes.profile),
    ]) {
      testWidgets('deve ir de $from para $to ao tocar em $label', (
        tester,
      ) async {
        final router = await pumpAppRouter(tester);
        router.go(from);
        await tester.pumpAndSettle();

        await tapDestination(tester, label);

        expect(router.state.matchedLocation, to);
      });
    }

    testWidgets('deve marcar o destino tocado como selecionado', (
      tester,
    ) async {
      await pumpAppRouter(tester);

      await tapDestination(tester, 'Estante');

      final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(bar.selectedIndex, 2);
    });

    // A Estante é a única aba cujo título difere do rótulo da barra.
    for (final (label, title) in [
      ('Descobrir', 'Descobrir'),
      ('Buscar', 'Buscar'),
      ('Estante', 'Minha estante'),
      ('Perfil', 'Perfil'),
    ]) {
      testWidgets('deve mostrar $title na app bar ao tocar em $label', (
        tester,
      ) async {
        await pumpAppRouter(tester);

        await tapDestination(tester, label);

        expect(
          find.descendant(of: find.byType(AppBar), matching: find.text(title)),
          findsOneWidget,
        );
      });
    }
  });

  group('acessibilidade', () {
    // Os guidelines passam até com rótulo vazio, porque o Material já põe
    // "Guia N de 4" na semântica; por isso o nome de cada aba é conferido aqui.
    for (final label in ['Descobrir', 'Buscar', 'Estante', 'Perfil']) {
      testWidgets('deve anunciar a aba $label ao leitor de tela', (
        tester,
      ) async {
        final semantics = tester.ensureSemantics();
        await pumpAppRouter(tester);

        expect(find.bySemanticsLabel(RegExp('^$label\n')), findsOneWidget);
        semantics.dispose();
      });
    }

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

  group('botão voltar', () {
    for (final label in ['Buscar', 'Estante', 'Perfil']) {
      // Com predictive back, o Android fecha o app sem chamar o Flutter se o
      // último aviso disser que o app não trata o voltar.
      testWidgets('deve avisar o Android que trata o voltar em $label', (
        tester,
      ) async {
        final frameworkHandlesBack = recordFrameworkHandlesBack(tester);
        await pumpAppRouter(tester);

        await tapDestination(tester, label);

        expect(frameworkHandlesBack(), isTrue);
      });

      testWidgets('deve levar a Descobrir ao voltar em $label', (tester) async {
        final router = await pumpAppRouter(tester);
        await tapDestination(tester, label);

        await router.routerDelegate.popRoute();
        await tester.pumpAndSettle();

        expect(router.state.matchedLocation, AppRoutes.discover);
      });
    }
  });
}

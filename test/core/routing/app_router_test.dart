import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ja_vi_esse_filme/core/l10n/app_locale.dart';
import 'package:ja_vi_esse_filme/core/routing/app_router.dart';
import 'package:ja_vi_esse_filme/core/routing/app_routes.dart';
import 'package:ja_vi_esse_filme/core/theme/app_sizes.dart';
import 'package:ja_vi_esse_filme/features/about/presentation/screens/about_screen.dart';
import 'package:ja_vi_esse_filme/features/movies/domain/entities/movie.dart';
import 'package:ja_vi_esse_filme/features/movies/presentation/screens/discover_screen.dart';
import 'package:ja_vi_esse_filme/features/movies/presentation/screens/movie_details_screen.dart';
import 'package:ja_vi_esse_filme/features/movies/presentation/screens/search_screen.dart';
import 'package:ja_vi_esse_filme/features/movies/presentation/state/search_notifier.dart';
import 'package:ja_vi_esse_filme/features/movies/presentation/widgets/movie_poster.dart';
import 'package:ja_vi_esse_filme/l10n/app_localizations.dart';

import '../../helpers/back_navigation.dart';
import '../../helpers/stub_movie_repository.dart';
import '../../helpers/test_app.dart';

Future<GoRouter> pumpAppRouter(
  WidgetTester tester, {
  TextScaler textScaler = TextScaler.noScaling,
  List<Movie> movies = const [],
}) async {
  final router = createAppRouter(
    movieRepository: StubMovieRepository(movies: movies),
  );
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

  group('tela Sobre', () {
    final l10n = lookupAppLocalizations(AppLocale.locale);

    int selectedTab(WidgetTester tester) =>
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex;

    Future<GoRouter> openAbout(WidgetTester tester) async {
      final router = await pumpAppRouter(tester);
      router.go(AppRoutes.about);
      await tester.pumpAndSettle();
      return router;
    }

    testWidgets('deve abrir o Sobre dentro da aba Perfil', (tester) async {
      await openAbout(tester);

      expect(
        (find.byType(AboutScreen).evaluate().length, selectedTab(tester)),
        (1, 3),
      );
    });

    testWidgets('deve abrir o Sobre ao tocar na entrada do Perfil', (
      tester,
    ) async {
      await pumpAppRouter(tester);
      await tapDestination(tester, 'Perfil');

      await tester.tap(find.text(l10n.profileAboutEntry));
      await tester.pumpAndSettle();

      expect(find.byType(AboutScreen), findsOneWidget);
    });

    testWidgets('deve voltar ao Perfil ao voltar do Sobre', (tester) async {
      final router = await openAbout(tester);

      await router.routerDelegate.popRoute();
      await tester.pumpAndSettle();

      expect(router.state.matchedLocation, AppRoutes.profile);
    });

    testWidgets('deve avisar o Android que trata o voltar no Sobre', (
      tester,
    ) async {
      final frameworkHandlesBack = recordFrameworkHandlesBack(tester);

      await openAbout(tester);

      expect(frameworkHandlesBack(), isTrue);
    });

    testWidgets('deve animar a entrada do Sobre', (tester) async {
      await pumpAppRouter(tester);
      await tapDestination(tester, 'Perfil');

      await tester.tap(find.text(l10n.profileAboutEntry));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      final route = ModalRoute.of(tester.element(find.byType(AboutScreen)))!;
      expect(route.animation!.value, lessThan(1));
    });
  });

  group('detalhes do filme', () {
    final l10n = lookupAppLocalizations(AppLocale.locale);

    Future<GoRouter> openDetails(WidgetTester tester, String location) async {
      final router = await pumpAppRouter(tester);
      router.go(location);
      await tester.pumpAndSettle();
      return router;
    }

    int selectedTab(WidgetTester tester) =>
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex;

    for (final (tab, path, index) in [
      ('Descobrir', AppRoutes.discover, 0),
      ('Buscar', AppRoutes.search, 1),
    ]) {
      testWidgets('deve abrir os detalhes dentro da aba $tab', (tester) async {
        await openDetails(tester, AppRoutes.movieDetails(path, 7));

        expect(
          (
            find.byType(MovieDetailsScreen).evaluate().length,
            selectedTab(tester),
          ),
          (1, index),
        );
      });

      testWidgets('deve voltar à grade da aba $tab ao voltar', (tester) async {
        final router = await openDetails(
          tester,
          AppRoutes.movieDetails(path, 7),
        );

        await router.routerDelegate.popRoute();
        await tester.pumpAndSettle();

        expect(router.state.matchedLocation, path);
      });

      testWidgets('deve avisar o Android que trata o voltar nos detalhes '
          'da aba $tab', (tester) async {
        final frameworkHandlesBack = recordFrameworkHandlesBack(tester);

        await openDetails(tester, AppRoutes.movieDetails(path, 7));

        expect(frameworkHandlesBack(), isTrue);
      });
    }

    testWidgets('deve pedir os detalhes do id da rota', (tester) async {
      await openDetails(tester, AppRoutes.movieDetails(AppRoutes.search, 42));

      expect(find.text('Filme 42'), findsWidgets);
    });

    for (final id in [
      'abc',
      '0',
      '-1',
      '7.5',
      '99999999999999999999',
      '0x1F',
      '+7',
      ' 7',
    ]) {
      testWidgets('deve mostrar não encontrado com o id $id', (tester) async {
        await openDetails(tester, '${AppRoutes.discover}/filme/$id');

        expect(find.text(l10n.movieNotFound), findsOneWidget);
      });
    }

    // O go_router reaproveita a página quando só o parâmetro muda: o
    // provider precisa trocar junto com o id.
    testWidgets('deve trocar de filme quando só o id da rota muda', (
      tester,
    ) async {
      final router = await openDetails(
        tester,
        AppRoutes.movieDetails(AppRoutes.discover, 1),
      );

      router.go(AppRoutes.movieDetails(AppRoutes.discover, 2));
      await tester.pumpAndSettle();

      expect(find.text('Filme 2'), findsWidgets);
    });

    testWidgets('a seta da barra deve voltar à grade', (tester) async {
      final router = await openDetails(
        tester,
        AppRoutes.movieDetails(AppRoutes.search, 7),
      );

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(router.state.matchedLocation, AppRoutes.search);
    });
  });

  group('pôster da grade', () {
    final movies = [
      for (var i = 1; i <= 40; i++) Movie(id: i, title: 'Filme $i'),
    ];

    testWidgets('deve abrir os detalhes do filme tocado na Descobrir', (
      tester,
    ) async {
      final router = await pumpAppRouter(tester, movies: movies);

      await tester.tap(find.byType(MoviePoster).at(1));
      await tester.pumpAndSettle();

      expect(
        router.state.matchedLocation,
        AppRoutes.movieDetails(AppRoutes.discover, 2),
      );
    });

    testWidgets('deve abrir os detalhes do filme tocado na Buscar', (
      tester,
    ) async {
      final router = await pumpAppRouter(tester, movies: movies);
      await tapDestination(tester, 'Buscar');
      await tester.enterText(find.byType(TextField), 'filme');
      await tester.pump(SearchNotifier.debounce);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(MoviePoster).first);
      await tester.pumpAndSettle();

      expect(
        router.state.matchedLocation,
        AppRoutes.movieDetails(AppRoutes.search, 1),
      );
    });

    Movie? previewOf(WidgetTester tester) => tester
        .widget<MovieDetailsScreen>(find.byType(MovieDetailsScreen))
        .preview;

    testWidgets('deve levar o filme tocado na Descobrir aos detalhes', (
      tester,
    ) async {
      await pumpAppRouter(tester, movies: movies);

      await tester.tap(find.byType(MoviePoster).at(1));
      await tester.pumpAndSettle();

      expect(previewOf(tester), movies[1]);
    });

    testWidgets('deve levar o filme tocado na Buscar aos detalhes', (
      tester,
    ) async {
      await pumpAppRouter(tester, movies: movies);
      await tapDestination(tester, 'Buscar');
      await tester.enterText(find.byType(TextField), 'filme');
      await tester.pump(SearchNotifier.debounce);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(MoviePoster).first);
      await tester.pumpAndSettle();

      expect(previewOf(tester), movies[0]);
    });

    testWidgets('deve vir sem filme da grade quando a URL abre os detalhes', (
      tester,
    ) async {
      final router = await pumpAppRouter(tester, movies: movies);

      router.go(AppRoutes.movieDetails(AppRoutes.discover, 2));
      await tester.pumpAndSettle();

      expect(previewOf(tester), isNull);
    });

    testWidgets('deve animar a entrada dos detalhes', (tester) async {
      await pumpAppRouter(tester, movies: movies);

      await tester.tap(find.byType(MoviePoster).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      final route = ModalRoute.of(
        tester.element(find.byType(MovieDetailsScreen)),
      )!;
      expect(route.animation!.value, lessThan(1));
    });

    testWidgets('deve voar com o pôster da grade até os detalhes', (
      tester,
    ) async {
      await pumpAppRouter(tester, movies: movies);
      final grid = tester.getSize(find.byType(MoviePoster).first).width;

      await tester.tap(find.byType(MoviePoster).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // A grade continua visível embaixo durante a transição: só o pôster do
      // filme tocado interessa, e o da grade fica escondido pelo Hero.
      expect(
        tester
            .getSize(
              find.byWidgetPredicate(
                (widget) => widget is MoviePoster && widget.movie.id == 1,
              ),
            )
            .width,
        // A célula pode ser mais larga ou mais estreita que o cabeçalho,
        // conforme a tela do teste: o voo fica entre os dois.
        inExclusiveRange(
          math.min(grid, AppSizes.detailsPosterWidth),
          math.max(grid, AppSizes.detailsPosterWidth),
        ),
      );
    });

    testWidgets('deve manter a proporção do pôster quando o teclado fecha no '
        'meio do voo', (tester) async {
      await pumpAppRouter(tester, movies: movies);
      await tapDestination(tester, 'Buscar');
      await tester.enterText(find.byType(TextField), 'filme');
      await tester.pump(SearchNotifier.debounce);
      await tester.pumpAndSettle();
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(MoviePoster).first);
      await tester.pump();
      tester.view.viewInsets = FakeViewPadding.zero;
      await tester.pump(const Duration(milliseconds: 100));

      final size = tester.getSize(
        find.byWidgetPredicate(
          (widget) => widget is MoviePoster && widget.movie.id == 1,
        ),
      );
      expect(size.width / size.height, closeTo(2 / 3, 0.01));
    });

    testWidgets('deve ignorar um filme de outro id no extra', (tester) async {
      final router = await pumpAppRouter(tester, movies: movies);

      router.go(
        AppRoutes.movieDetails(AppRoutes.discover, 2),
        extra: const Movie(id: 99, title: 'Outro'),
      );
      await tester.pumpAndSettle();

      expect(previewOf(tester), isNull);
    });

    testWidgets('deve voltar à grade na mesma rolagem', (tester) async {
      final router = await pumpAppRouter(tester, movies: movies);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
      await tester.pumpAndSettle();
      final offset = tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .pixels;

      await tester.tap(find.byType(MoviePoster).first);
      await tester.pumpAndSettle();
      await router.routerDelegate.popRoute();
      await tester.pumpAndSettle();

      expect(
        tester
            .state<ScrollableState>(find.byType(Scrollable).first)
            .position
            .pixels,
        offset,
      );
    });
  });
}

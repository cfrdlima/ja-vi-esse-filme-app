import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/core/error/failures.dart';
import 'package:ja_vi_esse_filme/core/l10n/app_locale.dart';
import 'package:ja_vi_esse_filme/features/movies/domain/entities/search_query.dart';
import 'package:ja_vi_esse_filme/features/movies/presentation/screens/search_screen.dart';
import 'package:ja_vi_esse_filme/features/movies/presentation/state/search_notifier.dart';
import 'package:ja_vi_esse_filme/features/movies/presentation/widgets/movie_poster.dart';
import 'package:ja_vi_esse_filme/features/movies/presentation/widgets/poster_skeleton.dart';
import 'package:ja_vi_esse_filme/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/fake_movie_repository.dart';
import '../../../../helpers/test_app.dart';

void main() {
  final l10n = lookupAppLocalizations(AppLocale.locale);
  late FakeMovieRepository repository;

  setUp(() => repository = FakeMovieRepository());

  // O provider cria e descarta o notifier com a árvore, como no app: o
  // debounce pendente é cancelado antes da checagem de timers do teste.
  Widget screen() => testApp(
    home: ChangeNotifierProvider(
      create: (_) => SearchNotifier(repository: repository),
      child: const SearchScreen(),
    ),
  );

  Future<void> pumpScreen(WidgetTester tester) => tester.pumpWidget(screen());

  /// Digita e espera o debounce: a busca abre carregando.
  Future<void> typeAndWait(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField), text);
    await tester.pump(SearchNotifier.debounce);
  }

  Future<void> answer(WidgetTester tester, {int count = 2}) async {
    repository.complete(moviePage(page: 1, count: count, totalPages: 1));
    await tester.pump();
  }

  testWidgets('deve mostrar o título da tela', (tester) async {
    await pumpScreen(tester);

    expect(find.text(l10n.searchTitle), findsOneWidget);
  });

  group('campo', () {
    testWidgets('deve ter o rótulo visível', (tester) async {
      await pumpScreen(tester);

      expect(
        find.widgetWithText(TextField, l10n.searchFieldLabel),
        findsOneWidget,
      );
    });

    testWidgets('deve limitar o termo ao máximo do domínio', (tester) async {
      await pumpScreen(tester);

      await tester.enterText(
        find.byType(TextField),
        'a' * (SearchQuery.maxLength + 20),
      );

      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        hasLength(SearchQuery.maxLength),
      );
    });

    testWidgets('deve contar o limite em code points, como o domínio', (
      tester,
    ) async {
      await pumpScreen(tester);

      // "e" + acento combinante: um caractere visível, dois code points.
      await tester.enterText(find.byType(TextField), 'e\u0301' * 60);

      expect(
        tester
            .widget<TextField>(find.byType(TextField))
            .controller!
            .text
            .runes
            .length,
        SearchQuery.maxLength,
      );
    });

    testWidgets('deve pedir ao teclado que não aprenda o termo', (
      tester,
    ) async {
      await pumpScreen(tester);

      expect(
        tester
            .widget<TextField>(find.byType(TextField))
            .enableIMEPersonalizedLearning,
        isFalse,
      );
    });

    testWidgets('deve usar a ação de buscar do teclado', (tester) async {
      await pumpScreen(tester);

      expect(
        tester.widget<TextField>(find.byType(TextField)).textInputAction,
        TextInputAction.search,
      );
    });

    testWidgets('deve buscar na hora pela ação do teclado', (tester) async {
      await pumpScreen(tester);
      await tester.enterText(find.byType(TextField), 'matrix');

      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();

      expect(repository.requestedQueries, [SearchQuery('matrix')]);
    });

    testWidgets('não deve mostrar o botão de limpar sem texto', (tester) async {
      await pumpScreen(tester);

      expect(find.byTooltip(l10n.searchClear), findsNothing);
    });

    testWidgets('deve mostrar o botão de limpar com texto', (tester) async {
      await pumpScreen(tester);

      await tester.enterText(find.byType(TextField), 'm');
      await tester.pump();

      expect(find.byTooltip(l10n.searchClear), findsOneWidget);
    });

    testWidgets('o botão de limpar deve ter alvo de pelo menos 48dp', (
      tester,
    ) async {
      await pumpScreen(tester);
      await tester.enterText(find.byType(TextField), 'm');
      await tester.pump();

      final size = tester.getSize(
        find.ancestor(
          of: find.byTooltip(l10n.searchClear),
          matching: find.byType(IconButton),
        ),
      );

      expect(size.shortestSide, greaterThanOrEqualTo(48));
    });

    testWidgets('limpar deve apagar o termo', (tester) async {
      await pumpScreen(tester);
      await typeAndWait(tester, 'matrix');

      await tester.tap(find.byTooltip(l10n.searchClear));
      await tester.pump();

      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
    });

    testWidgets('limpar deve voltar ao estado inicial', (tester) async {
      await pumpScreen(tester);
      await typeAndWait(tester, 'matrix');
      await answer(tester);

      await tester.tap(find.byTooltip(l10n.searchClear));
      await tester.pump();

      expect(find.text(l10n.searchIdle), findsOneWidget);
    });

    testWidgets('limpar deve pôr o foco no campo para o termo novo', (
      tester,
    ) async {
      await pumpScreen(tester);
      await tester.enterText(find.byType(TextField), 'matrix');
      // Como depois de arrastar a grade, que fecha o teclado.
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();

      await tester.tap(find.byTooltip(l10n.searchClear));
      await tester.pump();

      expect(
        tester.widget<TextField>(find.byType(TextField)).focusNode!.hasFocus,
        isTrue,
      );
    });
  });

  group('inicial', () {
    testWidgets('deve convidar a buscar antes de digitar', (tester) async {
      await pumpScreen(tester);

      expect(find.text(l10n.searchIdle), findsOneWidget);
    });

    testWidgets('deve continuar no inicial com um termo curto', (tester) async {
      await pumpScreen(tester);

      await typeAndWait(tester, 'm');

      expect(find.text(l10n.searchIdle), findsOneWidget);
    });

    testWidgets('não deve pedir nada antes do fim da espera', (tester) async {
      await pumpScreen(tester);

      await tester.enterText(find.byType(TextField), 'matrix');
      await tester.pump(const Duration(milliseconds: 399));

      expect(repository.requestedQueries, isEmpty);
    });
  });

  group('carregando', () {
    testWidgets('deve mostrar a grade de skeleton', (tester) async {
      await pumpScreen(tester);

      await typeAndWait(tester, 'matrix');

      expect(find.byType(PosterSkeleton), findsWidgets);
    });

    testWidgets('deve manter o campo editável', (tester) async {
      await pumpScreen(tester);

      await typeAndWait(tester, 'matrix');

      expect(
        tester.widget<TextField>(find.byType(TextField)).enabled,
        isNot(isFalse),
      );
    });
  });

  group('vazio', () {
    testWidgets('deve dizer que nada foi encontrado para o termo', (
      tester,
    ) async {
      await pumpScreen(tester);
      await typeAndWait(tester, '  xyzxyz ');

      await answer(tester, count: 0);

      expect(find.text(l10n.searchEmpty('xyzxyz')), findsOneWidget);
    });

    testWidgets('deve anunciar o vazio ao leitor de tela', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpScreen(tester);
      await typeAndWait(tester, 'xyzxyz');

      await answer(tester, count: 0);

      expect(
        tester.getSemantics(find.text(l10n.searchEmpty('xyzxyz'))),
        isSemantics(isLiveRegion: true),
      );
      semantics.dispose();
    });

    testWidgets('não deve oferecer tentar de novo', (tester) async {
      await pumpScreen(tester);
      await typeAndWait(tester, 'xyzxyz');

      await answer(tester, count: 0);

      expect(find.text(l10n.retry), findsNothing);
    });
  });

  group('longo demais', () {
    // O campo já corta no máximo; o aviso é a defesa do estado, testada
    // mandando o termo direto ao notifier.
    Future<void> sendTooLong(WidgetTester tester) async {
      tester
          .element(find.byType(SearchScreen))
          .read<SearchNotifier>()
          .onQueryChanged('a' * (SearchQuery.maxLength + 1));
      await tester.pump();
    }

    testWidgets('deve avisar o máximo de caracteres', (tester) async {
      await pumpScreen(tester);

      await sendTooLong(tester);

      expect(
        find.text(l10n.searchTooLong(SearchQuery.maxLength)),
        findsOneWidget,
      );
    });

    testWidgets('deve anunciar o aviso ao leitor de tela', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpScreen(tester);

      await sendTooLong(tester);

      expect(
        tester.getSemantics(
          find.text(l10n.searchTooLong(SearchQuery.maxLength)),
        ),
        isSemantics(isLiveRegion: true),
      );
      semantics.dispose();
    });
  });

  group('erro', () {
    testWidgets('deve anunciar o erro ao leitor de tela', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpScreen(tester);
      await typeAndWait(tester, 'matrix');

      repository.fail(const NetworkFailure());
      await tester.pump();

      expect(
        tester.getSemantics(find.text(l10n.failureNetwork)),
        isSemantics(isLiveRegion: true),
      );
      semantics.dispose();
    });

    testWidgets('deve mostrar a mensagem e tentar de novo', (tester) async {
      await pumpScreen(tester);
      await typeAndWait(tester, 'matrix');

      repository.fail(const NetworkFailure());
      await tester.pump();

      expect(
        (
          find.text(l10n.failureNetwork).evaluate().length,
          find.text(l10n.retry).evaluate().length,
        ),
        (1, 1),
      );
    });

    testWidgets('tentar de novo deve repetir o mesmo termo', (tester) async {
      await pumpScreen(tester);
      await typeAndWait(tester, 'matrix');
      repository.fail(const NetworkFailure());
      await tester.pump();

      await tester.tap(find.text(l10n.retry));
      await tester.pump();

      expect(repository.requestedQueries, [
        SearchQuery('matrix'),
        SearchQuery('matrix'),
      ]);
    });
  });

  group('sucesso', () {
    testWidgets('deve mostrar os pôsteres encontrados', (tester) async {
      await pumpScreen(tester);
      await typeAndWait(tester, 'matrix');

      await answer(tester, count: 3);

      expect(find.byType(MoviePoster), findsNWidgets(3));
    });

    testWidgets('arrastar a grade deve fechar o teclado', (tester) async {
      await pumpScreen(tester);
      await typeAndWait(tester, 'matrix');
      await answer(tester, count: 3);

      expect(
        tester
            .widget<CustomScrollView>(find.byType(CustomScrollView))
            .keyboardDismissBehavior,
        ScrollViewKeyboardDismissBehavior.onDrag,
      );
    });

    testWidgets('um termo novo deve trocar os resultados', (tester) async {
      await pumpScreen(tester);
      await typeAndWait(tester, 'matrix');
      await answer(tester, count: 3);

      await typeAndWait(tester, 'matriz');

      expect(find.byType(PosterSkeleton), findsWidgets);
    });
  });

  group('fonte grande', () {
    Future<void> pumpLarge(WidgetTester tester) async {
      tester.view
        ..physicalSize = const Size(320, 640)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 640),
            textScaler: TextScaler.linear(1.5),
          ),
          child: screen(),
        ),
      );
    }

    testWidgets('não deve vazar no estado inicial', (tester) async {
      await pumpLarge(tester);

      expect(tester.takeException(), isNull);
    });

    testWidgets('não deve vazar no vazio com um termo longo', (tester) async {
      await pumpLarge(tester);
      await typeAndWait(tester, 'um título de filme bem comprido ' * 3);
      await answer(tester, count: 0);

      expect(tester.takeException(), isNull);
    });

    testWidgets('não deve vazar no erro', (tester) async {
      await pumpLarge(tester);
      await typeAndWait(tester, 'matrix');
      repository.fail(const RateLimitFailure());
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });
}

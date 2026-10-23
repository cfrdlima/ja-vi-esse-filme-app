import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/core/error/failures.dart';
import 'package:ja_vi_esse_filme/core/l10n/app_locale.dart';
import 'package:ja_vi_esse_filme/features/movies/domain/entities/movie_category.dart';
import 'package:ja_vi_esse_filme/features/movies/presentation/screens/discover_screen.dart';
import 'package:ja_vi_esse_filme/features/movies/presentation/state/discover_notifier.dart';
import 'package:ja_vi_esse_filme/features/movies/presentation/state/paged_movies_notifier.dart';
import 'package:ja_vi_esse_filme/features/movies/presentation/widgets/movie_poster.dart';
import 'package:ja_vi_esse_filme/features/movies/presentation/widgets/poster_skeleton.dart';
import 'package:ja_vi_esse_filme/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/fake_movie_repository.dart';
import '../../../../helpers/test_app.dart';

void main() {
  final l10n = lookupAppLocalizations(AppLocale.locale);
  late FakeMovieRepository repository;
  late DiscoverNotifier discover;
  // A lista de populares, que abre carregando.
  late PagedMoviesNotifier notifier;
  final created = <DiscoverNotifier>[];

  setUp(() => repository = FakeMovieRepository());

  tearDown(() {
    for (final notifier in created) {
      notifier.dispose();
    }
    created.clear();
  });

  // Criado dentro do testWidgets, e não no setUp: o primeiro pedido nasce na
  // zona do teste, e o pump entrega a resposta do fake.
  DiscoverNotifier createDiscover() {
    discover = DiscoverNotifier(repository: repository);
    notifier = discover.current;
    created.add(discover);
    return discover;
  }

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      testApp(
        home: ChangeNotifierProvider.value(
          value: createDiscover(),
          child: const DiscoverScreen(),
        ),
      ),
    );
  }

  Future<void> loadFirstPage(
    WidgetTester tester, {
    int count = 2,
    int totalPages = 3,
  }) async {
    repository.complete(
      moviePage(page: 1, count: count, totalPages: totalPages),
    );
    await tester.pump();
  }

  testWidgets('deve mostrar o título da tela', (tester) async {
    await pumpScreen(tester);

    expect(find.text(l10n.discoverTitle), findsOneWidget);
  });

  group('seletor de categoria', () {
    bool isSelected(WidgetTester tester, String label) => tester
        .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, label))
        .selected;

    testWidgets('deve oferecer as três categorias', (tester) async {
      await pumpScreen(tester);

      final labels = tester
          .widgetList<ChoiceChip>(find.byType(ChoiceChip))
          .map((chip) => (chip.label as Text).data);
      expect(labels, [
        l10n.categoryPopular,
        l10n.categoryNowPlaying,
        l10n.categoryTopRated,
      ]);
    });

    testWidgets('deve marcar populares ao abrir', (tester) async {
      await pumpScreen(tester);

      expect(isSelected(tester, l10n.categoryPopular), isTrue);
    });

    testWidgets('deve carregar a categoria tocada', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.text(l10n.categoryNowPlaying));
      await tester.pump();

      expect(repository.requestedCategories.last, MovieCategory.nowPlaying);
    });

    testWidgets('deve marcar a categoria tocada', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.text(l10n.categoryTopRated));
      await tester.pump();

      expect(isSelected(tester, l10n.categoryTopRated), isTrue);
    });

    testWidgets('deve mostrar os filmes da categoria tocada', (tester) async {
      await pumpScreen(tester);
      await loadFirstPage(tester, totalPages: 1);

      await tester.tap(find.text(l10n.categoryTopRated));
      await tester.pump();
      repository.complete(moviePage(page: 1, count: 3));
      await tester.pump();

      expect(find.byType(MoviePoster), findsNWidgets(3));
    });

    testWidgets('deve voltar aos filmes já carregados da categoria', (
      tester,
    ) async {
      await pumpScreen(tester);
      await loadFirstPage(tester);
      await tester.tap(find.text(l10n.categoryTopRated));
      await tester.pump();

      await tester.tap(find.text(l10n.categoryPopular));
      await tester.pump();

      expect(find.byType(MoviePoster), findsNWidgets(2));
    });

    testWidgets('deve voltar à rolagem em que a categoria estava', (
      tester,
    ) async {
      await pumpScreen(tester);
      await loadFirstPage(tester, count: 40, totalPages: 1);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
      await tester.pump();
      await tester.tap(find.text(l10n.categoryTopRated));
      await tester.pump();

      await tester.tap(find.text(l10n.categoryPopular));
      await tester.pump();

      final scrollable = tester.state<ScrollableState>(
        find.descendant(
          of: find.byType(CustomScrollView),
          matching: find.byType(Scrollable),
        ),
      );
      expect(scrollable.position.pixels, greaterThan(0));
    });

    // Mede com a Inter de verdade: a fonte padrão dos testes (Ahem) desenha
    // cada letra como um quadrado e alargaria os chips.
    testWidgets('deve caber numa linha num celular de 412dp', (tester) async {
      await tester.runAsync(
        () =>
            (FontLoader('Inter')..addFont(
                  Future.value(
                    ByteData.sublistView(
                      File('assets/fonts/Inter-Variable.ttf').readAsBytesSync(),
                    ),
                  ),
                ))
                .load(),
      );
      tester.view
        ..physicalSize = const Size(412, 915)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pumpScreen(tester);

      final rows = tester
          .widgetList<ChoiceChip>(find.byType(ChoiceChip))
          .map((chip) => tester.getTopLeft(find.byWidget(chip)).dy)
          .toSet();
      expect(rows, hasLength(1));
    });

    testWidgets('não deve vazar com fonte 1.5x numa tela estreita', (
      tester,
    ) async {
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
          child: testApp(
            home: ChangeNotifierProvider.value(
              value: createDiscover(),
              child: const DiscoverScreen(),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('carregando', () {
    testWidgets('deve mostrar o skeleton da grade, sem spinner', (
      tester,
    ) async {
      await pumpScreen(tester);

      expect(find.byType(PosterSkeleton), findsWidgets);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('deve parar o pulso com o reduzir movimento', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: testApp(
            home: ChangeNotifierProvider.value(
              value: createDiscover(),
              child: const DiscoverScreen(),
            ),
          ),
        ),
      );

      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('deve anunciar o carregamento ao leitor de tela', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpScreen(tester);

      expect(find.bySemanticsLabel(l10n.discoverLoading), findsOneWidget);
      semantics.dispose();
    });
  });

  // O Android pode fazer o primeiro layout com a janela ainda sem largura;
  // com o padding, a grade ficaria com largura negativa.
  group('largura mínima', () {
    Future<void> pumpNarrow(WidgetTester tester) => tester.pumpWidget(
      testApp(
        home: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 20,
            child: ChangeNotifierProvider.value(
              value: createDiscover(),
              child: const DiscoverScreen(),
            ),
          ),
        ),
      ),
    );

    testWidgets('não deve quebrar o skeleton sem largura', (tester) async {
      await pumpNarrow(tester);

      expect(tester.takeException(), isNull);
    });

    testWidgets('não deve quebrar a grade sem largura', (tester) async {
      await pumpNarrow(tester);
      await loadFirstPage(tester);

      expect(tester.takeException(), isNull);
    });
  });

  group('vazio', () {
    testWidgets('deve explicar que não há filmes', (tester) async {
      await pumpScreen(tester);
      await loadFirstPage(tester, count: 0, totalPages: 0);

      expect(find.text(l10n.discoverEmpty), findsOneWidget);
    });

    testWidgets('deve carregar de novo ao tocar em tentar de novo', (
      tester,
    ) async {
      await pumpScreen(tester);
      await loadFirstPage(tester, count: 0, totalPages: 0);

      await tester.tap(find.text(l10n.retry));
      await tester.pump();

      expect(repository.requestedPages, [1, 1]);
    });
  });

  group('erro', () {
    Future<void> failFirstPage(WidgetTester tester, Failure failure) async {
      repository.fail(failure);
      await tester.pump();
    }

    testWidgets('deve mostrar a mensagem da falha', (tester) async {
      await pumpScreen(tester);
      await failFirstPage(tester, const NetworkFailure());

      expect(find.text(l10n.failureNetwork), findsOneWidget);
    });

    testWidgets('deve carregar de novo ao tocar em tentar de novo', (
      tester,
    ) async {
      await pumpScreen(tester);
      await failFirstPage(tester, const NetworkFailure());

      await tester.tap(find.text(l10n.retry));
      await tester.pump();

      expect(repository.requestedPages, [1, 1]);
    });

    testWidgets('deve esperar o retryAfter do 429 antes de tentar de novo', (
      tester,
    ) async {
      await pumpScreen(tester);
      await failFirstPage(
        tester,
        const RateLimitFailure(retryAfter: Duration(seconds: 5)),
      );

      expect(find.text(l10n.retryIn(5)), findsOneWidget);
    });

    testWidgets('deve liberar o tentar de novo quando a espera acaba', (
      tester,
    ) async {
      await pumpScreen(tester);
      await failFirstPage(
        tester,
        const RateLimitFailure(retryAfter: Duration(seconds: 5)),
      );

      await tester.pump(const Duration(seconds: 5));

      expect(find.text(l10n.retry), findsOneWidget);
    });

    testWidgets('não deve vazar com fonte 1.5x', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: testApp(
            home: ChangeNotifierProvider.value(
              value: createDiscover(),
              child: const DiscoverScreen(),
            ),
          ),
        ),
      );
      await failFirstPage(tester, const RateLimitFailure());

      expect(tester.takeException(), isNull);
      expect(find.text(l10n.failureRateLimit), findsOneWidget);
    });
  });

  group('sucesso', () {
    testWidgets('deve mostrar um pôster por filme', (tester) async {
      await pumpScreen(tester);
      await loadFirstPage(tester);

      expect(find.byType(MoviePoster), findsNWidgets(2));
    });

    testWidgets('deve mostrar o progresso da próxima página no rodapé', (
      tester,
    ) async {
      await pumpScreen(tester);
      await loadFirstPage(tester);

      unawaited(notifier.loadMore());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('deve oferecer tentar de novo quando a próxima página falha', (
      tester,
    ) async {
      await pumpScreen(tester);
      await loadFirstPage(tester);
      final failed = notifier.loadMore();
      repository.fail(const NetworkFailure());
      await failed;
      await tester.pump();

      await tester.tap(find.text(l10n.retry));
      await tester.pump();

      expect(find.text(l10n.discoverLoadMoreFailed), findsNothing);
      expect(repository.requestedPages, [1, 2, 2]);
    });

    testWidgets('deve esperar o retryAfter do 429 no rodapé', (tester) async {
      await pumpScreen(tester);
      await loadFirstPage(tester);
      final failed = notifier.loadMore();
      repository.fail(const RateLimitFailure(retryAfter: Duration(seconds: 4)));
      await failed;
      await tester.pump();

      expect(find.text(l10n.retryIn(4)), findsOneWidget);
    });

    testWidgets('deve pedir a próxima página ao rolar perto do fim', (
      tester,
    ) async {
      await pumpScreen(tester);
      await loadFirstPage(tester, count: 40);

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -3000));
      await tester.pump();

      expect(repository.requestedPages, [1, 2]);
    });

    testWidgets(
      'deve pedir a próxima página quando a primeira não enche a tela',
      (tester) async {
        await pumpScreen(tester);
        await loadFirstPage(tester, count: 2);
        await tester.pump();

        expect(repository.requestedPages, [1, 2]);
      },
    );

    testWidgets('não deve vazar o rodapé de falha com fonte 1.5x', (
      tester,
    ) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: testApp(
            home: ChangeNotifierProvider.value(
              value: createDiscover(),
              child: const DiscoverScreen(),
            ),
          ),
        ),
      );
      await loadFirstPage(tester);
      await tester.pump();
      repository.fail(const NetworkFailure());
      await tester.pump();
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text(l10n.discoverLoadMoreFailed), findsOneWidget);
    });

    testWidgets('não deve pedir a próxima página sem rolar', (tester) async {
      await pumpScreen(tester);
      await loadFirstPage(tester, count: 40);

      expect(repository.requestedPages, [1]);
    });
  });
}

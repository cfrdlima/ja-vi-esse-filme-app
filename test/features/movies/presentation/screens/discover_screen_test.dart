import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/core/error/failures.dart';
import 'package:ja_vi_esse_filme/core/l10n/app_locale.dart';
import 'package:ja_vi_esse_filme/features/movies/presentation/screens/discover_screen.dart';
import 'package:ja_vi_esse_filme/features/movies/presentation/state/popular_movies_notifier.dart';
import 'package:ja_vi_esse_filme/features/movies/presentation/widgets/movie_poster.dart';
import 'package:ja_vi_esse_filme/features/movies/presentation/widgets/poster_skeleton.dart';
import 'package:ja_vi_esse_filme/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/fake_movie_repository.dart';
import '../../../../helpers/test_app.dart';

void main() {
  final l10n = lookupAppLocalizations(AppLocale.locale);
  late FakeMovieRepository repository;
  late PopularMoviesNotifier notifier;

  setUp(() {
    repository = FakeMovieRepository();
    notifier = PopularMoviesNotifier(repository: repository);
  });

  tearDown(() => notifier.dispose());

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      testApp(
        home: ChangeNotifierProvider.value(
          value: notifier,
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
    final future = notifier.load();
    repository.complete(
      moviePage(page: 1, count: count, totalPages: totalPages),
    );
    await future;
    await tester.pump();
  }

  testWidgets('deve mostrar o título da tela', (tester) async {
    await pumpScreen(tester);

    expect(find.text(l10n.discoverTitle), findsOneWidget);
  });

  group('carregando', () {
    testWidgets('deve mostrar o skeleton da grade, sem spinner', (
      tester,
    ) async {
      unawaited(notifier.load());
      await pumpScreen(tester);

      expect(find.byType(PosterSkeleton), findsWidgets);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('deve parar o pulso com o reduzir movimento', (tester) async {
      unawaited(notifier.load());
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: testApp(
            home: ChangeNotifierProvider.value(
              value: notifier,
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
      unawaited(notifier.load());
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
              value: notifier,
              child: const DiscoverScreen(),
            ),
          ),
        ),
      ),
    );

    testWidgets('não deve quebrar o skeleton sem largura', (tester) async {
      unawaited(notifier.load());
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
      final future = notifier.load();
      repository.fail(failure);
      await future;
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

    testWidgets('não deve vazar com fonte 1.5x', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: testApp(
            home: ChangeNotifierProvider.value(
              value: notifier,
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
              value: notifier,
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

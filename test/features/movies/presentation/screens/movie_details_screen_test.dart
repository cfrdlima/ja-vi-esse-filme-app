import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/core/error/failures.dart';
import 'package:ja_vi_esse_filme/core/l10n/app_locale.dart';
import 'package:ja_vi_esse_filme/core/theme/app_sizes.dart';
import 'package:ja_vi_esse_filme/core/widgets/retry_button.dart';
import 'package:ja_vi_esse_filme/features/movies/domain/entities/cast_member.dart';
import 'package:ja_vi_esse_filme/features/movies/domain/entities/movie.dart';
import 'package:ja_vi_esse_filme/features/movies/domain/entities/movie_details.dart';
import 'package:ja_vi_esse_filme/features/movies/presentation/screens/movie_details_screen.dart';
import 'package:ja_vi_esse_filme/features/movies/presentation/state/movie_details_notifier.dart';
import 'package:ja_vi_esse_filme/features/movies/presentation/widgets/cast_member_card.dart';
import 'package:ja_vi_esse_filme/features/movies/presentation/widgets/movie_details_content.dart';
import 'package:ja_vi_esse_filme/features/movies/presentation/widgets/movie_poster.dart';
import 'package:ja_vi_esse_filme/features/movies/presentation/widgets/poster_hero.dart';
import 'package:ja_vi_esse_filme/features/movies/presentation/widgets/poster_skeleton.dart';
import 'package:ja_vi_esse_filme/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/fake_movie_repository.dart';
import '../../../../helpers/test_app.dart';

void main() {
  final l10n = lookupAppLocalizations(AppLocale.locale);
  late FakeMovieRepository repository;

  setUp(() => repository = FakeMovieRepository());

  final complete = MovieDetails(
    id: 7,
    title: 'Duna: Parte Dois',
    overview: 'Paul Atreides se une a Chani e aos Fremen.',
    posterPath: '/poster-duna.jpg',
    releaseDate: DateTime(2024, 2, 27),
    runtime: const Duration(minutes: 166),
    voteAverage: 8.14,
    genres: ['Ficção científica', 'Aventura'],
    cast: [
      for (var i = 0; i < 15; i++)
        CastMember(
          id: i,
          name: 'Pessoa $i',
          character: 'Personagem $i',
          profilePath: i.isEven ? '/perfil-$i.jpg' : null,
        ),
    ],
  );

  final bare = MovieDetails(id: 7, title: 'Filme Sem Nada', overview: '');

  Widget screen({MediaQueryData? mediaQuery, Movie? preview}) {
    final app = testApp(
      home: ChangeNotifierProvider(
        create: (_) {
          final notifier = MovieDetailsNotifier(
            repository: repository,
            movieId: 7,
          );
          unawaited(notifier.load());
          return notifier;
        },
        child: MovieDetailsScreen(preview: preview),
      ),
    );
    return mediaQuery == null ? app : MediaQuery(data: mediaQuery, child: app);
  }

  const preview = Movie(
    id: 7,
    title: 'Duna: Parte Dois',
    posterPath: '/poster-duna.jpg',
  );

  PosterHero heroOfPoster(WidgetTester tester) => tester.widget<PosterHero>(
    find.ancestor(
      of: find.byType(MoviePoster),
      matching: find.byType(PosterHero),
    ),
  );

  Future<void> pumpWith(WidgetTester tester, MovieDetails details) async {
    await tester.pumpWidget(screen());
    repository.completeDetails(details);
    await tester.pump();
  }

  // O `MaterialApp` tira o tamanho da view, e não do `MediaQuery` de fora:
  // a tela estreita precisa vir do `tester.view`.
  Future<void> pumpNarrow(WidgetTester tester, {double textScale = 1.5}) {
    tester.view
      ..physicalSize = const Size(320, 640)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    return tester.pumpWidget(
      screen(
        mediaQuery: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      ),
    );
  }

  group('carregando', () {
    testWidgets('deve mostrar o skeleton, sem spinner', (tester) async {
      await tester.pumpWidget(screen());

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.bySemanticsLabel(l10n.movieDetailsLoading), findsOneWidget);
    });

    testWidgets('não deve vazar com fonte 1.5x numa tela de 320dp', (
      tester,
    ) async {
      await pumpNarrow(tester);

      expect(tester.takeException(), isNull);
    });

    testWidgets('deve pôr o pôster onde o conteúdo vai aparecer no tablet', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(1200, 800)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(screen());
      final skeletonLeft = tester.getTopLeft(find.byType(PosterSkeleton)).dx;

      repository.completeDetails(complete);
      await tester.pump();

      expect(tester.getTopLeft(find.byType(MoviePoster)).dx, skeletonLeft);
    });

    testWidgets('deve mostrar o pôster da grade enquanto carrega', (
      tester,
    ) async {
      await tester.pumpWidget(screen(preview: preview));

      expect(
        tester.widget<MoviePoster>(find.byType(MoviePoster)).movie,
        preview,
      );
    });

    testWidgets('deve pôr o pôster da grade no Hero do filme', (tester) async {
      await tester.pumpWidget(screen(preview: preview));

      expect(heroOfPoster(tester).movieId, 7);
    });

    testWidgets('não deve criar o Hero sem o filme da grade', (tester) async {
      await tester.pumpWidget(screen());

      expect(find.byType(PosterHero), findsNothing);
    });
  });

  group('não encontrado', () {
    Future<void> pumpNotFound(WidgetTester tester) async {
      await tester.pumpWidget(screen());
      repository.failDetails(const NotFoundFailure());
      await tester.pump();
    }

    testWidgets('deve avisar que o filme não foi encontrado', (tester) async {
      await pumpNotFound(tester);

      expect(find.text(l10n.movieNotFound), findsOneWidget);
    });

    testWidgets('não deve oferecer tentar de novo', (tester) async {
      await pumpNotFound(tester);

      expect(find.byType(RetryButton), findsNothing);
    });

    testWidgets('deve anunciar o aviso ao leitor de tela', (tester) async {
      await pumpNotFound(tester);

      expect(
        tester.getSemantics(find.text(l10n.movieNotFound)),
        isSemantics(isLiveRegion: true),
      );
    });
  });

  group('erro', () {
    Future<void> pumpError(WidgetTester tester) async {
      await tester.pumpWidget(screen());
      repository.failDetails(const NetworkFailure());
      await tester.pump();
    }

    testWidgets('deve mostrar a mensagem da falha', (tester) async {
      await pumpError(tester);

      expect(find.text(l10n.failureNetwork), findsOneWidget);
    });

    testWidgets('deve pedir de novo ao tocar em tentar de novo', (
      tester,
    ) async {
      await pumpError(tester);

      await tester.tap(find.byType(RetryButton));
      await tester.pump();

      expect(repository.requestedDetails, [7, 7]);
    });

    testWidgets('não deve vazar com fonte 1.5x numa tela de 320dp', (
      tester,
    ) async {
      await pumpNarrow(tester);
      repository.failDetails(const RateLimitFailure());
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });

  group('sucesso', () {
    testWidgets('deve mostrar o título na barra e no cabeçalho', (
      tester,
    ) async {
      await pumpWith(tester, complete);

      expect(find.text('Duna: Parte Dois'), findsNWidgets(2));
    });

    testWidgets('deve mostrar data, duração e nota formatadas', (tester) async {
      await pumpWith(tester, complete);

      expect(
        [
          '27/02/2024',
          '2 h 46 min',
          '8,1',
        ].map((text) => find.text(text).evaluate().length),
        [1, 1, 1],
      );
    });

    testWidgets('deve ler a nota com a escala', (tester) async {
      await pumpWith(tester, complete);

      expect(find.bySemanticsLabel(l10n.ratingSemantics(8.14)), findsOneWidget);
    });

    testWidgets('deve descrever o pôster ao leitor de tela', (tester) async {
      await pumpWith(tester, complete);

      expect(
        find.bySemanticsLabel(l10n.moviePosterOf('Duna: Parte Dois')),
        findsOneWidget,
      );
    });

    testWidgets('deve pôr o pôster no Hero do filme', (tester) async {
      await pumpWith(tester, complete);

      expect(heroOfPoster(tester).movieId, 7);
    });

    testWidgets('deve mostrar os gêneros', (tester) async {
      await pumpWith(tester, complete);

      expect(
        [
          'Ficção científica',
          'Aventura',
        ].map((genre) => find.widgetWithText(Chip, genre).evaluate().length),
        [1, 1],
      );
    });

    testWidgets('deve mostrar a sinopse com o título da seção', (tester) async {
      await pumpWith(tester, complete);

      expect(
        [
          l10n.movieOverviewTitle,
          'Paul Atreides se une a Chani e aos Fremen.',
        ].map((text) => find.text(text).evaluate().length),
        [1, 1],
      );
    });

    testWidgets('deve mostrar uma pessoa por membro do elenco', (tester) async {
      await pumpWith(tester, complete);

      expect(find.byType(CastMemberCard), findsNWidgets(15));
    });

    testWidgets('deve ler nome e personagem num nó só', (tester) async {
      await pumpWith(tester, complete);

      expect(
        find.bySemanticsLabel(
          l10n.castMemberSemantics('Pessoa 0', 'Personagem 0'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('não deve vazar com fonte 1.5x numa tela de 320dp', (
      tester,
    ) async {
      await pumpNarrow(tester);
      repository.completeDetails(complete);
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('não deve vazar com fonte 2x (o máximo do Android) em 320dp', (
      tester,
    ) async {
      await pumpNarrow(tester, textScale: 2);
      repository.completeDetails(complete);
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });

  group('dados ausentes', () {
    testWidgets('deve avisar que não há sinopse', (tester) async {
      await pumpWith(tester, bare);

      expect(find.text(l10n.movieNoOverview), findsOneWidget);
    });

    testWidgets('não deve mostrar seção de elenco sem elenco', (tester) async {
      await pumpWith(tester, bare);

      expect(find.text(l10n.movieCastTitle), findsNothing);
    });

    // A lista exata de textos pega também um traço ou "desconhecido" no
    // lugar do que falta, e não depende do formato da data ou da duração.
    testWidgets('deve mostrar só o título e a sinopse ausente', (tester) async {
      await pumpWith(tester, bare);

      expect(
        tester
            .widgetList<Text>(
              find.descendant(
                of: find.byType(MovieDetailsContent),
                matching: find.byType(Text),
              ),
            )
            .map((text) => text.data),
        ['Filme Sem Nada', l10n.movieOverviewTitle, l10n.movieNoOverview],
      );
    });

    testWidgets('não deve mostrar a estrela da nota', (tester) async {
      await pumpWith(tester, bare);

      expect(find.byIcon(Icons.star), findsNothing);
    });

    testWidgets('deve ler só o nome de quem vem sem personagem', (
      tester,
    ) async {
      await pumpWith(
        tester,
        MovieDetails(
          id: 7,
          title: 'Filme',
          overview: '',
          cast: [const CastMember(id: 1, name: 'Pessoa', character: '')],
        ),
      );

      expect(find.bySemanticsLabel('Pessoa'), findsOneWidget);
    });
  });

  group('transição', () {
    const gridWidth = 60.0;

    // Uma grade de um pôster só, que empilha os detalhes como a aba faz.
    Future<void> pumpGrid(WidgetTester tester) => tester.pumpWidget(
      testApp(
        home: Builder(
          builder: (context) => Align(
            alignment: Alignment.bottomRight,
            child: SizedBox(
              width: gridWidth,
              child: PosterHero(
                movieId: 7,
                child: MoviePoster(
                  movie: preview,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ChangeNotifierProvider(
                        create: (_) {
                          final notifier = MovieDetailsNotifier(
                            repository: repository,
                            movieId: 7,
                          );
                          unawaited(notifier.load());
                          return notifier;
                        },
                        child: const MovieDetailsScreen(preview: preview),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Future<void> tapAndFlyHalfway(WidgetTester tester) async {
      await tester.tap(find.byType(MoviePoster));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    }

    testWidgets('deve voar com o pôster da grade até os detalhes', (
      tester,
    ) async {
      await pumpGrid(tester);

      await tapAndFlyHalfway(tester);

      expect(
        tester.getSize(find.byType(MoviePoster)).width,
        inExclusiveRange(gridWidth, AppSizes.detailsPosterWidth),
      );
    });

    testWidgets('deve seguir voando quando o filme chega no meio do voo', (
      tester,
    ) async {
      await pumpGrid(tester);
      await tapAndFlyHalfway(tester);

      repository.completeDetails(complete);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(MoviePoster), findsOneWidget);
    });

    testWidgets('não deve ler o pôster duas vezes durante o voo', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpGrid(tester);

      await tapAndFlyHalfway(tester);

      expect(find.bySemanticsLabel(preview.title), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('deve voar de volta à grade ao voltar', (tester) async {
      await pumpGrid(tester);
      // O pulso do skeleton não para: o filme chega antes do `pumpAndSettle`.
      await tester.tap(find.byType(MoviePoster));
      await tester.pump();
      repository.completeDetails(complete);
      await tester.pumpAndSettle();

      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        tester.getSize(find.byType(MoviePoster)).width,
        inExclusiveRange(gridWidth, AppSizes.detailsPosterWidth),
      );
    });
  });
}

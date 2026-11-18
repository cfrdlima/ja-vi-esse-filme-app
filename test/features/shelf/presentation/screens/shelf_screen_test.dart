import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ja_vi_esse_filme/core/error/failures.dart';
import 'package:ja_vi_esse_filme/features/auth/domain/entities/app_user.dart';
import 'package:ja_vi_esse_filme/features/auth/domain/entities/auth_state.dart';
import 'package:ja_vi_esse_filme/features/auth/domain/repositories/auth_repository.dart';
import 'package:ja_vi_esse_filme/features/auth/presentation/state/session_notifier.dart';
import 'package:ja_vi_esse_filme/features/auth/presentation/widgets/google_sign_in_button.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/movie_copy.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/shelf_mark.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/shelf_movie.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/shelf_page.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/repositories/movie_copy_source.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/repositories/shelf_repository.dart';
import 'package:ja_vi_esse_filme/features/shelf/presentation/screens/shelf_screen.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/fake_auth_repository.dart';
import '../../../../helpers/fake_shelf_repository.dart';
import '../../../../helpers/test_app.dart';

/// Falha na hora sem rede: a renovação para e não mexe na tela.
class _SilentCopySource implements MovieCopySource {
  final List<int> requestedIds = [];

  @override
  Future<MovieCopy> fetchCopy(int movieId) {
    requestedIds.add(movieId);
    return Future.error(const NetworkFailure());
  }
}

void main() {
  late FakeShelfRepository shelf;
  late FakeAuthRepository auth;
  late _SilentCopySource source;

  final ana = AppUser(uid: 'ana123', displayName: 'Ana');

  ShelfMovie movie(int id, {DateTime? cachedAt, String? posterPath}) =>
      ShelfMovie(
        copy: MovieCopy(
          movieId: id,
          title: 'Filme $id',
          posterPath: posterPath,
        ),
        cachedAt: cachedAt ?? DateTime.now().toUtc(),
        marks: {ShelfMark.watched: DateTime.utc(2026, 11)},
      );

  ShelfPage page(List<ShelfMovie> movies, {bool hasMore = false}) =>
      ShelfPage(movies: movies, hasMore: hasMore);

  setUp(() {
    shelf = FakeShelfRepository();
    auth = FakeAuthRepository();
    source = _SilentCopySource();
  });

  tearDown(() async {
    shelf.close();
    await auth.close();
  });

  // Criados dentro do teste: assinados no `setUp`, os streams entregariam os
  // eventos fora da zona do `testWidgets`, e o `pump` não os veria.
  Widget shelfApp({TextScaler textScaler = TextScaler.noScaling}) {
    final router = GoRouter(
      initialLocation: '/estante',
      routes: [
        GoRoute(
          path: '/estante',
          builder: (_, _) => const ShelfScreen(),
          routes: [
            GoRoute(
              path: 'filme/:id',
              builder: (_, state) =>
                  Text('detalhes ${state.pathParameters['id']}'),
            ),
          ],
        ),
        GoRoute(path: '/descobrir', builder: (_, _) => const Text('descobrir')),
      ],
    );
    return MultiProvider(
      providers: [
        Provider<AuthRepository>.value(value: auth),
        Provider<ShelfRepository>.value(value: shelf),
        Provider<MovieCopySource>.value(value: source),
        ChangeNotifierProvider(
          create: (_) => SessionNotifier(repository: auth),
        ),
      ],
      child: testRouterApp(
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: textScaler),
          child: child!,
        ),
      ),
    );
  }

  Future<void> pumpSignedOut(WidgetTester tester) async {
    await tester.pumpWidget(shelfApp());
    auth.emit(const SignedOut());
    await tester.pumpAndSettle();
  }

  Future<void> pumpSignedIn(
    WidgetTester tester, {
    TextScaler? textScaler,
  }) async {
    await tester.pumpWidget(
      shelfApp(textScaler: textScaler ?? TextScaler.noScaling),
    );
    auth.emit(SignedIn(ana));
    await tester.pump();
    await tester.pump();
  }

  Future<void> emitPage(WidgetTester tester, ShelfPage page) async {
    shelf.emitShelf(page);
    await tester.pump();
    await tester.pump();
  }

  // O skeleton pulsa sem parar, e o `pumpAndSettle` nunca terminaria: a
  // troca de aba anda em passos até a animação acabar.
  Future<void> settleTabs(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  group('ShelfScreen', () {
    group('sem conta', () {
      testWidgets('deve convidar a entrar', (tester) async {
        await pumpSignedOut(tester);

        expect(
          find.text(
            'Entre para guardar os filmes que você viu, quer ver e mais gosta.',
          ),
          findsOneWidget,
        );
      });

      testWidgets('deve mostrar o botão do Google', (tester) async {
        await pumpSignedOut(tester);

        expect(find.byType(GoogleSignInButton), findsOneWidget);
      });

      testWidgets('não deve mostrar as abas', (tester) async {
        await pumpSignedOut(tester);

        expect(find.byType(TabBar), findsNothing);
      });

      testWidgets('deve entrar ao tocar no botão do Google', (tester) async {
        await pumpSignedOut(tester);

        await tester.tap(find.byType(GoogleSignInButton));
        await tester.pump();

        expect(auth.pendingSignIns, 1);
      });

      testWidgets('deve caber com a fonte grande', (tester) async {
        await tester.pumpWidget(
          shelfApp(textScaler: const TextScaler.linear(1.5)),
        );
        auth.emit(const SignedOut());
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });
    });

    group('com conta', () {
      testWidgets('deve mostrar as três abas', (tester) async {
        await pumpSignedIn(tester);

        expect(
          [
            find.text('Assistidos'),
            find.text('Quero assistir'),
            find.text('Favoritos'),
          ].every((f) => f.evaluate().length == 1),
          isTrue,
        );
      });

      testWidgets('deve abrir na aba dos assistidos', (tester) async {
        await pumpSignedIn(tester);

        expect(shelf.shelfCalls.single.mark, ShelfMark.watched);
      });

      testWidgets('deve mostrar o skeleton enquanto carrega', (tester) async {
        await pumpSignedIn(tester);

        expect(find.bySemanticsLabel('Carregando sua Estante'), findsOneWidget);
      });

      testWidgets('deve mostrar o vazio da aba', (tester) async {
        await pumpSignedIn(tester);

        await emitPage(tester, page([]));

        expect(find.text('Nenhum filme assistido ainda.'), findsOneWidget);
      });

      testWidgets('deve levar ao Descobrir pelo vazio', (tester) async {
        await pumpSignedIn(tester);
        await emitPage(tester, page([]));

        await tester.tap(find.text('Descobrir filmes'));
        await tester.pumpAndSettle();

        expect(find.text('descobrir'), findsOneWidget);
      });

      testWidgets('deve mostrar o erro da primeira página', (tester) async {
        await pumpSignedIn(tester);

        shelf.emitShelfError(const NetworkFailure());
        await tester.pump();

        expect(
          find.text('Sem conexão com a internet. Confira sua rede.'),
          findsOneWidget,
        );
      });

      testWidgets('deve assinar de novo no tentar de novo', (tester) async {
        await pumpSignedIn(tester);
        shelf.emitShelfError(const NetworkFailure());
        await tester.pump();

        await tester.tap(find.text('Tentar de novo'));
        await tester.pump();

        expect(shelf.shelfCalls, hasLength(2));
      });

      testWidgets('deve mostrar o pôster com o título do filme', (
        tester,
      ) async {
        await pumpSignedIn(tester);

        await emitPage(tester, page([movie(7)]));

        expect(find.bySemanticsLabel('Filme 7'), findsOneWidget);
      });

      testWidgets('não deve mostrar o título da cópia vencida', (tester) async {
        await pumpSignedIn(tester);

        await emitPage(tester, page([movie(7, cachedAt: DateTime.utc(2000))]));

        expect(find.bySemanticsLabel('Filme 7'), findsNothing);
      });

      testWidgets('deve dizer que a cópia vencida está atualizando', (
        tester,
      ) async {
        await pumpSignedIn(tester);

        await emitPage(tester, page([movie(7, cachedAt: DateTime.utc(2000))]));

        expect(
          find.bySemanticsLabel('Atualizando dados do filme'),
          findsOneWidget,
        );
      });

      testWidgets('deve pedir a renovação da cópia vencida', (tester) async {
        await pumpSignedIn(tester);

        await emitPage(tester, page([movie(7, cachedAt: DateTime.utc(2000))]));

        expect(source.requestedIds, [7]);
      });

      testWidgets('deve abrir os Detalhes ao tocar no pôster', (tester) async {
        await pumpSignedIn(tester);
        await emitPage(tester, page([movie(7)]));

        await tester.tap(find.bySemanticsLabel('Filme 7'));
        await tester.pumpAndSettle();

        expect(find.text('detalhes 7'), findsOneWidget);
      });

      testWidgets('deve abrir os Detalhes com o filme em duas abas vivas', (
        tester,
      ) async {
        await pumpSignedIn(tester);
        await emitPage(tester, page([movie(7)]));
        await tester.tap(find.text('Favoritos'));
        await settleTabs(tester);
        await emitPage(tester, page([movie(7)]));
        await tester.tap(find.text('Assistidos'));
        await settleTabs(tester);

        await tester.tap(find.bySemanticsLabel('Filme 7'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });

      testWidgets('deve assinar a marca da aba tocada', (tester) async {
        await pumpSignedIn(tester);

        await tester.tap(find.text('Favoritos'));
        await settleTabs(tester);

        expect(shelf.shelfCalls.last.mark, ShelfMark.favorite);
      });

      testWidgets('deve pedir mais filmes quando a página não enche a tela', (
        tester,
      ) async {
        await pumpSignedIn(tester);

        await emitPage(tester, page([movie(7)], hasMore: true));

        expect(shelf.shelfCalls.last.limit, 40);
      });

      testWidgets('deve mostrar no rodapé o erro depois dos filmes', (
        tester,
      ) async {
        await pumpSignedIn(tester);
        await emitPage(tester, page([movie(7)]));

        shelf.emitShelfError(const NetworkFailure());
        await tester.pump();
        await tester.pump();

        expect(find.text('Não deu para atualizar a Estante.'), findsOneWidget);
      });

      testWidgets('deve mostrar o spinner no rodapé enquanto pede mais', (
        tester,
      ) async {
        await pumpSignedIn(tester);

        await emitPage(tester, page([movie(7)], hasMore: true));

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('deve assinar de novo no tentar de novo do rodapé', (
        tester,
      ) async {
        await pumpSignedIn(tester);
        await emitPage(tester, page([movie(7)]));
        shelf.emitShelfError(const NetworkFailure());
        await tester.pump();
        await tester.pump();

        await tester.tap(find.text('Tentar de novo'));
        await tester.pump();

        expect(shelf.shelfCalls, hasLength(2));
      });

      testWidgets('deve avisar no rodapé que chegou ao teto', (tester) async {
        await pumpSignedIn(tester);

        // Com mais filmes e a tela sem encher, cada página pede a próxima.
        for (var i = 0; i < 10; i++) {
          await emitPage(tester, page([movie(7)], hasMore: true));
        }

        expect(
          find.text('Mostrando os 200 filmes mais recentes.'),
          findsOneWidget,
        );
      });

      testWidgets('deve voltar ao convite ao sair da conta', (tester) async {
        await pumpSignedIn(tester);
        await emitPage(tester, page([movie(7)]));

        auth.emit(const SignedOut());
        await tester.pumpAndSettle();

        expect(find.byType(GoogleSignInButton), findsOneWidget);
      });

      testWidgets('deve caber com a fonte grande', (tester) async {
        await pumpSignedIn(tester, textScaler: const TextScaler.linear(1.5));

        await emitPage(tester, page([movie(7), movie(8)]));

        expect(tester.takeException(), isNull);
      });

      testWidgets('deve caber o vazio com a fonte grande', (tester) async {
        await pumpSignedIn(tester, textScaler: const TextScaler.linear(1.5));

        await emitPage(tester, page([]));

        expect(tester.takeException(), isNull);
      });
    });
  });
}

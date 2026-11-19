import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ja_vi_esse_filme/core/error/failures.dart';
import 'package:ja_vi_esse_filme/core/l10n/app_locale.dart';
import 'package:ja_vi_esse_filme/features/auth/domain/entities/app_user.dart';
import 'package:ja_vi_esse_filme/features/auth/domain/entities/auth_state.dart';
import 'package:ja_vi_esse_filme/features/auth/domain/repositories/auth_repository.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/list_name.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/movie_copy.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/movie_list.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/shelf_movie.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/shelf_page.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/repositories/movie_copy_source.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/repositories/movie_lists_repository.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/repositories/shelf_repository.dart';
import 'package:ja_vi_esse_filme/features/shelf/presentation/screens/movie_list_screen.dart';
import 'package:ja_vi_esse_filme/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/fake_auth_repository.dart';
import '../../../../helpers/fake_movie_lists_repository.dart';
import '../../../../helpers/fake_shelf_repository.dart';
import '../../../../helpers/test_app.dart';

class _SilentCopySource implements MovieCopySource {
  @override
  Future<MovieCopy> fetchCopy(int movieId) =>
      Future.error(const NetworkFailure());
}

void main() {
  final l10n = lookupAppLocalizations(AppLocale.locale);
  final ana = AppUser(uid: 'ana123', displayName: 'Ana');
  final terror = MovieList(
    id: 'Lst0aBcDeFgHiJkLmNoP',
    name: ListName('Terror'),
  );

  late FakeMovieListsRepository lists;
  late FakeShelfRepository shelf;
  late FakeAuthRepository auth;

  ShelfMovie movie(int id) => ShelfMovie(
    copy: MovieCopy(movieId: id, title: 'Filme $id'),
    cachedAt: DateTime.now().toUtc(),
    marks: const {},
    lists: {terror.id: DateTime.utc(2026, 11)},
  );

  setUp(() {
    lists = FakeMovieListsRepository();
    shelf = FakeShelfRepository();
    auth = FakeAuthRepository();
  });

  tearDown(() async {
    shelf.close();
    await auth.close();
  });

  Widget app({TextScaler textScaler = TextScaler.noScaling}) {
    final router = GoRouter(
      initialLocation: '/estante/listas/${terror.id}',
      routes: [
        GoRoute(
          path: '/estante',
          builder: (_, _) => const Scaffold(body: Text('estante')),
          routes: [
            GoRoute(
              path: 'listas/:listId',
              builder: (_, state) => MovieListScreen(
                listId: state.pathParameters['listId']!,
                initial: terror,
              ),
              routes: [
                GoRoute(
                  path: 'filme/:id',
                  builder: (_, state) =>
                      Text('detalhes ${state.pathParameters['id']}'),
                ),
              ],
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
        Provider<MovieListsRepository>.value(value: lists),
        Provider<MovieCopySource>.value(value: _SilentCopySource()),
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

  Future<void> pumpScreen(
    WidgetTester tester, {
    TextScaler textScaler = TextScaler.noScaling,
  }) async {
    await tester.pumpWidget(app(textScaler: textScaler));
    auth.emit(SignedIn(ana));
    await tester.pump();
    await tester.pump();
    lists.emitLists([terror]);
    await tester.pump();
  }

  Future<void> emitPage(WidgetTester tester, List<ShelfMovie> movies) async {
    lists.emitPage(ShelfPage(movies: movies, hasMore: false));
    await tester.pump();
    await tester.pump();
  }

  Future<void> openMenuItem(WidgetTester tester, String label) async {
    await tester.tap(find.byTooltip(l10n.listsOptions('Terror')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  testWidgets('deve mostrar o nome da lista', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Terror'), findsOneWidget);
  });

  testWidgets('deve assinar os filmes da lista', (tester) async {
    await pumpScreen(tester);

    expect(lists.pageCalls.single.list, terror);
  });

  testWidgets('deve mostrar o vazio da lista', (tester) async {
    await pumpScreen(tester);

    await emitPage(tester, []);

    expect(find.text(l10n.listEmpty), findsOneWidget);
  });

  testWidgets('deve mostrar os pôsteres da lista', (tester) async {
    await pumpScreen(tester);

    await emitPage(tester, [movie(550)]);

    expect(find.bySemanticsLabel(RegExp('Filme 550')), findsOneWidget);
  });

  testWidgets('deve abrir os Detalhes na pilha da lista', (tester) async {
    await pumpScreen(tester);
    await emitPage(tester, [movie(550)]);

    await tester.tap(find.bySemanticsLabel(RegExp('Filme 550')));
    await tester.pumpAndSettle();

    expect(find.text('detalhes 550'), findsOneWidget);
  });

  Future<void> removeByLongPress(WidgetTester tester) async {
    await tester.longPress(find.bySemanticsLabel(RegExp('Filme 550')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.listRemoveMovie));
    await tester.pump();
  }

  testWidgets('deve tirar o filme pelo toque longo', (tester) async {
    await pumpScreen(tester);
    await emitPage(tester, [movie(550)]);

    await removeByLongPress(tester);

    expect(lists.writes.single.movie, movie(550));
  });

  testWidgets('deve avisar o filme tirado com o desfazer', (tester) async {
    await pumpScreen(tester);
    await emitPage(tester, [movie(550)]);
    await removeByLongPress(tester);

    lists.writes.single.complete();
    await tester.pumpAndSettle();

    expect([
      find.text(l10n.listMovieRemoved),
      find.text(l10n.listUndo),
    ], everyElement(findsOneWidget));
  });

  testWidgets('deve pôr o filme de volta no desfazer', (tester) async {
    await pumpScreen(tester);
    await emitPage(tester, [movie(550)]);
    await removeByLongPress(tester);
    lists.writes.single.complete();
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.listUndo));
    await tester.pump();

    expect(lists.writes.last.kind, ListWriteKind.add);
  });

  testWidgets('deve renomear pelo menu', (tester) async {
    await pumpScreen(tester);

    await openMenuItem(tester, l10n.listsRename);
    await tester.enterText(find.byType(TextField), 'Suspense');
    await tester.pump();
    await tester.tap(find.text(l10n.listsSave));
    await tester.pumpAndSettle();

    expect(find.text('Suspense'), findsOneWidget);
  });

  testWidgets('deve voltar para a Estante depois de apagar', (tester) async {
    await pumpScreen(tester);
    await openMenuItem(tester, l10n.listsDelete);
    await tester.tap(find.widgetWithText(TextButton, l10n.listsDelete));
    await tester.pump();

    lists.writes.single.complete();
    await tester.pumpAndSettle();

    expect(find.text('estante'), findsOneWidget);
  });

  testWidgets('deve dizer que a lista foi apagada em outro aparelho', (
    tester,
  ) async {
    await pumpScreen(tester);

    lists.emitLists([]);
    await tester.pump();

    expect(find.text(l10n.listGone), findsOneWidget);
  });

  testWidgets('deve voltar para as listas da lista apagada', (tester) async {
    await pumpScreen(tester);
    lists.emitLists([]);
    await tester.pump();

    await tester.tap(find.text(l10n.listBackToLists));
    await tester.pumpAndSettle();

    expect(find.text('estante'), findsOneWidget);
  });

  testWidgets('deve caber com a fonte grande', (tester) async {
    await pumpScreen(tester, textScaler: const TextScaler.linear(2));

    await emitPage(tester, [movie(550), movie(551)]);

    expect(tester.takeException(), isNull);
  });
}

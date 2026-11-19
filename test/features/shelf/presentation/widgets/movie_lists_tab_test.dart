import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/core/error/failures.dart';
import 'package:ja_vi_esse_filme/core/l10n/app_locale.dart';
import 'package:ja_vi_esse_filme/core/l10n/failure_message.dart';
import 'package:ja_vi_esse_filme/features/auth/domain/entities/app_user.dart';
import 'package:ja_vi_esse_filme/features/auth/domain/entities/auth_state.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/list_name.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/movie_list.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/usecases/create_movie_list.dart';
import 'package:ja_vi_esse_filme/features/shelf/presentation/state/movie_lists_notifier.dart';
import 'package:ja_vi_esse_filme/features/shelf/presentation/widgets/movie_lists_tab.dart';
import 'package:ja_vi_esse_filme/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/fake_movie_lists_repository.dart';
import '../../../../helpers/test_app.dart';

void main() {
  final l10n = lookupAppLocalizations(AppLocale.locale);
  final ana = AppUser(uid: 'ana123', displayName: 'Ana');

  MovieList listNamed(String name, int id) => MovieList(
    id: 'Lst${id.toString().padLeft(17, '0')}',
    name: ListName(name),
  );

  final terror = listNamed('Terror', 1);

  late FakeMovieListsRepository lists;
  late StreamController<AuthState> account;
  late MovieListsNotifier notifier;
  late List<MovieList> opened;

  setUp(() {
    lists = FakeMovieListsRepository();
    account = StreamController<AuthState>.broadcast();
    notifier = MovieListsNotifier(
      lists: lists,
      createList: CreateMovieList(lists),
      account: account.stream,
    );
    opened = [];
  });

  tearDown(() => account.close());

  Future<void> pumpTab(WidgetTester tester) async {
    await tester.pumpWidget(
      testApp(
        home: Scaffold(
          body: ChangeNotifierProvider.value(
            value: notifier,
            child: MovieListsTabView(onOpen: opened.add),
          ),
        ),
      ),
    );
    account.add(SignedIn(ana));
    await tester.pump();
  }

  Future<void> emit(WidgetTester tester, List<MovieList> value) async {
    lists.emitLists(value);
    await tester.pump();
  }

  Future<void> openMenu(WidgetTester tester, MovieList list) async {
    await tester.tap(find.byTooltip(l10n.listsOptions(list.name.value)));
    await tester.pumpAndSettle();
  }

  testWidgets('deve mostrar o skeleton carregando', (tester) async {
    await pumpTab(tester);

    expect(find.bySemanticsLabel(l10n.listsLoading), findsOneWidget);
  });

  testWidgets('deve mostrar o vazio com o criar lista', (tester) async {
    await pumpTab(tester);

    await emit(tester, []);

    expect([
      find.text(l10n.listsEmpty),
      find.text(l10n.listsCreateAction),
    ], everyElement(findsOneWidget));
  });

  testWidgets('deve abrir o diálogo pelo criar lista do vazio', (tester) async {
    await pumpTab(tester);
    await emit(tester, []);

    await tester.tap(find.text(l10n.listsCreateAction));
    await tester.pumpAndSettle();

    expect(find.text(l10n.listsNameLabel), findsOneWidget);
  });

  testWidgets('deve mostrar o erro com o tentar de novo', (tester) async {
    await pumpTab(tester);
    lists.emitListsError(const NetworkFailure());
    await tester.pump();

    await tester.tap(find.text(l10n.retry));
    await tester.pump();

    expect(lists.watchListsCalls, 2);
  });

  testWidgets('deve mostrar as listas', (tester) async {
    await pumpTab(tester);

    await emit(tester, [terror, listNamed('Ação', 2)]);

    expect([
      find.text('Terror'),
      find.text('Ação'),
    ], everyElement(findsOneWidget));
  });

  testWidgets('deve abrir a lista tocada', (tester) async {
    await pumpTab(tester);
    await emit(tester, [terror]);

    await tester.tap(find.text('Terror'));

    expect(opened, [terror]);
  });

  testWidgets('deve criar pela Nova lista', (tester) async {
    await pumpTab(tester);
    await emit(tester, [terror]);

    await tester.tap(find.text(l10n.listsNew));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Ação');
    await tester.tap(find.text(l10n.listsCreate));
    await tester.pumpAndSettle();

    expect(find.text('Ação'), findsOneWidget);
  });

  testWidgets('deve desabilitar a Nova lista no teto', (tester) async {
    await pumpTab(tester);

    await emit(tester, [
      for (var i = 0; i < MovieList.maxPerAccount; i++) listNamed('L$i', i),
    ]);

    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, l10n.listsNew),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets('deve dizer o teto abaixo da Nova lista', (tester) async {
    await pumpTab(tester);

    await emit(tester, [
      for (var i = 0; i < MovieList.maxPerAccount; i++) listNamed('L$i', i),
    ]);

    expect(
      find.text(l10n.listsAtLimit(MovieList.maxPerAccount)),
      findsOneWidget,
    );
  });

  testWidgets('deve avisar a recusa ao criar', (tester) async {
    await pumpTab(tester);
    await emit(tester, [terror]);
    await tester.tap(find.text(l10n.listsNew));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Ação');
    await tester.tap(find.text(l10n.listsCreate));
    await tester.pumpAndSettle();

    lists.writes.single.fail(const RateLimitFailure());
    await tester.pumpAndSettle();

    expect(
      find.text(failureMessage(l10n, const RateLimitFailure())),
      findsOneWidget,
    );
  });

  testWidgets('deve renomear pelo menu', (tester) async {
    await pumpTab(tester);
    await emit(tester, [terror]);

    await openMenu(tester, terror);
    await tester.tap(find.text(l10n.listsRename));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Suspense');
    await tester.tap(find.text(l10n.listsSave));
    await tester.pumpAndSettle();

    expect(find.text('Suspense'), findsOneWidget);
  });

  testWidgets('deve perguntar antes de apagar', (tester) async {
    await pumpTab(tester);
    await emit(tester, [terror]);

    await openMenu(tester, terror);
    await tester.tap(find.text(l10n.listsDelete));
    await tester.pumpAndSettle();

    expect(find.text(l10n.listsDeleteTitle('Terror')), findsOneWidget);
  });

  testWidgets('não deve apagar no Cancelar', (tester) async {
    await pumpTab(tester);
    await emit(tester, [terror]);
    await openMenu(tester, terror);
    await tester.tap(find.text(l10n.listsDelete));
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.listsCancel));
    await tester.pumpAndSettle();

    expect(lists.writes, isEmpty);
  });

  Future<void> confirmDelete(WidgetTester tester) async {
    await openMenu(tester, terror);
    await tester.tap(find.text(l10n.listsDelete));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, l10n.listsDelete));
    await tester.pump();
  }

  testWidgets('deve mostrar a linha apagando', (tester) async {
    await pumpTab(tester);
    await emit(tester, [terror]);

    await confirmDelete(tester);

    expect(find.bySemanticsLabel(l10n.listsDeleting('Terror')), findsOneWidget);
  });

  testWidgets('deve avisar a lista apagada', (tester) async {
    await pumpTab(tester);
    await emit(tester, [terror]);
    await confirmDelete(tester);

    lists.writes.single.complete();
    await tester.pump();
    await tester.pump();

    expect(find.text(l10n.listsDeleted), findsOneWidget);
  });

  testWidgets('deve avisar a falha ao apagar com o tentar de novo', (
    tester,
  ) async {
    await pumpTab(tester);
    await emit(tester, [terror]);
    await confirmDelete(tester);

    lists.writes.single.fail(const NetworkFailure());
    await tester.pump();
    await tester.pump();

    expect([
      find.text(failureMessage(l10n, const NetworkFailure())),
      find.widgetWithText(SnackBarAction, l10n.retry),
    ], everyElement(findsOneWidget));
  });

  testWidgets('deve caber com a fonte grande', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpTab(tester);

    await emit(tester, [
      for (var i = 0; i < MovieList.maxPerAccount; i++)
        listNamed('Uma lista com nome comprido $i', i),
    ]);

    expect(tester.takeException(), isNull);
  });
}

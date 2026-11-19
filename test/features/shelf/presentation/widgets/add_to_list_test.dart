import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/core/error/failures.dart';
import 'package:ja_vi_esse_filme/core/l10n/app_locale.dart';
import 'package:ja_vi_esse_filme/core/l10n/failure_message.dart';
import 'package:ja_vi_esse_filme/features/auth/domain/entities/app_user.dart';
import 'package:ja_vi_esse_filme/features/auth/domain/entities/auth_state.dart';
import 'package:ja_vi_esse_filme/features/auth/domain/repositories/auth_repository.dart';
import 'package:ja_vi_esse_filme/features/auth/presentation/state/session_notifier.dart';
import 'package:ja_vi_esse_filme/features/auth/presentation/widgets/google_sign_in_button.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/list_name.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/movie_copy.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/movie_list.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/shelf_entry.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/shelf_movie.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/repositories/movie_lists_repository.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/repositories/shelf_repository.dart';
import 'package:ja_vi_esse_filme/features/shelf/presentation/widgets/shelf_marks_section.dart';
import 'package:ja_vi_esse_filme/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/fake_auth_repository.dart';
import '../../../../helpers/fake_movie_lists_repository.dart';
import '../../../../helpers/fake_shelf_repository.dart';
import '../../../../helpers/test_app.dart';

void main() {
  final l10n = lookupAppLocalizations(AppLocale.locale);
  final ana = AppUser(uid: 'ana123', displayName: 'Ana');
  final copy = MovieCopy(movieId: 550, title: 'Clube da Luta');
  final terror = MovieList(
    id: 'Lst0aBcDeFgHiJkLmNoP',
    name: ListName('Terror'),
  );

  late FakeShelfRepository shelf;
  late FakeMovieListsRepository lists;
  late FakeAuthRepository auth;

  setUp(() {
    shelf = FakeShelfRepository();
    lists = FakeMovieListsRepository();
    auth = FakeAuthRepository();
  });

  tearDown(() async {
    shelf.close();
    await auth.close();
  });

  Future<void> pumpDetails(
    WidgetTester tester, {
    AuthState account = const SignedOut(),
    ShelfEntry? entry,
    TextScaler textScaler = TextScaler.noScaling,
  }) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ShelfRepository>.value(value: shelf),
          Provider<MovieListsRepository>.value(value: lists),
          Provider<AuthRepository>.value(value: auth),
          ChangeNotifierProvider(
            create: (_) => SessionNotifier(repository: auth),
          ),
        ],
        child: MediaQuery(
          data: MediaQueryData(textScaler: textScaler),
          child: testApp(
            home: const Scaffold(
              body: SingleChildScrollView(
                child: ShelfMarksSection(movieId: 550, title: 'Clube da Luta'),
              ),
            ),
          ),
        ),
      ),
    );
    auth.emit(account);
    await tester.pump();
    if (entry != null) {
      shelf.emit(entry);
      await tester.pump();
    }
  }

  ShelfEntry inTerror() => OnShelf(
    ShelfMovie(
      copy: copy,
      cachedAt: DateTime.utc(2026, 11),
      marks: const {},
      lists: {terror.id: DateTime.utc(2026, 11)},
    ),
  );

  Future<void> openSheet(WidgetTester tester, List<MovieList> value) async {
    await tester.tap(find.text(l10n.addToListAction));
    await tester.pump();
    lists.emitLists(value);
    await tester.pumpAndSettle();
  }

  testWidgets('deve mostrar o Adicionar à lista fora das listas', (
    tester,
  ) async {
    await pumpDetails(
      tester,
      account: SignedIn(ana),
      entry: const NotOnShelf(),
    );

    expect(find.text(l10n.addToListAction), findsOneWidget);
  });

  testWidgets('deve dizer que o filme está nas listas', (tester) async {
    await pumpDetails(tester, account: SignedIn(ana), entry: inTerror());

    expect(find.text(l10n.addToListInLists), findsOneWidget);
  });

  testWidgets('deve mostrar o botão sem conta', (tester) async {
    await pumpDetails(tester);

    expect(find.text(l10n.addToListAction), findsOneWidget);
  });

  testWidgets('deve levar ao login sem conta', (tester) async {
    await pumpDetails(tester);

    await tester.tap(find.text(l10n.addToListAction));
    await tester.pumpAndSettle();

    expect(find.byType(GoogleSignInButton), findsOneWidget);
  });

  testWidgets('deve abrir a folha com as listas', (tester) async {
    await pumpDetails(
      tester,
      account: SignedIn(ana),
      entry: const NotOnShelf(),
    );

    await openSheet(tester, [terror]);

    expect(find.widgetWithText(CheckboxListTile, 'Terror'), findsOneWidget);
  });

  testWidgets('deve pôr o filme na lista marcada', (tester) async {
    await pumpDetails(
      tester,
      account: SignedIn(ana),
      entry: const NotOnShelf(),
    );
    await openSheet(tester, [terror]);

    await tester.tap(find.widgetWithText(CheckboxListTile, 'Terror'));
    await tester.pump();
    await tester.pump();

    expect(lists.writes.single.kind, ListWriteKind.add);
  });

  testWidgets('deve dizer que ainda não há listas', (tester) async {
    await pumpDetails(
      tester,
      account: SignedIn(ana),
      entry: const NotOnShelf(),
    );

    await openSheet(tester, []);

    expect(find.text(l10n.addToListNone), findsOneWidget);
  });

  testWidgets('deve criar lista pela folha', (tester) async {
    await pumpDetails(
      tester,
      account: SignedIn(ana),
      entry: const NotOnShelf(),
    );
    await openSheet(tester, []);

    await tester.tap(find.text(l10n.listsNew));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Ação');
    await tester.pump();
    await tester.tap(find.text(l10n.listsCreate));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(CheckboxListTile, 'Ação'), findsOneWidget);
  });

  testWidgets('deve avisar a lista cheia', (tester) async {
    await pumpDetails(
      tester,
      account: SignedIn(ana),
      entry: const NotOnShelf(),
    );
    lists.moviesCount[terror.id] = MovieList.maxMovies;
    await openSheet(tester, [terror]);

    await tester.tap(find.widgetWithText(CheckboxListTile, 'Terror'));
    await tester.pump();
    await tester.pump();

    expect(
      find.text(failureMessage(l10n, const ListFullFailure())),
      findsOneWidget,
    );
  });

  testWidgets('deve caber a folha com a fonte grande', (tester) async {
    await pumpDetails(
      tester,
      account: SignedIn(ana),
      entry: const NotOnShelf(),
      textScaler: const TextScaler.linear(2),
    );

    await openSheet(tester, [
      for (var i = 0; i < 12; i++)
        MovieList(
          id: 'Lst${i.toString().padLeft(17, '0')}',
          name: ListName('Uma lista com nome comprido $i'),
        ),
    ]);

    expect(tester.takeException(), isNull);
  });
}

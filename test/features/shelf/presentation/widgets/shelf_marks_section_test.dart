import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/features/auth/domain/entities/app_user.dart';
import 'package:ja_vi_esse_filme/features/auth/domain/entities/auth_state.dart';
import 'package:ja_vi_esse_filme/features/auth/domain/repositories/auth_repository.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/movie_copy.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/rating.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/shelf_entry.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/shelf_mark.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/shelf_movie.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/repositories/shelf_repository.dart';
import 'package:ja_vi_esse_filme/features/shelf/presentation/widgets/shelf_marks_section.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/fake_auth_repository.dart';
import '../../../../helpers/fake_shelf_repository.dart';
import '../../../../helpers/test_app.dart';

void main() {
  late FakeShelfRepository shelf;
  late FakeAuthRepository auth;

  final ana = AppUser(uid: 'ana123', displayName: 'Ana');
  final watchedAt = DateTime.utc(2026, 11, 10);

  setUp(() {
    shelf = FakeShelfRepository();
    auth = FakeAuthRepository();
  });

  tearDown(() async {
    shelf.close();
    await auth.close();
  });

  Future<void> pumpSection(
    WidgetTester tester, {
    required Set<ShelfMark> marks,
    Rating? rating,
  }) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ShelfRepository>.value(value: shelf),
          Provider<AuthRepository>.value(value: auth),
        ],
        child: testApp(
          home: const Scaffold(
            body: SingleChildScrollView(
              child: ShelfMarksSection(movieId: 550, title: 'Clube da Luta'),
            ),
          ),
        ),
      ),
    );
    auth.emit(SignedIn(ana));
    await tester.pump();
    shelf.emit(
      OnShelf(
        ShelfMovie(
          copy: MovieCopy(movieId: 550, title: 'Clube da Luta'),
          cachedAt: watchedAt,
          marks: {for (final mark in marks) mark: watchedAt},
          rating: rating,
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> tapWatched(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(FilterChip, 'Assistido'));
    await tester.pumpAndSettle();
  }

  group('ShelfMarksSection', () {
    testWidgets('deve mostrar a nota no filme assistido', (tester) async {
      await pumpSection(tester, marks: {ShelfMark.watched});

      expect(find.text('Sua nota'), findsOneWidget);
    });

    testWidgets('não deve mostrar a nota no filme não assistido', (
      tester,
    ) async {
      await pumpSection(tester, marks: {ShelfMark.favorite});

      expect(find.text('Sua nota'), findsNothing);
    });

    testWidgets('deve pedir confirmação ao tirar o Assistido com nota', (
      tester,
    ) async {
      await pumpSection(tester, marks: {ShelfMark.watched}, rating: Rating(7));

      await tapWatched(tester);

      expect(find.text('Tirar dos assistidos?'), findsOneWidget);
    });

    testWidgets('não deve tirar o Assistido ao cancelar', (tester) async {
      await pumpSection(tester, marks: {ShelfMark.watched}, rating: Rating(7));
      await tapWatched(tester);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(shelf.writes, isEmpty);
    });

    testWidgets('deve tirar o Assistido ao confirmar', (tester) async {
      await pumpSection(tester, marks: {ShelfMark.watched}, rating: Rating(7));
      await tapWatched(tester);

      await tester.tap(find.text('Tirar'));
      await tester.pumpAndSettle();

      expect(
        (shelf.writes.single.mark, shelf.writes.single.isAdd),
        (ShelfMark.watched, false),
      );
    });

    testWidgets('não deve perguntar ao tirar o Assistido sem nota nem dia', (
      tester,
    ) async {
      await pumpSection(tester, marks: {ShelfMark.watched});

      await tapWatched(tester);

      expect(find.text('Tirar dos assistidos?'), findsNothing);
    });

    testWidgets('deve tirar na hora o Assistido sem nota nem dia', (
      tester,
    ) async {
      await pumpSection(tester, marks: {ShelfMark.watched});

      await tapWatched(tester);

      expect(shelf.writes.single.mark, ShelfMark.watched);
    });

    // Outro aparelho tirou o Assistido com o diálogo aberto: o "Tirar" não
    // pode pôr a marca de volta.
    testWidgets('não deve pôr o Assistido de volta ao confirmar', (
      tester,
    ) async {
      await pumpSection(
        tester,
        marks: {ShelfMark.watched, ShelfMark.favorite},
        rating: Rating(7),
      );
      await tapWatched(tester);
      shelf.emit(
        OnShelf(
          ShelfMovie(
            copy: MovieCopy(movieId: 550, title: 'Clube da Luta'),
            cachedAt: watchedAt,
            marks: {ShelfMark.favorite: watchedAt},
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Tirar'));
      await tester.pumpAndSettle();

      expect(shelf.writes, isEmpty);
    });

    testWidgets('deve caber a confirmação com a fonte grande', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpSection(tester, marks: {ShelfMark.watched}, rating: Rating(7));

      await tapWatched(tester);

      expect(
        (
          find.text('Tirar dos assistidos?').evaluate().length,
          tester.takeException(),
        ),
        (1, null),
      );
    });

    testWidgets('não deve perguntar ao tirar o Favorito com nota', (
      tester,
    ) async {
      await pumpSection(
        tester,
        marks: {ShelfMark.watched, ShelfMark.favorite},
        rating: Rating(7),
      );

      await tester.tap(find.widgetWithText(FilterChip, 'Favorito'));
      await tester.pumpAndSettle();

      expect(find.text('Tirar dos assistidos?'), findsNothing);
    });
  });
}

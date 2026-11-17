import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/core/error/failures.dart';
import 'package:ja_vi_esse_filme/features/auth/domain/entities/app_user.dart';
import 'package:ja_vi_esse_filme/features/auth/domain/entities/auth_state.dart';
import 'package:ja_vi_esse_filme/features/auth/domain/entities/sign_in_outcome.dart';
import 'package:ja_vi_esse_filme/features/auth/presentation/state/session_notifier.dart';
import 'package:ja_vi_esse_filme/features/auth/presentation/widgets/sign_in_sheet.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/movie_copy.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/shelf_entry.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/shelf_mark.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/shelf_movie.dart';
import 'package:ja_vi_esse_filme/features/shelf/presentation/state/shelf_marks_notifier.dart';
import 'package:ja_vi_esse_filme/features/shelf/presentation/widgets/shelf_marks_bar.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/fake_auth_repository.dart';
import '../../../../helpers/fake_shelf_repository.dart';
import '../../../../helpers/test_app.dart';

void main() {
  late FakeShelfRepository shelf;
  late FakeAuthRepository auth;
  late SessionNotifier session;
  late ShelfMarksNotifier marks;

  final ana = AppUser(uid: 'ana123', displayName: 'Ana');
  final copy = MovieCopy(movieId: 550, title: 'Clube da Luta');

  setUp(() {
    shelf = FakeShelfRepository();
    auth = FakeAuthRepository();
  });

  tearDown(() async {
    shelf.close();
    await auth.close();
  });

  // Criados dentro do teste: assinados no `setUp`, os streams entregariam os
  // eventos fora da zona do `testWidgets`, e o `pump` não os veria.
  Widget barApp({TextScaler textScaler = TextScaler.noScaling}) {
    session = SessionNotifier(repository: auth);
    marks = ShelfMarksNotifier(
      shelf: shelf,
      account: auth.authStateChanges,
      copy: copy,
    );
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: session),
        ChangeNotifierProvider.value(value: marks),
      ],
      child: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: textScaler),
          child: testApp(home: const Scaffold(body: ShelfMarksBar())),
        ),
      ),
    );
  }

  Future<void> pumpBar(WidgetTester tester) async {
    await tester.pumpWidget(barApp());
    addTearDown(() {
      marks.dispose();
      session.dispose();
    });
  }

  Future<void> readyWith(WidgetTester tester, Set<ShelfMark> on) async {
    await pumpBar(tester);
    auth.emit(SignedIn(ana));
    await tester.pump();
    shelf.emit(
      on.isEmpty
          ? const NotOnShelf()
          : OnShelf(
              ShelfMovie(
                copy: copy,
                cachedAt: DateTime.utc(2026, 11),
                marks: {for (final m in on) m: DateTime.utc(2026, 11)},
              ),
            ),
    );
    await tester.pump();
  }

  bool isSelected(WidgetTester tester, String label) => tester
      .widget<FilterChip>(find.widgetWithText(FilterChip, label))
      .selected;

  group('carregando', () {
    testWidgets('deve anunciar que as marcas estão carregando', (tester) async {
      await pumpBar(tester);

      expect(find.bySemanticsLabel('Carregando suas marcas'), findsOneWidget);
    });

    testWidgets('deve não mostrar os chips enquanto carrega', (tester) async {
      await pumpBar(tester);

      expect(find.byType(FilterChip), findsNothing);
    });
  });

  group('sucesso', () {
    testWidgets('deve mostrar as três marcas na ordem', (tester) async {
      await readyWith(tester, {});

      final labels = tester
          .widgetList<FilterChip>(find.byType(FilterChip))
          .map((chip) => (chip.label as Text).data);
      expect(labels, ['Assistido', 'Quero assistir', 'Favorito']);
    });

    testWidgets('deve mostrar ligada a marca que o filme tem', (tester) async {
      await readyWith(tester, {ShelfMark.favorite});

      expect(isSelected(tester, 'Favorito'), isTrue);
    });

    testWidgets('deve mostrar desligada a marca que o filme não tem', (
      tester,
    ) async {
      await readyWith(tester, {ShelfMark.favorite});

      expect(isSelected(tester, 'Assistido'), isFalse);
    });

    testWidgets('deve trocar o ícone para o cheio na marca ligada', (
      tester,
    ) async {
      await readyWith(tester, {ShelfMark.watched});

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('deve ligar a marca na hora ao tocar', (tester) async {
      await readyWith(tester, {});

      await tester.tap(find.text('Quero assistir'));
      await tester.pump();

      expect(isSelected(tester, 'Quero assistir'), isTrue);
    });

    testWidgets('deve ter alvo de toque de pelo menos 48dp', (tester) async {
      await readyWith(tester, {});

      expect(
        tester.getSize(find.widgetWithText(FilterChip, 'Favorito')).height,
        greaterThanOrEqualTo(48),
      );
    });

    testWidgets('deve anunciar a marca ligada como selecionada', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await readyWith(tester, {ShelfMark.favorite});

      expect(
        tester.getSemantics(find.widgetWithText(FilterChip, 'Favorito')),
        matchesSemantics(
          label: 'Favorito',
          isButton: true,
          hasSelectedState: true,
          isSelected: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      semantics.dispose();
    });

    testWidgets('deve caber sem overflow com fonte grande', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(barApp(textScaler: const TextScaler.linear(2)));
      addTearDown(() {
        marks.dispose();
        session.dispose();
      });
      auth.emit(SignedIn(ana));
      await tester.pump();
      shelf.emit(const NotOnShelf());
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });

  group('erro', () {
    testWidgets('deve mostrar o erro de leitura', (tester) async {
      await pumpBar(tester);
      auth.emit(SignedIn(ana));
      await tester.pump();
      shelf.emitError(const NetworkFailure());
      await tester.pump();

      expect(find.text('Não deu para carregar suas marcas.'), findsOneWidget);
    });

    testWidgets('deve assinar de novo ao tocar em tentar de novo', (
      tester,
    ) async {
      await pumpBar(tester);
      auth.emit(SignedIn(ana));
      await tester.pump();
      shelf.emitError(const NetworkFailure());
      await tester.pump();

      await tester.tap(find.text('Tentar de novo'));
      await tester.pump();

      expect(shelf.watchCalls, 2);
    });

    testWidgets('deve mostrar a falha da escrita recusada', (tester) async {
      await readyWith(tester, {});
      await tester.tap(find.text('Favorito'));
      await tester.pump();

      shelf.writes.single.fail(const NetworkFailure());
      await tester.pump();

      expect(
        find.text('Sem conexão com a internet. Confira sua rede.'),
        findsOneWidget,
      );
    });

    testWidgets('deve repetir a escrita ao tocar em tentar de novo', (
      tester,
    ) async {
      await readyWith(tester, {});
      await tester.tap(find.text('Favorito'));
      await tester.pump();
      shelf.writes.single.fail(const NetworkFailure());
      await tester.pump();

      await tester.tap(find.text('Tentar de novo'));
      await tester.pump();

      expect(shelf.writes.length, 2);
    });
  });

  group('deslogado', () {
    Future<void> signedOut(WidgetTester tester) async {
      await pumpBar(tester);
      auth.emit(const SignedOut());
      await tester.pump();
    }

    testWidgets('deve mostrar as marcas desligadas', (tester) async {
      await signedOut(tester);

      expect(isSelected(tester, 'Assistido'), isFalse);
    });

    testWidgets('deve abrir a folha de login ao tocar numa marca', (
      tester,
    ) async {
      await signedOut(tester);

      await tester.tap(find.text('Assistido'));
      await tester.pumpAndSettle();

      expect(find.byType(SignInSheet), findsOneWidget);
    });

    testWidgets('deve pôr a marca tocada depois do login', (tester) async {
      await signedOut(tester);
      await tester.tap(find.text('Favorito'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Entrar com o Google'));
      await tester.pump();
      auth.completeSignIn(SignInCompleted(ana));
      auth.emit(SignedIn(ana));
      // Sem `pumpAndSettle`: o skeleton das marcas pulsa enquanto carrega.
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      shelf.emit(const NotOnShelf());
      await tester.pump();

      expect(
        (shelf.writes.single.mark, shelf.writes.single.isAdd),
        (ShelfMark.favorite, true),
      );
    });

    testWidgets('deve não marcar nada ao fechar a folha sem login', (
      tester,
    ) async {
      await signedOut(tester);
      await tester.tap(find.text('Favorito'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(CloseButton));
      await tester.pumpAndSettle();
      auth.emit(SignedIn(ana));
      await tester.pump();
      shelf.emit(const NotOnShelf());
      await tester.pump();

      expect(shelf.writes, isEmpty);
    });
  });
}

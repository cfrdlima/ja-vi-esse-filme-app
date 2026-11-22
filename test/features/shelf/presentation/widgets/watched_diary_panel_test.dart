import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/core/error/failures.dart';
import 'package:ja_vi_esse_filme/core/theme/app_spacing.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/movie_copy.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/rating.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/shelf_mark.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/shelf_movie.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/watched_on.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/usecases/choose_watched_on.dart';
import 'package:ja_vi_esse_filme/features/shelf/presentation/state/watched_diary_notifier.dart';
import 'package:ja_vi_esse_filme/features/shelf/presentation/widgets/watched_diary_panel.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/accessibility.dart';
import '../../../../helpers/fake_shelf_repository.dart';
import '../../../../helpers/test_app.dart';

void main() {
  final now = DateTime(2026, 11, 18, 12);
  final watchedAt = DateTime(2026, 11, 10, 20);

  ShelfMovie watched({Rating? rating, WatchedOn? watchedOn}) => ShelfMovie(
    copy: MovieCopy(movieId: 550, title: 'Clube da Luta'),
    cachedAt: watchedAt,
    marks: {ShelfMark.watched: watchedAt},
    rating: rating,
    watchedOn: watchedOn,
  );

  late FakeShelfRepository shelf;
  late ValueNotifier<ShelfMovie?> movie;
  late WatchedDiaryNotifier diary;

  setUp(() {
    shelf = FakeShelfRepository();
    movie = ValueNotifier(null);
  });

  tearDown(() {
    movie.dispose();
    shelf.close();
  });

  Future<void> pumpPanel(
    WidgetTester tester, {
    ShelfMovie? initial,
    TextScaler textScaler = TextScaler.noScaling,
  }) async {
    movie.value = initial;
    diary = WatchedDiaryNotifier(
      shelf: shelf,
      chooseWatchedOn: ChooseWatchedOn(shelf: shelf, now: () => now),
      watchedMovie: movie,
    );
    addTearDown(diary.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: diary,
        child: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: textScaler),
            child: testApp(
              home: Scaffold(
                // A margem dos Detalhes: a guideline de alvo de toque ignora o
                // que encosta na borda da tela (decisão 020).
                body: SingleChildScrollView(
                  padding: EdgeInsets.all(AppSpacing.standard.md),
                  child: const WatchedDiaryPanel(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Finder star(int n) => find.byKey(ValueKey('diary-star-$n'));

  group('WatchedDiaryPanel', () {
    testWidgets('não deve mostrar nada sem o filme assistido', (tester) async {
      await pumpPanel(tester);

      expect(find.text('Sua nota'), findsNothing);
    });

    testWidgets('deve mostrar o rótulo da nota', (tester) async {
      await pumpPanel(tester, initial: watched());

      expect(find.text('Sua nota'), findsOneWidget);
    });

    testWidgets('deve mostrar cinco estrelas', (tester) async {
      await pumpPanel(tester, initial: watched());

      expect(find.byIcon(Icons.star_border), findsNWidgets(5));
    });

    testWidgets('deve desenhar três estrelas e meia', (tester) async {
      await pumpPanel(tester, initial: watched(rating: Rating(7)));

      expect(
        (
          find.byIcon(Icons.star).evaluate().length,
          find.byIcon(Icons.star_half).evaluate().length,
          find.byIcon(Icons.star_border).evaluate().length,
        ),
        (3, 1, 1),
      );
    });

    testWidgets('deve dar quatro estrelas ao tocar na quarta', (tester) async {
      await pumpPanel(tester, initial: watched());

      await tester.tap(star(4));
      await tester.pump();

      expect(shelf.personalWrites.single.value, Rating(8));
    });

    testWidgets('deve ter alvo de toque de 48dp em cada estrela', (
      tester,
    ) async {
      await pumpPanel(tester, initial: watched());

      expect(tester.getSize(star(1)).width, greaterThanOrEqualTo(48));
    });

    testWidgets('deve ler a nota para o leitor de tela', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpPanel(tester, initial: watched(rating: Rating(7)));

      expect(
        tester.getSemantics(find.byKey(const ValueKey('diary-stars'))),
        isSemantics(
          label: 'Sua nota',
          value: '3,5 de 5 estrelas',
          hasIncreaseAction: true,
          hasDecreaseAction: true,
        ),
      );
      semantics.dispose();
    });

    testWidgets('deve ler "Sem nota" para o leitor de tela', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpPanel(tester, initial: watched());

      expect(
        tester.getSemantics(find.byKey(const ValueKey('diary-stars'))),
        isSemantics(label: 'Sua nota', value: 'Sem nota'),
      );
      semantics.dispose();
    });

    testWidgets('deve subir meia estrela pelo leitor de tela', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpPanel(tester, initial: watched(rating: Rating(7)));

      tester.semantics.increase(find.semantics.byLabel('Sua nota'));
      await tester.pump();

      expect(shelf.personalWrites.single.value, Rating(8));
      semantics.dispose();
    });

    testWidgets('deve ler as estrelas como controle deslizante', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpPanel(tester, initial: watched(rating: Rating(7)));

      expect(
        tester.getSemantics(find.byKey(const ValueKey('diary-stars'))),
        isSemantics(isSlider: true),
      );
      semantics.dispose();
    });

    testWidgets('deve descer meia estrela pelo leitor de tela', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpPanel(tester, initial: watched(rating: Rating(7)));

      tester.semantics.decrease(find.semantics.byLabel('Sua nota'));
      await tester.pump();

      expect(shelf.personalWrites.single.value, Rating(6));
      semantics.dispose();
    });

    testWidgets('não deve oferecer subir com cinco estrelas', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpPanel(tester, initial: watched(rating: Rating(10)));

      expect(
        tester.getSemantics(find.byKey(const ValueKey('diary-stars'))),
        isSemantics(hasIncreaseAction: false, hasDecreaseAction: true),
      );
      semantics.dispose();
    });

    testWidgets('não deve oferecer descer sem nota', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpPanel(tester, initial: watched());

      expect(
        tester.getSemantics(find.byKey(const ValueKey('diary-stars'))),
        isSemantics(hasIncreaseAction: true, hasDecreaseAction: false),
      );
      semantics.dispose();
    });

    testWidgets('deve dizer ao leitor de tela que o botão escolhe o dia', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpPanel(tester, initial: watched());

      expect(
        tester.getSemantics(find.byType(TextButton).first),
        isSemantics(tooltip: 'Escolher quando assistiu', isButton: true),
      );
      semantics.dispose();
    });

    testWidgets('não deve mostrar "Tirar nota" sem nota', (tester) async {
      await pumpPanel(tester, initial: watched());

      expect(find.text('Tirar nota'), findsNothing);
    });

    testWidgets('deve tirar a nota', (tester) async {
      await pumpPanel(tester, initial: watched(rating: Rating(7)));

      await tester.tap(find.text('Tirar nota'));
      await tester.pump();

      expect(
        (shelf.personalWrites.single.field, shelf.personalWrites.single.value),
        (PersonalField.rating, null),
      );
    });

    testWidgets('deve sugerir o dia da marca', (tester) async {
      await pumpPanel(tester, initial: watched());

      expect(find.text('10/11/2026 (dia da marca)'), findsOneWidget);
    });

    testWidgets('deve mostrar o dia escolhido', (tester) async {
      final day = WatchedOn(year: 2026, month: 11, day: 1);
      await pumpPanel(tester, initial: watched(watchedOn: day));

      expect(find.text('01/11/2026'), findsOneWidget);
    });

    testWidgets('não deve mostrar "Tirar dia" sem dia escolhido', (
      tester,
    ) async {
      await pumpPanel(tester, initial: watched());

      expect(find.text('Tirar dia'), findsNothing);
    });

    testWidgets('deve tirar o dia escolhido', (tester) async {
      final day = WatchedOn(year: 2026, month: 11, day: 1);
      await pumpPanel(tester, initial: watched(watchedOn: day));

      await tester.tap(find.text('Tirar dia'));
      await tester.pump();

      expect(
        (shelf.personalWrites.single.field, shelf.personalWrites.single.value),
        (PersonalField.watchedOn, null),
      );
    });

    testWidgets('deve gravar o dia confirmado no seletor', (tester) async {
      await pumpPanel(tester, initial: watched());

      await tester.tap(find.text('10/11/2026 (dia da marca)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('12'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(
        shelf.personalWrites.single.value,
        WatchedOn(year: 2026, month: 11, day: 12),
      );
    });

    testWidgets('não deve gravar nada ao cancelar o seletor', (tester) async {
      await pumpPanel(tester, initial: watched());

      await tester.tap(find.text('10/11/2026 (dia da marca)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(shelf.personalWrites, isEmpty);
    });

    testWidgets('não deve deixar escolher amanhã no seletor', (tester) async {
      await pumpPanel(tester, initial: watched());

      await tester.tap(find.text('10/11/2026 (dia da marca)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('19'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(
        shelf.personalWrites.single.value,
        WatchedOn(year: 2026, month: 11, day: 10),
      );
    });

    testWidgets('deve mostrar a recusa com "tentar de novo"', (tester) async {
      await pumpPanel(tester, initial: watched());
      await tester.tap(star(2));
      await tester.pump();

      shelf.personalWrites.single.fail(const NetworkFailure());
      await tester.pump();

      expect(find.text('Tentar de novo'), findsOneWidget);
    });

    testWidgets('deve repetir a escrita recusada', (tester) async {
      await pumpPanel(tester, initial: watched());
      await tester.tap(star(2));
      await tester.pump();
      shelf.personalWrites.single.fail(const NetworkFailure());
      await tester.pump();

      await tester.tap(find.text('Tentar de novo'));
      await tester.pump();

      expect(shelf.personalWrites.last.value, Rating(4));
    });

    testWidgets('deve caber com a fonte grande e o dia sugerido', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await pumpPanel(
        tester,
        initial: watched(rating: Rating(7)),
        textScaler: const TextScaler.linear(2),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('deve caber com a fonte grande', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await pumpPanel(
        tester,
        initial: watched(
          rating: Rating(7),
          watchedOn: WatchedOn(year: 2026, month: 11, day: 1),
        ),
        textScaler: const TextScaler.linear(2),
      );

      expect(tester.takeException(), isNull);
    });
  });

  // Testes de caracterização (decisão 020): o painel já passava na auditoria.
  group('acessibilidade num celular estreito', () {
    final states = <String, Future<void> Function(WidgetTester, TextScaler)>{
      'com a nota e o dia sugerido': (tester, textScaler) => pumpPanel(
        tester,
        initial: watched(rating: Rating(7)),
        textScaler: textScaler,
      ),
      'com a nota e o dia escolhido': (tester, textScaler) => pumpPanel(
        tester,
        initial: watched(
          rating: Rating(7),
          watchedOn: WatchedOn(year: 2026, month: 11, day: 8),
        ),
        textScaler: textScaler,
      ),
      'na recusa com o tentar de novo': (tester, textScaler) async {
        await pumpPanel(tester, initial: watched(), textScaler: textScaler);
        await tester.tap(star(2));
        await tester.pump();
        shelf.personalWrites.single.fail(const NetworkFailure());
        await tester.pump();
      },
    };
    final fonts = {'': TextScaler.noScaling, ' com a fonte 2x': largeFont};
    for (final MapEntry(key: state, value: reach) in states.entries) {
      for (final MapEntry(key: font, value: textScaler) in fonts.entries) {
        testWidgets('deve ser acessível $state$font', (tester) async {
          useNarrowPhone(tester);
          await reach(tester, textScaler);

          await expectAccessible(tester);
        });
      }
    }
    for (final MapEntry(key: font, value: textScaler) in fonts.entries) {
      // Exceção da decisão 020: o calendário do Material tem 7 colunas num
      // diálogo de largura fixa, e cada dia só chega a 48dp em telas a partir
      // de cerca de 392dp (37,7dp em 320dp).
      testWidgets('deve ser acessível no seletor do dia, menos no tamanho do '
          'dia$font', (tester) async {
        useNarrowPhone(tester);
        await pumpPanel(tester, initial: watched(), textScaler: textScaler);
        await tester.tap(find.text('10/11/2026 (dia da marca)'));
        await tester.pumpAndSettle();

        await expectAccessible(tester, except: {androidTapTargetGuideline});
      });
    }
  });
}

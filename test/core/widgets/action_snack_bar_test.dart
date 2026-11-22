import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/core/widgets/action_snack_bar.dart';

import '../../helpers/accessibility.dart';
import '../../helpers/test_app.dart';

void main() {
  var actions = 0;

  setUp(() => actions = 0);

  Future<void> pumpHost(WidgetTester tester) =>
      tester.pumpWidget(testApp(home: const Scaffold(body: SizedBox())));

  Future<ScaffoldFeatureController<SnackBar, SnackBarClosedReason>> show(
    WidgetTester tester, {
    String message = 'Filme tirado da lista.',
    String actionLabel = 'Desfazer',
  }) async {
    final controller = showActionSnackBar(
      messenger: ScaffoldMessenger.of(tester.element(find.byType(Scaffold))),
      message: message,
      actionLabel: actionLabel,
      onAction: () => actions++,
    );
    await tester.pumpAndSettle();
    return controller;
  }

  Future<void> showNotice(
    WidgetTester tester, {
    String message = 'Filme tirado da lista.',
    String actionLabel = 'Desfazer',
  }) async {
    await pumpHost(tester);
    await show(tester, message: message, actionLabel: actionLabel);
  }

  testWidgets('deve mostrar a mensagem', (tester) async {
    await showNotice(tester);

    expect(find.text('Filme tirado da lista.'), findsOneWidget);
  });

  testWidgets('deve rodar a ação ao tocar nela', (tester) async {
    await showNotice(tester);

    await tester.tap(find.text('Desfazer'));
    await tester.pump();

    expect(actions, 1);
  });

  testWidgets('deve fechar o aviso ao tocar na ação', (tester) async {
    await showNotice(tester);

    await tester.tap(find.text('Desfazer'));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('deve rodar a ação uma vez só com dois toques', (tester) async {
    await showNotice(tester);

    await tester.tap(find.text('Desfazer'));
    await tester.pump();
    await tester.tap(find.text('Desfazer'), warnIfMissed: false);
    await tester.pump();

    expect(actions, 1);
  });

  // Durante a saída, o botão desabilitado continua com a cor da ação, como o
  // `SnackBarAction`, e não pisca quase invisível sobre o fundo.
  testWidgets('deve manter a cor da ação enquanto o aviso sai', (tester) async {
    await showNotice(tester);

    await tester.tap(find.text('Desfazer'));
    await tester.pump();
    // O tempo da animação da cor do botão, antes de o aviso acabar de sair.
    await tester.pump(kThemeChangeDuration);

    final context = tester.element(find.text('Desfazer'));
    expect(
      DefaultTextStyle.of(context).style.color,
      Theme.of(context).colorScheme.inversePrimary,
    );
  });

  // O aviso com ação não some sozinho antes de quem usa leitor de tela
  // chegar até ela.
  testWidgets('deve ficar na tela até o toque', (tester) async {
    await showNotice(tester);

    await tester.pump(const Duration(minutes: 1));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
  });

  // Persistente, um aviso deixaria o seguinte preso na fila até o toque.
  testWidgets('deve trocar na hora o aviso anterior pelo novo', (tester) async {
    await showNotice(tester, message: 'Primeiro');

    await show(tester, message: 'Segundo');

    expect(
      [find.text('Primeiro'), find.text('Segundo')],
      [findsNothing, findsOneWidget],
    );
  });

  testWidgets('deve avisar quando outro aviso toma o lugar', (tester) async {
    await pumpHost(tester);
    final first = await show(tester, message: 'Primeiro');
    var replaced = false;
    first.closed.then((_) => replaced = true).ignore();

    await show(tester, message: 'Segundo');

    expect(replaced, isTrue);
  });

  testWidgets('deve ser acessível com a fonte 2x num celular estreito', (
    tester,
  ) async {
    useNarrowPhone(tester);
    useLargeFont(tester);

    await showNotice(
      tester,
      message: 'Sem conexão. Confira a internet.',
      actionLabel: 'Tentar de novo',
    );

    await expectAccessible(tester);
  });

  testWidgets('deve ser acessível com a fonte normal', (tester) async {
    useNarrowPhone(tester);

    await showNotice(tester);

    await expectAccessible(tester);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/core/widgets/action_snack_bar.dart';

import '../../helpers/accessibility.dart';
import '../../helpers/test_app.dart';

void main() {
  var actions = 0;

  setUp(() => actions = 0);

  Future<void> showNotice(
    WidgetTester tester, {
    String message = 'Filme tirado da lista.',
    String actionLabel = 'Desfazer',
  }) async {
    await tester.pumpWidget(
      testApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () {
                  final messenger = ScaffoldMessenger.of(context);
                  messenger.showSnackBar(
                    actionSnackBar(
                      messenger: messenger,
                      message: message,
                      actionLabel: actionLabel,
                      onAction: () => actions++,
                    ),
                  );
                },
                child: const Text('Mostrar'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Mostrar'));
    await tester.pumpAndSettle();
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

  // Como o `SnackBarAction` do Material: o aviso com ação só sai pelo toque
  // ou por outro aviso, e não some antes de quem usa leitor de tela chegar.
  testWidgets('deve ficar na tela até o toque', (tester) async {
    await showNotice(tester);

    await tester.pump(const Duration(minutes: 1));

    expect(find.byType(SnackBar), findsOneWidget);
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

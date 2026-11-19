import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/core/l10n/app_locale.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/list_name.dart';
import 'package:ja_vi_esse_filme/features/shelf/presentation/widgets/list_name_dialog.dart';
import 'package:ja_vi_esse_filme/l10n/app_localizations.dart';

import '../../../../helpers/test_app.dart';

void main() {
  final l10n = lookupAppLocalizations(AppLocale.locale);

  /// Abre o diálogo e devolve onde a resposta vai cair.
  Future<List<ListName?>> open(WidgetTester tester, {ListName? initial}) async {
    final answers = <ListName?>[];
    await tester.pumpWidget(
      testApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => answers.add(
              await ListNameDialog.show(context, initial: initial),
            ),
            child: const Text('abrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    return answers;
  }

  Finder action(String label) => find.widgetWithText(TextButton, label);

  bool isEnabled(WidgetTester tester, String label) =>
      tester.widget<TextButton>(action(label)).onPressed != null;

  testWidgets('deve mostrar o rótulo visível do campo', (tester) async {
    await open(tester);

    expect(find.text(l10n.listsNameLabel), findsOneWidget);
  });

  testWidgets('deve mostrar o contador zerado', (tester) async {
    await open(tester);

    expect(
      find.text(l10n.listsNameCounter(0, ListName.maxLength)),
      findsOneWidget,
    );
  });

  testWidgets('deve desabilitar o Criar com o nome vazio', (tester) async {
    await open(tester);

    expect(isEnabled(tester, l10n.listsCreate), isFalse);
  });

  testWidgets('deve devolver o nome ao criar', (tester) async {
    final answers = await open(tester);

    await tester.enterText(find.byType(TextField), '  Terror ');
    await tester.pump();
    await tester.tap(action(l10n.listsCreate));
    await tester.pumpAndSettle();

    expect(answers, [ListName('Terror')]);
  });

  testWidgets('deve criar com o Enter do teclado', (tester) async {
    final answers = await open(tester);

    await tester.enterText(find.byType(TextField), 'Terror');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(answers, [ListName('Terror')]);
  });

  testWidgets('não deve fechar com o Enter e o nome vazio', (tester) async {
    final answers = await open(tester);

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(answers, isEmpty);
  });

  testWidgets('deve contar o emoji como dois', (tester) async {
    await open(tester);

    await tester.enterText(find.byType(TextField), '😀');
    await tester.pump();

    expect(
      find.text(l10n.listsNameCounter(2, ListName.maxLength)),
      findsOneWidget,
    );
  });

  testWidgets('deve dizer o motivo do nome longo embaixo do campo', (
    tester,
  ) async {
    await open(tester);

    await tester.enterText(find.byType(TextField), '😀' * 26);
    await tester.pump();

    expect(
      find.text(l10n.listsNameTooLong(ListName.maxLength)),
      findsOneWidget,
    );
  });

  testWidgets('deve desabilitar o Criar com o nome longo', (tester) async {
    await open(tester);

    await tester.enterText(find.byType(TextField), 'a' * 51);
    await tester.pump();

    expect(isEnabled(tester, l10n.listsCreate), isFalse);
  });

  testWidgets('deve pedir um nome depois de apagar o que digitou', (
    tester,
  ) async {
    await open(tester);

    await tester.enterText(find.byType(TextField), 'a');
    await tester.pump();
    await tester.enterText(find.byType(TextField), '   ');
    await tester.pump();

    expect(find.text(l10n.listsNameEmpty), findsOneWidget);
  });

  testWidgets('não deve acusar erro antes de digitar', (tester) async {
    await open(tester);

    expect(find.text(l10n.listsNameEmpty), findsNothing);
  });

  // O campo de uma linha já troca a quebra de linha por espaço; o tab passa.
  testWidgets('deve recusar o tab colado', (tester) async {
    await open(tester);

    await tester.enterText(find.byType(TextField), 'Ter\tror');
    await tester.pump();

    expect(find.text(l10n.listsNameControl), findsOneWidget);
  });

  testWidgets('deve fechar sem nome no Cancelar', (tester) async {
    final answers = await open(tester);

    await tester.tap(action(l10n.listsCancel));
    await tester.pumpAndSettle();

    expect(answers, [null]);
  });

  testWidgets('deve renomear com o nome atual no campo', (tester) async {
    await open(tester, initial: ListName('Terror'));

    expect(find.widgetWithText(TextField, 'Terror'), findsOneWidget);
  });

  testWidgets('deve usar o título e a ação de renomear', (tester) async {
    await open(tester, initial: ListName('Terror'));

    expect([
      find.text(l10n.listsRenameTitle),
      action(l10n.listsSave),
    ], everyElement(findsOneWidget));
  });

  testWidgets('deve caber com a fonte grande', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await open(tester);

    expect(tester.takeException(), isNull);
  });
}

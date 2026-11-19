import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/core/l10n/app_locale.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/list_name.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/movie_list.dart';
import 'package:ja_vi_esse_filme/features/shelf/presentation/widgets/delete_list_dialog.dart';
import 'package:ja_vi_esse_filme/l10n/app_localizations.dart';

import '../../../../helpers/test_app.dart';

void main() {
  final l10n = lookupAppLocalizations(AppLocale.locale);
  final terror = MovieList(
    id: 'Lst0aBcDeFgHiJkLmNoP',
    name: ListName('Terror'),
  );

  Future<List<bool>> open(WidgetTester tester) async {
    final answers = <bool>[];
    await tester.pumpWidget(
      testApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async =>
                answers.add(await DeleteListDialog.confirm(context, terror)),
            child: const Text('abrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    return answers;
  }

  testWidgets('deve perguntar pelo nome da lista', (tester) async {
    await open(tester);

    expect(find.text(l10n.listsDeleteTitle('Terror')), findsOneWidget);
  });

  testWidgets('deve confirmar no Apagar', (tester) async {
    final answers = await open(tester);

    await tester.tap(find.text(l10n.listsDelete));
    await tester.pumpAndSettle();

    expect(answers, [true]);
  });

  testWidgets('não deve confirmar no Cancelar', (tester) async {
    final answers = await open(tester);

    await tester.tap(find.text(l10n.listsCancel));
    await tester.pumpAndSettle();

    expect(answers, [false]);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/core/widgets/placeholder_screen.dart';

import '../../helpers/test_app.dart';

Future<void> pumpPlaceholder(WidgetTester tester) =>
    tester.pumpWidget(testApp(home: const PlaceholderScreen(title: 'Buscar')));

void main() {
  testWidgets('deve mostrar o título na app bar', (tester) async {
    await pumpPlaceholder(tester);

    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('Buscar')),
      findsOneWidget,
    );
  });

  testWidgets('deve avisar que a tela chega em breve', (tester) async {
    await pumpPlaceholder(tester);

    expect(find.text('Em breve'), findsOneWidget);
  });
}

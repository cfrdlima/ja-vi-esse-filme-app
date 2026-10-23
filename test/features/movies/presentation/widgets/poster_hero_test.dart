import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/features/movies/presentation/widgets/poster_hero.dart';

import '../../../../helpers/test_app.dart';

void main() {
  Future<void> pumpHero(
    WidgetTester tester, {
    bool disableAnimations = false,
  }) => tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: testApp(home: const PosterHero(movieId: 7, child: Text('pôster'))),
    ),
  );

  testWidgets('deve envolver o pôster num Hero com a tag do filme', (
    tester,
  ) async {
    await pumpHero(tester);

    expect(tester.widget<Hero>(find.byType(Hero)).tag, 'poster-7');
  });

  testWidgets('deve mostrar o pôster dentro do Hero', (tester) async {
    await pumpHero(tester);

    expect(
      find.descendant(of: find.byType(Hero), matching: find.text('pôster')),
      findsOneWidget,
    );
  });

  testWidgets('não deve criar o Hero com o movimento reduzido', (tester) async {
    await pumpHero(tester, disableAnimations: true);

    expect(find.byType(Hero), findsNothing);
  });

  testWidgets('deve mostrar o pôster com o movimento reduzido', (tester) async {
    await pumpHero(tester, disableAnimations: true);

    expect(find.text('pôster'), findsOneWidget);
  });
}

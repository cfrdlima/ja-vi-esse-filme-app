import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/features/movies/presentation/widgets/movie_details_skeleton.dart';

import '../../../../helpers/accessibility.dart';
import '../../../../helpers/test_app.dart';

void main() {
  Future<double> firstLineHeight(WidgetTester tester) async {
    await tester.pumpWidget(
      testApp(home: const Scaffold(body: MovieDetailsSkeleton())),
    );
    final line = find.descendant(
      of: find.byType(FractionallySizedBox),
      matching: find.byType(Container),
    );
    return tester.getSize(line.first).height;
  }

  testWidgets('deve desenhar a linha com a altura da letra do corpo', (
    tester,
  ) async {
    final height = await firstLineHeight(tester);

    expect(height, 16);
  });

  // Revisão da sessão 011 (S6): com a altura fixa, o skeleton encolhia em
  // relação ao texto que chega no lugar dele.
  testWidgets('deve crescer a linha junto com a fonte grande', (tester) async {
    useLargeFont(tester);

    final height = await firstLineHeight(tester);

    expect(height, 32);
  });
}

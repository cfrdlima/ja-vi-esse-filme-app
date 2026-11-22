import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'accessibility.dart';
import 'test_app.dart';

/// A falha do [check], ou nulo se passou. Sem o `expectLater`, que é
/// guardado e entraria em conflito com o `pump` do ajudante.
Future<TestFailure?> _failureOf(Future<void> check) async {
  try {
    await check;
    return null;
  } on TestFailure catch (failure) {
    return failure;
  }
}

void main() {
  Widget button({double size = 48, String? label = 'Marcar'}) => testApp(
    home: Scaffold(
      body: Center(
        child: SizedBox.square(
          dimension: size,
          child: IconButton(
            tooltip: label,
            onPressed: () {},
            icon: const Icon(Icons.check),
          ),
        ),
      ),
    ),
  );

  group('useNarrowPhone', () {
    testWidgets('deve deixar a tela com 320dp de largura', (tester) async {
      useNarrowPhone(tester);
      await tester.pumpWidget(button());

      final width = tester.getSize(find.byType(Scaffold)).width;

      expect(width, 320);
    });
  });

  group('useLargeFont', () {
    testWidgets('deve dobrar a fonte do app', (tester) async {
      useLargeFont(tester);
      await tester.pumpWidget(button());

      final scaler = MediaQuery.textScalerOf(
        tester.element(find.byType(Scaffold)),
      );

      expect(scaler.scale(10), 20);
    });
  });

  group('expectAccessible', () {
    testWidgets('deve aceitar o alvo de 48dp com rótulo', (tester) async {
      await tester.pumpWidget(button());

      await expectAccessible(tester);
    });

    testWidgets('deve recusar o alvo menor que 48dp', (tester) async {
      await tester.pumpWidget(button(size: 40));

      final failure = await _failureOf(expectAccessible(tester));

      expect(failure, isA<TestFailure>());
    });

    testWidgets('deve aceitar o alvo pequeno com a guideline dispensada', (
      tester,
    ) async {
      await tester.pumpWidget(button(size: 40));

      final failure = await _failureOf(
        expectAccessible(tester, except: {androidTapTargetGuideline}),
      );

      expect(failure, isNull);
    });

    testWidgets('deve recusar o alvo sem rótulo', (tester) async {
      await tester.pumpWidget(button(label: null));

      final failure = await _failureOf(expectAccessible(tester));

      expect(failure, isA<TestFailure>());
    });

    testWidgets('deve recusar o texto sem contraste', (tester) async {
      await tester.pumpWidget(
        testApp(
          home: const Scaffold(
            backgroundColor: Colors.black,
            body: Text(
              'Quase invisível',
              style: TextStyle(color: Colors.black),
            ),
          ),
        ),
      );

      final failure = await _failureOf(expectAccessible(tester));

      expect(failure, isA<TestFailure>());
    });

    testWidgets('deve recusar o layout que vaza', (tester) async {
      useNarrowPhone(tester);
      await tester.pumpWidget(
        testApp(
          home: const Scaffold(
            body: Row(children: [SizedBox(width: 400, height: 10)]),
          ),
        ),
      );

      final failure = await _failureOf(expectAccessible(tester));

      expect(failure, isA<TestFailure>());
    });
  });
}

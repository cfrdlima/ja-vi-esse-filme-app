import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// A maior fonte das configurações do Android, o piso da decisão 020.
const largeFont = TextScaler.linear(2);

/// Celular estreito (320dp), onde o overflow horizontal aparece. O teste
/// padrão (800×600) o esconde.
void useNarrowPhone(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(960, 1920)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

/// Fonte em [largeFont] no app inteiro, para a tela que não monta um
/// `MediaQuery` próprio por cima do `MaterialApp`.
void useLargeFont(WidgetTester tester) {
  tester.platformDispatcher.textScaleFactorTestValue = largeFont.scale(1);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

/// Confere o layout sem vazar e as três guidelines do Flutter (decisão 020):
/// alvo de toque de 48dp, rótulo em todo alvo e contraste AA.
Future<void> expectAccessible(WidgetTester tester) async {
  expect(tester.takeException(), isNull, reason: 'o layout não pode vazar');
  final semantics = tester.ensureSemantics();
  await tester.pump();
  try {
    // `evaluate` + `fail`, e não `expectLater(meetsGuideline)`: o matcher
    // registra a falha direto no teste, e o próprio teste do ajudante não
    // conseguiria conferir que ele recusa.
    for (final guideline in _guidelines) {
      final evaluation = await guideline.evaluate(tester);
      if (!evaluation.passed) fail(evaluation.reason ?? guideline.description);
    }
  } finally {
    semantics.dispose();
  }
}

final _guidelines = <AccessibilityGuideline>[
  androidTapTargetGuideline,
  labeledTapTargetGuideline,
  textContrastGuideline,
];

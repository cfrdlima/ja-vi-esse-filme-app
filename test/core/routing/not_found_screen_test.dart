import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/core/routing/not_found_screen.dart';
import 'package:ja_vi_esse_filme/core/theme/app_theme.dart';

Future<void> pumpNotFound(
  WidgetTester tester, {
  required VoidCallback onGoHome,
}) => tester.pumpWidget(
  MaterialApp(
    theme: AppTheme.dark(),
    home: NotFoundScreen(onGoHome: onGoHome),
  ),
);

void main() {
  testWidgets('deve chamar onGoHome ao tocar em Ir para Descobrir', (
    tester,
  ) async {
    var calls = 0;
    await pumpNotFound(tester, onGoHome: () => calls++);

    await tester.tap(find.text('Ir para Descobrir'));

    expect(calls, 1);
  });

  testWidgets('deve rolar em vez de vazar com fonte 2x numa tela baixa', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pumpNotFound(tester, onGoHome: () {});

    expect(tester.takeException(), isNull);
  });
}

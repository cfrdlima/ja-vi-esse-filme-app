import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/core/theme/app_theme_tokens.dart';
import 'package:ja_vi_esse_filme/main.dart';

void main() {
  testWidgets('o app deve usar o tema escuro do design system', (tester) async {
    await tester.pumpWidget(const MainApp());

    final context = tester.element(find.byType(Scaffold));
    expect(Theme.of(context).extension<AppThemeTokens>(), AppThemeTokens.dark);
  });

  testWidgets('o app deve ficar no modo escuro mesmo com o sistema claro', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await tester.pumpWidget(const MainApp());

    final context = tester.element(find.byType(Scaffold));
    expect(Theme.of(context).brightness, Brightness.dark);
  });
}

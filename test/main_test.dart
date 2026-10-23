import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/core/theme/app_theme_tokens.dart';
import 'package:ja_vi_esse_filme/main.dart';

import 'helpers/stub_movie_repository.dart';

void main() {
  testWidgets('o app deve usar o tema escuro do design system', (tester) async {
    await tester.pumpWidget(MainApp(movieRepository: StubMovieRepository()));

    final context = tester.element(find.byType(Scaffold).first);
    expect(Theme.of(context).extension<AppThemeTokens>(), AppThemeTokens.dark);
  });

  testWidgets('o app deve ficar no modo escuro mesmo com o sistema claro', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await tester.pumpWidget(MainApp(movieRepository: StubMovieRepository()));

    final context = tester.element(find.byType(Scaffold).first);
    expect(Theme.of(context).brightness, Brightness.dark);
  });

  testWidgets('o app deve usar o locale pt_BR', (tester) async {
    await tester.pumpWidget(MainApp(movieRepository: StubMovieRepository()));

    final context = tester.element(find.byType(Scaffold).first);
    expect(Localizations.localeOf(context), const Locale('pt', 'BR'));
  });

  testWidgets('os textos do Material devem sair em português', (tester) async {
    await tester.pumpWidget(MainApp(movieRepository: StubMovieRepository()));

    final context = tester.element(find.byType(Scaffold).first);
    expect(MaterialLocalizations.of(context).backButtonTooltip, 'Voltar');
  });

  testWidgets('o app deve abrir no shell de navegação', (tester) async {
    await tester.pumpWidget(MainApp(movieRepository: StubMovieRepository()));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
  });
}

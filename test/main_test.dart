import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/core/links/external_link_opener.dart';
import 'package:ja_vi_esse_filme/core/theme/app_theme_tokens.dart';
import 'package:ja_vi_esse_filme/main.dart';
import 'package:provider/provider.dart';

import 'helpers/fake_link_opener.dart';
import 'helpers/stub_movie_repository.dart';

void main() {
  MainApp app({ExternalLinkOpener? linkOpener, String appVersion = ''}) =>
      MainApp(
        movieRepository: StubMovieRepository(),
        linkOpener: linkOpener ?? FakeLinkOpener(),
        appVersion: appVersion,
      );

  testWidgets('o app deve usar o tema escuro do design system', (tester) async {
    await tester.pumpWidget(app());

    final context = tester.element(find.byType(Scaffold).first);
    expect(Theme.of(context).extension<AppThemeTokens>(), AppThemeTokens.dark);
  });

  testWidgets('o app deve ficar no modo escuro mesmo com o sistema claro', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await tester.pumpWidget(app());

    final context = tester.element(find.byType(Scaffold).first);
    expect(Theme.of(context).brightness, Brightness.dark);
  });

  testWidgets('o app deve usar o locale pt_BR', (tester) async {
    await tester.pumpWidget(app());

    final context = tester.element(find.byType(Scaffold).first);
    expect(Localizations.localeOf(context), const Locale('pt', 'BR'));
  });

  testWidgets('os textos do Material devem sair em português', (tester) async {
    await tester.pumpWidget(app());

    final context = tester.element(find.byType(Scaffold).first);
    expect(MaterialLocalizations.of(context).backButtonTooltip, 'Voltar');
  });

  testWidgets('o app deve abrir no shell de navegação', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('as telas devem receber o abridor de links do app', (
    tester,
  ) async {
    final opener = FakeLinkOpener();
    await tester.pumpWidget(app(linkOpener: opener));

    final context = tester.element(find.byType(Scaffold).first);
    expect(context.read<ExternalLinkOpener>(), same(opener));
  });

  testWidgets('o Sobre deve mostrar a versão recebida pelo app', (
    tester,
  ) async {
    await tester.pumpWidget(app(appVersion: '9.9.9'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sobre o app'));
    await tester.pumpAndSettle();

    expect(find.text('Versão 9.9.9'), findsOneWidget);
  });
}

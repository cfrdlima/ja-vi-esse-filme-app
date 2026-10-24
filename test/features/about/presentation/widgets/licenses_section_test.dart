import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/core/l10n/app_locale.dart';
import 'package:ja_vi_esse_filme/core/licenses/font_licenses.dart';
import 'package:ja_vi_esse_filme/features/about/presentation/widgets/licenses_section.dart';
import 'package:ja_vi_esse_filme/l10n/app_localizations.dart';

import '../../../../helpers/test_app.dart';

void main() {
  final l10n = lookupAppLocalizations(AppLocale.locale);

  setUp(LicenseRegistry.reset);
  tearDown(LicenseRegistry.reset);

  Widget section({String appVersion = '1.2.3'}) => testApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: LicensesSection(appVersion: appVersion),
      ),
    ),
  );

  Future<void> openLicenses(WidgetTester tester) async {
    await tester.tap(find.text(l10n.aboutLicensesEntry));
    // A página de licenças lê o registro fora do quadro; o `runAsync` deixa
    // esse trabalho terminar antes de conferir a lista.
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
  }

  testWidgets('deve marcar o título da seção como cabeçalho', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(section());

    expect(
      tester.getSemantics(find.text(l10n.aboutLicensesTitle)),
      matchesSemantics(label: l10n.aboutLicensesTitle, isHeader: true),
    );
    semantics.dispose();
  });

  testWidgets('deve anunciar a entrada de licenças como botão', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(section());

    expect(
      tester.getSemantics(find.byType(ListTile)),
      matchesSemantics(
        label: l10n.aboutLicensesEntry,
        isButton: true,
        hasTapAction: true,
        hasEnabledState: true,
        isEnabled: true,
        isFocusable: true,
        hasFocusAction: true,
        // O `ListTile` sempre expõe o estado de seleção, aqui desmarcado.
        hasSelectedState: true,
      ),
    );
    semantics.dispose();
  });

  testWidgets('deve ter alvo de toque de pelo menos 48dp', (tester) async {
    await tester.pumpWidget(section());

    expect(
      tester.getSize(find.byType(ListTile)).height,
      greaterThanOrEqualTo(48),
    );
  });

  testWidgets('deve abrir a página de licenças ao tocar', (tester) async {
    await tester.pumpWidget(section());

    await openLicenses(tester);

    expect(find.byType(LicensePage), findsOneWidget);
  });

  testWidgets('deve mostrar o nome e a versão do app nas licenças', (
    tester,
  ) async {
    await tester.pumpWidget(section());

    await openLicenses(tester);

    expect(
      (
        find.text(l10n.appName).evaluate().length,
        find.text('1.2.3').evaluate().length,
      ),
      (1, 1),
    );
  });

  testWidgets('deve listar as fontes do app nas licenças', (tester) async {
    registerFontLicenses();
    await tester.pumpWidget(section());

    await openLicenses(tester);

    expect(
      (
        find.text('Inter').evaluate().length,
        find.text('Playfair Display').evaluate().length,
      ),
      (1, 1),
    );
  });
}

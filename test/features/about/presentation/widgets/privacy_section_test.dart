import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/core/l10n/app_locale.dart';
import 'package:ja_vi_esse_filme/core/links/app_links.dart';
import 'package:ja_vi_esse_filme/core/links/external_link_opener.dart';
import 'package:ja_vi_esse_filme/features/about/presentation/widgets/privacy_section.dart';
import 'package:ja_vi_esse_filme/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/fake_link_opener.dart';
import '../../../../helpers/test_app.dart';

void main() {
  final l10n = lookupAppLocalizations(AppLocale.locale);

  Widget section(
    FakeLinkOpener opener, {
    TextScaler textScaler = TextScaler.noScaling,
  }) => MediaQuery(
    data: MediaQueryData(textScaler: textScaler),
    child: Provider<ExternalLinkOpener>.value(
      value: opener,
      child: testApp(
        home: const Scaffold(
          body: SingleChildScrollView(child: PrivacySection()),
        ),
      ),
    ),
  );

  Finder policyLink() => find.byKey(PrivacySection.policyLinkKey);

  testWidgets('deve marcar o título da seção como cabeçalho', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(section(FakeLinkOpener()));

    expect(
      tester.getSemantics(find.text(l10n.aboutPrivacyTitle)),
      matchesSemantics(label: l10n.aboutPrivacyTitle, isHeader: true),
    );
    semantics.dispose();
  });

  testWidgets('deve mostrar o resumo da política', (tester) async {
    await tester.pumpWidget(section(FakeLinkOpener()));

    expect(find.text(l10n.aboutPrivacySummary), findsOneWidget);
  });

  testWidgets('deve abrir a política publicada ao tocar no link', (
    tester,
  ) async {
    final opener = FakeLinkOpener();
    await tester.pumpWidget(section(opener));

    await tester.tap(find.text(l10n.aboutPrivacyPolicyLink));
    await tester.pump();

    expect(opener.opened, [AppLinks.privacyPolicy]);
  });

  testWidgets('deve abrir a política pelo toque do leitor de tela', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final opener = FakeLinkOpener();
    await tester.pumpWidget(section(opener));

    tester.semantics.tap(
      find.semantics.byLabel(l10n.aboutPrivacyPolicySemantics),
    );
    await tester.pump();

    expect(opener.opened, [AppLinks.privacyPolicy]);
    semantics.dispose();
  });

  testWidgets('deve avisar quando nenhum app abre a política', (tester) async {
    final opener = FakeLinkOpener(
      failure: const LinkNotOpened(LinkNotOpenedReason.noApp),
    );
    await tester.pumpWidget(section(opener));

    await tester.tap(find.text(l10n.aboutPrivacyPolicyLink));
    await tester.pump();

    expect(find.text(l10n.aboutPrivacyPolicyOpenFailed), findsOneWidget);
  });

  testWidgets('deve ler a política como link que sai do app', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(section(FakeLinkOpener()));

    expect(
      tester.getSemantics(policyLink()),
      matchesSemantics(
        label: l10n.aboutPrivacyPolicySemantics,
        isLink: true,
        hasTapAction: true,
      ),
    );
    semantics.dispose();
  });

  testWidgets('deve ter alvo de toque de pelo menos 48dp', (tester) async {
    await tester.pumpWidget(section(FakeLinkOpener()));

    expect(tester.getSize(policyLink()).height, greaterThanOrEqualTo(48));
  });

  testWidgets('deve caber com fonte 2x sem overflow', (tester) async {
    await tester.pumpWidget(
      section(FakeLinkOpener(), textScaler: const TextScaler.linear(2)),
    );

    expect(tester.takeException(), isNull);
  });
}

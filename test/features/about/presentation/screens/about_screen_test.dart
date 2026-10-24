import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/core/assets/app_assets.dart';
import 'package:ja_vi_esse_filme/core/l10n/app_locale.dart';
import 'package:ja_vi_esse_filme/core/theme/app_sizes.dart';
import 'package:ja_vi_esse_filme/features/about/presentation/screens/about_screen.dart';
import 'package:ja_vi_esse_filme/features/about/presentation/widgets/licenses_section.dart';
import 'package:ja_vi_esse_filme/features/about/presentation/widgets/privacy_section.dart';
import 'package:ja_vi_esse_filme/l10n/app_localizations.dart';

import '../../../../helpers/test_app.dart';

void main() {
  final l10n = lookupAppLocalizations(AppLocale.locale);
  const tmdbNoticeOriginal =
      'This application uses TMDB and the TMDB APIs but is not endorsed, '
      'certified, or otherwise approved by TMDB.';

  Future<void> pumpAbout(
    WidgetTester tester, {
    String appVersion = '1.2.3',
    TextScaler textScaler = TextScaler.noScaling,
  }) async {
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(textScaler: textScaler),
        child: testApp(home: AboutScreen(appVersion: appVersion)),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('identidade do app', () {
    testWidgets('deve mostrar o nome do app', (tester) async {
      await pumpAbout(tester);

      expect(find.text(l10n.appName), findsOneWidget);
    });

    testWidgets('deve mostrar a versão do app', (tester) async {
      await pumpAbout(tester);

      expect(find.text(l10n.aboutVersion('1.2.3')), findsOneWidget);
    });

    testWidgets('deve esconder a versão quando o build não a informa', (
      tester,
    ) async {
      await pumpAbout(tester, appVersion: '');

      expect(find.textContaining(l10n.aboutVersion('')), findsNothing);
    });
  });

  group('atribuição ao TMDB', () {
    testWidgets('deve marcar a seção do TMDB como cabeçalho', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpAbout(tester);

      expect(
        tester.getSemantics(find.text(l10n.aboutTmdbTitle)),
        matchesSemantics(label: l10n.aboutTmdbTitle, isHeader: true),
      );
      semantics.dispose();
    });

    testWidgets('deve mostrar o logo do TMDB com texto alternativo', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpAbout(tester);

      expect(
        find.bySemanticsLabel(l10n.aboutTmdbLogoSemantics),
        findsOneWidget,
      );
      semantics.dispose();
    });

    testWidgets('deve desenhar o logo com a largura do design', (tester) async {
      await pumpAbout(tester);

      expect(tester.getSize(find.byType(Image)).width, AppSizes.tmdbLogoWidth);
    });

    testWidgets('deve desenhar o logo a partir do asset do TMDB', (
      tester,
    ) async {
      await pumpAbout(tester);

      final image = tester.widget<Image>(find.byType(Image)).image;
      expect((image as AssetImage).assetName, AppAssets.tmdbLogo);
    });

    testWidgets('deve reservar a altura do logo antes de a imagem carregar', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(home: const AboutScreen(appVersion: '1.2.3')),
      );

      expect(
        tester.getSize(find.byType(Image)).height,
        closeTo(AppSizes.tmdbLogoWidth / AppSizes.tmdbLogoAspectRatio, 0.01),
      );
    });

    testWidgets('deve mostrar o nome TMDB quando o logo não carrega', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(
          home: DefaultAssetBundle(
            bundle: _FailingAssetBundle(),
            child: const AboutScreen(appVersion: '1.2.3'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('TMDB'), findsOneWidget);
    });

    testWidgets('deve mostrar o aviso de não endosso em português', (
      tester,
    ) async {
      await pumpAbout(tester);

      expect(find.text(l10n.aboutTmdbNotice), findsOneWidget);
    });

    testWidgets('deve mostrar o aviso original dos termos do TMDB', (
      tester,
    ) async {
      await pumpAbout(tester);

      expect(find.text(tmdbNoticeOriginal), findsOneWidget);
    });

    testWidgets('deve ler o aviso original em inglês no leitor de tela', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpAbout(tester);

      final label = tester
          .getSemantics(find.bySemanticsLabel(tmdbNoticeOriginal))
          .attributedLabel;
      expect(
        label.attributes.whereType<LocaleStringAttribute>().single.locale,
        const Locale('en'),
      );
      semantics.dispose();
    });
  });

  testWidgets('deve mostrar a seção de privacidade depois do TMDB', (
    tester,
  ) async {
    await pumpAbout(tester);

    expect(
      tester.getTopLeft(find.byType(PrivacySection)).dy,
      greaterThan(tester.getTopLeft(find.text(l10n.aboutTmdbNotice)).dy),
    );
  });

  testWidgets('deve mostrar a seção de licenças depois da privacidade', (
    tester,
  ) async {
    await pumpAbout(tester);

    expect(
      tester.getTopLeft(find.byType(LicensesSection)).dy,
      greaterThan(tester.getTopLeft(find.byType(PrivacySection)).dy),
    );
  });

  group('acessibilidade', () {
    testWidgets('deve ter contraste AA nos textos', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpAbout(tester);

      await expectLater(tester, meetsGuideline(textContrastGuideline));
      semantics.dispose();
    });

    testWidgets('deve caber com fonte 2x sem overflow', (tester) async {
      await pumpAbout(tester, textScaler: const TextScaler.linear(2));

      expect(tester.takeException(), isNull);
    });
  });
}

/// Bundle que falha em todo asset, como um PNG fora do `pubspec.yaml`.
class _FailingAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) =>
      Future.error(FlutterError('asset ausente: $key'));
}

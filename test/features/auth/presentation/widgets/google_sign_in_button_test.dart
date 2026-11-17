import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/core/l10n/app_locale.dart';
import 'package:ja_vi_esse_filme/features/auth/presentation/widgets/google_sign_in_button.dart';
import 'package:ja_vi_esse_filme/l10n/app_localizations.dart';

import '../../../../helpers/test_app.dart';

void main() {
  final l10n = lookupAppLocalizations(AppLocale.locale);

  Future<void> pumpButton(WidgetTester tester, Widget button) =>
      tester.pumpWidget(
        testApp(
          home: Scaffold(body: Center(child: button)),
        ),
      );

  testWidgets('deve chamar o onPressed ao tocar em Entrar com o Google', (
    tester,
  ) async {
    var taps = 0;
    await pumpButton(tester, GoogleSignInButton(onPressed: () => taps++));

    await tester.tap(find.text(l10n.signInWithGoogle));

    expect(taps, 1);
  });

  testWidgets('deve mostrar o G oficial do Google', (tester) async {
    await pumpButton(tester, GoogleSignInButton(onPressed: () {}));

    expect(
      find.image(const AssetImage('assets/images/google_g_logo.png')),
      findsOneWidget,
    );
  });

  group('acessibilidade', () {
    testWidgets('deve ser lido como o botão Entrar com o Google', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpButton(tester, GoogleSignInButton(onPressed: () {}));

      expect(find.bySemanticsLabel(l10n.signInWithGoogle), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('deve ter alvo de toque de 48dp', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpButton(tester, GoogleSignInButton(onPressed: () {}));

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      semantics.dispose();
    });

    testWidgets('deve ter contraste AA no texto', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpButton(tester, GoogleSignInButton(onPressed: () {}));

      await expectLater(tester, meetsGuideline(textContrastGuideline));
      semantics.dispose();
    });

    testWidgets('deve caber com fonte 2x numa tela estreita', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: testApp(
            home: Scaffold(
              body: Center(child: GoogleSignInButton(onPressed: () {})),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('entrando', () {
    testWidgets('deve trocar o G pelo indicador de progresso', (tester) async {
      await pumpButton(tester, const GoogleSignInButton.loading());

      expect(
        find.image(const AssetImage('assets/images/google_g_logo.png')),
        findsNothing,
      );
    });

    testWidgets('deve mostrar o indicador de progresso', (tester) async {
      await pumpButton(tester, const GoogleSignInButton.loading());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('deve ser lido como Entrando com o Google', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpButton(tester, const GoogleSignInButton.loading());

      expect(find.bySemanticsLabel(l10n.signingInWithGoogle), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('deve ficar desabilitado', (tester) async {
      await pumpButton(tester, const GoogleSignInButton.loading());

      expect(
        tester.widget<OutlinedButton>(find.byType(OutlinedButton)).enabled,
        isFalse,
      );
    });
  });
}

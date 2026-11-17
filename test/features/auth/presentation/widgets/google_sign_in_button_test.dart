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
}

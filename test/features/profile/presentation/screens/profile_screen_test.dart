import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/core/l10n/app_locale.dart';
import 'package:ja_vi_esse_filme/features/auth/domain/entities/auth_state.dart';
import 'package:ja_vi_esse_filme/features/auth/presentation/state/session_notifier.dart';
import 'package:ja_vi_esse_filme/features/profile/presentation/screens/profile_screen.dart';
import 'package:ja_vi_esse_filme/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/fake_auth_repository.dart';
import '../../../../helpers/test_app.dart';

void main() {
  final l10n = lookupAppLocalizations(AppLocale.locale);

  late FakeAuthRepository repository;

  setUp(() => repository = FakeAuthRepository());

  tearDown(() => repository.close());

  Future<void> pumpProfile(
    WidgetTester tester, {
    TextScaler textScaler = TextScaler.noScaling,
  }) => tester.pumpWidget(
    ChangeNotifierProvider(
      create: (_) => SessionNotifier(repository: repository),
      child: MediaQuery(
        data: MediaQueryData(textScaler: textScaler),
        child: testApp(home: const ProfileScreen()),
      ),
    ),
  );

  testWidgets('deve mostrar o título Perfil', (tester) async {
    await pumpProfile(tester);

    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('Perfil')),
      findsOneWidget,
    );
  });

  testWidgets('deve mostrar a entrada Sobre o app', (tester) async {
    await pumpProfile(tester);

    expect(find.text(l10n.profileAboutEntry), findsOneWidget);
  });

  testWidgets('deve anunciar a entrada Sobre o app como botão', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpProfile(tester);

    expect(
      tester.getSemantics(find.byType(ListTile)),
      matchesSemantics(
        label: l10n.profileAboutEntry,
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

  testWidgets('deve ter alvo de toque de 48dp', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpProfile(tester);

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    semantics.dispose();
  });

  testWidgets('deve ter contraste AA nos textos', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpProfile(tester);

    await expectLater(tester, meetsGuideline(textContrastGuideline));
    semantics.dispose();
  });

  testWidgets('deve caber com fonte 2x sem overflow', (tester) async {
    await pumpProfile(tester, textScaler: const TextScaler.linear(2));

    expect(tester.takeException(), isNull);
  });

  group('carregando', () {
    testWidgets('deve anunciar que a conta está carregando', (tester) async {
      await pumpProfile(tester);

      expect(find.bySemanticsLabel(l10n.profileAccountLoading), findsOneWidget);
    });
  });

  group('deslogado', () {
    setUp(() => repository.emit(const SignedOut()));

    testWidgets('deve convidar a entrar para guardar os filmes', (
      tester,
    ) async {
      await pumpProfile(tester);
      await tester.pump();

      expect(find.text(l10n.profileSignedOutTitle), findsOneWidget);
    });

    testWidgets('deve dizer o que a conta guarda', (tester) async {
      await pumpProfile(tester);
      await tester.pump();

      expect(find.text(l10n.profileSignedOutBody), findsOneWidget);
    });

    testWidgets('deve pedir o login ao tocar em Entrar com o Google', (
      tester,
    ) async {
      await pumpProfile(tester);
      await tester.pump();

      await tester.tap(find.text(l10n.signInWithGoogle));

      expect(repository.pendingSignIns, 1);
    });
  });
}

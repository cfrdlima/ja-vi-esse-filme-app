import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/core/error/failures.dart';
import 'package:ja_vi_esse_filme/core/l10n/app_locale.dart';
import 'package:ja_vi_esse_filme/core/widgets/retry_button.dart';
import 'package:ja_vi_esse_filme/features/auth/domain/entities/app_user.dart';
import 'package:ja_vi_esse_filme/features/auth/domain/entities/auth_state.dart';
import 'package:ja_vi_esse_filme/features/auth/presentation/state/session_notifier.dart';
import 'package:ja_vi_esse_filme/features/profile/presentation/screens/profile_screen.dart';
import 'package:ja_vi_esse_filme/features/profile/presentation/widgets/account_avatar.dart';
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

  group('entrando', () {
    setUp(() => repository.emit(const SignedOut()));

    testWidgets('deve mostrar o botão do Google entrando', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpProfile(tester);
      await tester.pump();

      await tester.tap(find.text(l10n.signInWithGoogle));
      await tester.pump();

      expect(find.bySemanticsLabel(l10n.signingInWithGoogle), findsOneWidget);
      semantics.dispose();
    });
  });

  group('falha no login', () {
    Future<void> pumpFailedSignIn(WidgetTester tester) async {
      repository.emit(const SignedOut());
      await pumpProfile(tester);
      await tester.pump();
      await tester.tap(find.text(l10n.signInWithGoogle));
      repository.failSignIn(const NetworkFailure());
      await tester.pump();
    }

    testWidgets('deve mostrar a mensagem da falha', (tester) async {
      await pumpFailedSignIn(tester);

      expect(find.text(l10n.failureNetwork), findsOneWidget);
    });

    testWidgets('deve tentar de novo pelo botão do Google', (tester) async {
      await pumpFailedSignIn(tester);

      await tester.tap(find.text(l10n.signInWithGoogle));

      expect(repository.pendingSignIns, 1);
    });
  });

  group('logado', () {
    final ana = AppUser(
      uid: 'abc123',
      displayName: 'Ana Souza',
      email: 'ana@example.com',
    );

    Future<void> pumpSignedIn(WidgetTester tester, AppUser user) async {
      repository.emit(SignedIn(user));
      await pumpProfile(tester);
      await tester.pump();
    }

    testWidgets('deve mostrar o nome da conta', (tester) async {
      await pumpSignedIn(tester, ana);

      expect(find.text('Ana Souza'), findsOneWidget);
    });

    testWidgets('deve mostrar Sua conta quando a conta não tem nome', (
      tester,
    ) async {
      await pumpSignedIn(tester, AppUser(uid: 'abc123'));

      expect(find.text(l10n.profileUnnamedAccount), findsOneWidget);
    });

    testWidgets('deve mostrar o avatar da conta', (tester) async {
      await pumpSignedIn(tester, ana);

      expect(find.byType(AccountAvatar), findsOneWidget);
    });

    testWidgets('deve mostrar o e-mail da conta', (tester) async {
      await pumpSignedIn(tester, ana);

      expect(find.text('ana@example.com'), findsOneWidget);
    });

    testWidgets('deve pedir o logout ao tocar em Sair', (tester) async {
      await pumpSignedIn(tester, ana);

      await tester.tap(find.text(l10n.profileSignOut));

      expect(repository.signOutCalls, 1);
    });
  });

  group('falha no logout', () {
    Future<void> pumpFailedSignOut(WidgetTester tester) async {
      repository
        ..emit(SignedIn(AppUser(uid: 'abc123', displayName: 'Ana')))
        ..signOutError = const NetworkFailure();
      await pumpProfile(tester);
      await tester.pump();
      await tester.tap(find.text(l10n.profileSignOut));
      await tester.pump();
    }

    testWidgets('deve mostrar a mensagem da falha', (tester) async {
      await pumpFailedSignOut(tester);

      expect(find.text(l10n.failureNetwork), findsOneWidget);
    });

    testWidgets('deve tentar sair de novo', (tester) async {
      await pumpFailedSignOut(tester);

      await tester.tap(find.byType(RetryButton));

      expect(repository.signOutCalls, 2);
    });
  });

  group('em todos os estados', () {
    final ana = AppUser(
      uid: 'abc123',
      displayName: 'Ana Carolina de Souza Albuquerque',
      email: 'ana.carolina.albuquerque@example.com',
    );

    // Com fonte 2x, o botão pode ficar abaixo da dobra.
    Future<void> tapVisible(WidgetTester tester, Finder finder) async {
      await tester.ensureVisible(finder);
      await tester.pump();
      await tester.tap(finder);
    }

    // Cada um leva a tela a um estado da sessão, depois do pumpProfile.
    final states = <String, Future<void> Function(WidgetTester)>{
      'carregando': (_) async {},
      'deslogado': (tester) async {
        repository.emit(const SignedOut());
        await tester.pump();
      },
      'entrando': (tester) async {
        repository.emit(const SignedOut());
        await tester.pump();
        await tapVisible(tester, find.text(l10n.signInWithGoogle));
        await tester.pump();
      },
      'falha no login': (tester) async {
        repository.emit(const SignedOut());
        await tester.pump();
        await tapVisible(tester, find.text(l10n.signInWithGoogle));
        repository.failSignIn(const NetworkFailure());
        await tester.pump();
      },
      'logado': (tester) async {
        repository.emit(SignedIn(ana));
        await tester.pump();
      },
      'falha no logout': (tester) async {
        repository
          ..emit(SignedIn(ana))
          ..signOutError = const NetworkFailure();
        await tester.pump();
        await tapVisible(tester, find.text(l10n.profileSignOut));
        await tester.pump();
      },
    };

    for (final MapEntry(key: name, value: reach) in states.entries) {
      group(name, () {
        testWidgets('deve mostrar a entrada Sobre o app', (tester) async {
          await pumpProfile(tester);
          await reach(tester);

          expect(find.text(l10n.profileAboutEntry), findsOneWidget);
        });

        testWidgets('deve caber com fonte 2x numa tela de celular', (
          tester,
        ) async {
          tester.view.physicalSize = const Size(360, 640);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await pumpProfile(tester, textScaler: const TextScaler.linear(2));
          await reach(tester);

          expect(tester.takeException(), isNull);
        });

        testWidgets('deve ter alvo de toque de 48dp', (tester) async {
          final semantics = tester.ensureSemantics();
          await pumpProfile(tester);
          await reach(tester);

          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          semantics.dispose();
        });

        testWidgets('deve ter contraste AA nos textos', (tester) async {
          final semantics = tester.ensureSemantics();
          await pumpProfile(tester);
          await reach(tester);

          await expectLater(tester, meetsGuideline(textContrastGuideline));
          semantics.dispose();
        });
      });
    }
  });
}

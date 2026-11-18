import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/core/error/failures.dart';
import 'package:ja_vi_esse_filme/core/l10n/app_locale.dart';
import 'package:ja_vi_esse_filme/core/widgets/retry_button.dart';
import 'package:ja_vi_esse_filme/features/auth/domain/entities/account_deletion_outcome.dart';
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
    bool disableAnimations = false,
  }) => tester.pumpWidget(
    ChangeNotifierProvider(
      create: (_) => SessionNotifier(repository: repository),
      child: MediaQuery(
        data: MediaQueryData(
          textScaler: textScaler,
          disableAnimations: disableAnimations,
        ),
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
      // Espera a transição do carregando: no começo do fade, o bloco ainda
      // está fora da árvore semântica.
      await tester.pumpAndSettle();

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
      await tester.pump();

      expect(repository.signOutCalls, 1);
    });
  });

  group('marcas sem sincronizar', () {
    final ana = AppUser(uid: 'abc123', displayName: 'Ana');

    Future<void> tapSignOut(WidgetTester tester) async {
      repository.emit(SignedIn(ana));
      await pumpProfile(tester);
      // Até o fim da troca vinda do "carregando", que ainda está na árvore.
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.profileSignOut));
      await tester.pump();
    }

    testWidgets('deve mostrar Saindo enquanto espera o servidor', (
      tester,
    ) async {
      repository.syncGate = Completer<void>();
      addTearDown(() => repository.syncGate?.complete());

      await tapSignOut(tester);

      expect(find.text(l10n.profileSigningOut), findsOneWidget);
    });

    testWidgets('deve desabilitar o botão enquanto espera o servidor', (
      tester,
    ) async {
      repository.syncGate = Completer<void>();
      addTearDown(() => repository.syncGate?.complete());

      await tapSignOut(tester);

      expect(
        tester
            .widget<OutlinedButton>(
              find.ancestor(
                of: find.text(l10n.profileSigningOut),
                matching: find.byWidgetPredicate((w) => w is OutlinedButton),
              ),
            )
            .onPressed,
        isNull,
      );
    });

    testWidgets('deve avisar que sair apaga as marcas', (tester) async {
      repository.synced = false;

      await tapSignOut(tester);

      expect(find.text(l10n.profileUnsyncedWarning), findsOneWidget);
    });

    testWidgets('deve anunciar o aviso ao leitor de tela', (tester) async {
      final semantics = tester.ensureSemantics();
      repository.synced = false;

      await tapSignOut(tester);

      expect(
        tester.getSemantics(find.text(l10n.profileUnsyncedWarning)),
        matchesSemantics(
          label: l10n.profileUnsyncedWarning,
          isLiveRegion: true,
        ),
      );
      semantics.dispose();
    });

    testWidgets('não deve sair antes de confirmar', (tester) async {
      repository.synced = false;

      await tapSignOut(tester);

      expect(repository.signOutCalls, 0);
    });

    testWidgets('deve sair ao tocar em Sair mesmo assim', (tester) async {
      repository.synced = false;
      await tapSignOut(tester);

      await tester.tap(find.text(l10n.profileSignOutAnyway));
      await tester.pump();

      expect(repository.signOutCalls, 1);
    });

    testWidgets('deve voltar à conta ao tocar em Ficar na conta', (
      tester,
    ) async {
      repository.synced = false;
      await tapSignOut(tester);

      await tester.tap(find.text(l10n.profileStaySignedIn));
      await tester.pump();

      expect(find.text(l10n.profileSignOut), findsOneWidget);
    });

    testWidgets('deve continuar mostrando a conta durante o aviso', (
      tester,
    ) async {
      repository.synced = false;

      await tapSignOut(tester);

      expect(find.text('Ana'), findsOneWidget);
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

  group('excluir a conta', () {
    final ana = AppUser(uid: 'abc123', displayName: 'Ana Souza');

    Future<void> pumpSignedIn(WidgetTester tester) async {
      repository.emit(SignedIn(ana));
      await pumpProfile(tester);
      await tester.pump();
    }

    // O Excluir conta fica no fim da lista, que pode passar da tela.
    Future<void> tapDeleteEntry(WidgetTester tester) async {
      final entry = find.widgetWithText(TextButton, l10n.profileDeleteAccount);
      await tester.ensureVisible(entry);
      await tester.pumpAndSettle();
      await tester.tap(entry);
      await tester.pumpAndSettle();
    }

    Future<void> confirm(WidgetTester tester) async {
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text(l10n.profileDeleteAccount),
        ),
      );
      // O spinner do "Excluindo" gira sem parar, e o `pumpAndSettle` não
      // terminaria: só o tempo de o diálogo fechar.
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
    }

    Future<void> pumpDeleting(WidgetTester tester) async {
      await pumpSignedIn(tester);
      await tapDeleteEntry(tester);
      await confirm(tester);
    }

    Future<void> pumpFailed(WidgetTester tester) async {
      await pumpDeleting(tester);
      repository.failDeletion(const NetworkFailure());
      await tester.pumpAndSettle();
    }

    Future<void> pumpDeleted(WidgetTester tester) async {
      await pumpDeleting(tester);
      repository.completeDeletion(const AccountDeleted());
      await tester.pumpAndSettle();
    }

    group('com a conta aberta', () {
      testWidgets('deve mostrar Excluir conta', (tester) async {
        await pumpSignedIn(tester);

        expect(
          find.widgetWithText(TextButton, l10n.profileDeleteAccount),
          findsOneWidget,
        );
      });

      testWidgets('deve dizer o que a exclusão apaga', (tester) async {
        await pumpSignedIn(tester);

        expect(find.text(l10n.profileDeleteAccountHint), findsOneWidget);
      });

      testWidgets('deve mostrar Excluir conta depois do Sobre o app', (
        tester,
      ) async {
        await pumpSignedIn(tester);

        final about = tester.getTopLeft(find.text(l10n.profileAboutEntry));
        final delete = tester.getTopLeft(find.text(l10n.profileDeleteAccount));
        expect(delete.dy, greaterThan(about.dy));
      });

      // O override pede o Excluir conta alinhado à esquerda, na mesma
      // margem do bloco da conta.
      testWidgets('deve alinhar Excluir conta com o Sair', (tester) async {
        await pumpSignedIn(tester);

        final signOut = tester.getTopLeft(
          find.widgetWithText(OutlinedButton, l10n.profileSignOut),
        );
        final delete = tester.getTopLeft(
          find.widgetWithText(TextButton, l10n.profileDeleteAccount),
        );
        expect(delete.dx, signOut.dx);
      });

      testWidgets('deve abrir a confirmação ao tocar em Excluir conta', (
        tester,
      ) async {
        await pumpSignedIn(tester);

        await tapDeleteEntry(tester);

        expect(find.text(l10n.deleteAccountDialogTitle), findsOneWidget);
      });

      testWidgets('deve explicar na confirmação que não dá para desfazer', (
        tester,
      ) async {
        await pumpSignedIn(tester);

        await tapDeleteEntry(tester);

        expect(find.text(l10n.deleteAccountDialogBody), findsOneWidget);
      });

      testWidgets('não deve excluir antes de confirmar', (tester) async {
        await pumpSignedIn(tester);

        await tapDeleteEntry(tester);

        expect(repository.pendingDeletions, 0);
      });

      testWidgets('deve fechar sem excluir ao tocar em Cancelar', (
        tester,
      ) async {
        await pumpSignedIn(tester);
        await tapDeleteEntry(tester);

        await tester.tap(find.text(l10n.deleteAccountDialogCancel));
        await tester.pumpAndSettle();

        expect(
          [
            find.byType(AlertDialog).evaluate().length,
            repository.pendingDeletions,
          ],
          [0, 0],
        );
      });

      testWidgets('deve excluir ao confirmar', (tester) async {
        await pumpSignedIn(tester);
        await tapDeleteEntry(tester);

        await confirm(tester);

        expect(repository.pendingDeletions, 1);
      });

      testWidgets('deve caber a confirmação com fonte 2x', (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        repository.emit(SignedIn(ana));
        await pumpProfile(tester, textScaler: const TextScaler.linear(2));
        await tester.pump();

        await tapDeleteEntry(tester);

        expect(tester.takeException(), isNull);
      });
    });

    testWidgets('não deve mostrar Excluir conta sem conta', (tester) async {
      repository.emit(const SignedOut());
      await pumpProfile(tester);
      await tester.pump();

      expect(find.text(l10n.profileDeleteAccount), findsNothing);
    });

    group('excluindo', () {
      testWidgets('deve mostrar Excluindo a conta', (tester) async {
        await pumpDeleting(tester);

        expect(find.text(l10n.profileDeletingAccount), findsOneWidget);
      });

      testWidgets('deve continuar mostrando a conta', (tester) async {
        await pumpDeleting(tester);

        expect(find.text('Ana Souza'), findsOneWidget);
      });

      testWidgets('deve desabilitar o Sair enquanto exclui', (tester) async {
        await pumpDeleting(tester);

        final signOut = tester.widget<OutlinedButton>(
          find.widgetWithText(OutlinedButton, l10n.profileSignOut),
        );
        expect(signOut.onPressed, isNull);
      });

      testWidgets('não deve excluir de novo enquanto exclui', (tester) async {
        await pumpDeleting(tester);

        final entry = tester.widget<TextButton>(
          find.widgetWithText(TextButton, l10n.profileDeletingAccount),
        );
        expect(entry.onPressed, isNull);
      });
    });

    group('falha na exclusão', () {
      testWidgets('deve mostrar a mensagem da falha', (tester) async {
        await pumpFailed(tester);

        expect(find.text(l10n.failureNetwork), findsOneWidget);
      });

      testWidgets('deve anunciar a falha ao leitor de tela', (tester) async {
        final semantics = tester.ensureSemantics();
        await pumpFailed(tester);

        expect(
          tester.getSemantics(find.text(l10n.failureNetwork)),
          matchesSemantics(label: l10n.failureNetwork, isLiveRegion: true),
        );
        semantics.dispose();
      });

      testWidgets('deve continuar mostrando a conta', (tester) async {
        await pumpFailed(tester);

        expect(find.text('Ana Souza'), findsOneWidget);
      });

      // A pessoa já confirmou: tentar de novo não abre outro diálogo.
      testWidgets('deve tentar excluir de novo sem a confirmação', (
        tester,
      ) async {
        await pumpFailed(tester);

        final retry = find.text(l10n.profileDeleteAccountRetry);
        await tester.ensureVisible(retry);
        await tester.pumpAndSettle();
        await tester.tap(retry);
        await tester.pump();

        expect(
          [
            find.byType(AlertDialog).evaluate().length,
            repository.pendingDeletions,
          ],
          [0, 1],
        );
      });

      testWidgets('deve deixar sair da conta', (tester) async {
        await pumpFailed(tester);

        await tester.tap(find.text(l10n.profileSignOut));
        await tester.pump();

        // Como no logado: espera as marcas chegarem ao servidor (sessão 022).
        expect(repository.syncCalls, greaterThan(0));
      });
    });

    group('conta excluída', () {
      testWidgets('deve avisar que a conta foi excluída', (tester) async {
        await pumpDeleted(tester);

        expect(find.text(l10n.profileAccountDeleted), findsOneWidget);
      });

      testWidgets('deve anunciar o aviso ao leitor de tela', (tester) async {
        final semantics = tester.ensureSemantics();
        await pumpDeleted(tester);

        expect(
          tester.getSemantics(find.text(l10n.profileAccountDeleted)),
          matchesSemantics(
            label: l10n.profileAccountDeleted,
            isLiveRegion: true,
          ),
        );
        semantics.dispose();
      });

      testWidgets('deve convidar a entrar de novo', (tester) async {
        await pumpDeleted(tester);

        expect(find.text(l10n.signInWithGoogle), findsOneWidget);
      });

      testWidgets('não deve mostrar Excluir conta', (tester) async {
        await pumpDeleted(tester);

        expect(find.text(l10n.profileDeleteAccount), findsNothing);
      });
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
      'saindo': (tester) async {
        repository
          ..emit(SignedIn(ana))
          ..syncGate = Completer<void>();
        addTearDown(() => repository.syncGate?.complete());
        await tester.pump();
        await tapVisible(tester, find.text(l10n.profileSignOut));
        await tester.pump();
      },
      'aviso de marcas sem sincronizar': (tester) async {
        repository
          ..emit(SignedIn(ana))
          ..synced = false;
        await tester.pump();
        await tapVisible(tester, find.text(l10n.profileSignOut));
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
      'excluindo a conta': (tester) async {
        repository.emit(SignedIn(ana));
        await tester.pump();
        unawaited(
          tester
              .element(find.byType(ProfileScreen))
              .read<SessionNotifier>()
              .deleteAccount(),
        );
        await tester.pump();
      },
      'falha na exclusão': (tester) async {
        repository.emit(SignedIn(ana));
        await tester.pump();
        unawaited(
          tester
              .element(find.byType(ProfileScreen))
              .read<SessionNotifier>()
              .deleteAccount(),
        );
        await tester.pump();
        repository.failDeletion(const NetworkFailure());
        await tester.pump();
      },
      'conta excluída': (tester) async {
        repository.emit(SignedIn(ana));
        await tester.pump();
        unawaited(
          tester
              .element(find.byType(ProfileScreen))
              .read<SessionNotifier>()
              .deleteAccount(),
        );
        await tester.pump();
        repository.completeDeletion(const AccountDeleted());
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

  testWidgets('deve trocar de estado sem animação com reduzir movimento', (
    tester,
  ) async {
    repository.emit(const SignedOut());
    await pumpProfile(tester, disableAnimations: true);
    await tester.pump();

    expect(
      tester.widget<AnimatedSwitcher>(find.byType(AnimatedSwitcher)).duration,
      Duration.zero,
    );
  });
}

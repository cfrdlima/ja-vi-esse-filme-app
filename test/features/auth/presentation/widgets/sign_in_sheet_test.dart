import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/core/error/failures.dart';
import 'package:ja_vi_esse_filme/features/auth/domain/entities/app_user.dart';
import 'package:ja_vi_esse_filme/features/auth/domain/entities/auth_state.dart';
import 'package:ja_vi_esse_filme/features/auth/domain/entities/sign_in_outcome.dart';
import 'package:ja_vi_esse_filme/features/auth/presentation/state/session_notifier.dart';
import 'package:ja_vi_esse_filme/features/auth/presentation/widgets/google_sign_in_button.dart';
import 'package:ja_vi_esse_filme/features/auth/presentation/widgets/sign_in_sheet.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/fake_auth_repository.dart';
import '../../../../helpers/test_app.dart';

void main() {
  late FakeAuthRepository auth;
  late SessionNotifier session;
  final ana = AppUser(uid: 'ana123', displayName: 'Ana');

  setUp(() => auth = FakeAuthRepository());
  tearDown(() => auth.close());

  /// Abre a folha por um botão e guarda o resultado em [results].
  Future<List<bool>> openSheet(WidgetTester tester) async {
    session = SessionNotifier(repository: auth);
    addTearDown(session.dispose);
    final results = <bool>[];
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: session,
        child: testApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async =>
                    results.add(await showSignInSheet(context)),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ),
    );
    auth.emit(const SignedOut());
    await tester.pump();
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    return results;
  }

  testWidgets('deve mostrar o título e o convite', (tester) async {
    await openSheet(tester);

    expect(find.text('Entre para guardar seus filmes'), findsOneWidget);
  });

  testWidgets('deve marcar o título como cabeçalho', (tester) async {
    final semantics = tester.ensureSemantics();
    await openSheet(tester);

    expect(
      tester.getSemantics(find.text('Entre para guardar seus filmes')),
      matchesSemantics(label: 'Entre para guardar seus filmes', isHeader: true),
    );
    semantics.dispose();
  });

  testWidgets('deve abrir o login do Google ao tocar no botão', (tester) async {
    await openSheet(tester);

    await tester.tap(find.text('Entrar com o Google'));
    await tester.pump();

    expect(auth.pendingSignIns, 1);
  });

  testWidgets('deve mostrar o botão entrando durante o login', (tester) async {
    await openSheet(tester);

    await tester.tap(find.text('Entrar com o Google'));
    await tester.pump();

    expect(
      tester
          .widget<GoogleSignInButton>(find.byType(GoogleSignInButton))
          .onPressed,
      isNull,
    );
  });

  testWidgets('deve fechar com verdadeiro quando a conta entra', (
    tester,
  ) async {
    final results = await openSheet(tester);

    await tester.tap(find.text('Entrar com o Google'));
    await tester.pump();
    auth.completeSignIn(SignInCompleted(ana));
    await tester.pumpAndSettle();

    expect(results, [true]);
  });

  testWidgets('deve fechar com falso pelo botão de fechar', (tester) async {
    final results = await openSheet(tester);

    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();

    expect(results, [false]);
  });

  testWidgets('deve ficar aberta quando o seletor do Google é cancelado', (
    tester,
  ) async {
    await openSheet(tester);

    await tester.tap(find.text('Entrar com o Google'));
    await tester.pump();
    auth.completeSignIn(const SignInCancelled());
    await tester.pumpAndSettle();

    expect(find.byType(SignInSheet), findsOneWidget);
  });

  testWidgets('deve mostrar a falha do login acima do botão', (tester) async {
    await openSheet(tester);

    await tester.tap(find.text('Entrar com o Google'));
    await tester.pump();
    auth.failSignIn(const NetworkFailure());
    await tester.pumpAndSettle();

    expect(
      find.text('Sem conexão com a internet. Confira sua rede.'),
      findsOneWidget,
    );
  });

  testWidgets('deve deixar tentar de novo depois da falha', (tester) async {
    await openSheet(tester);
    await tester.tap(find.text('Entrar com o Google'));
    await tester.pump();
    auth.failSignIn(const NetworkFailure());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Entrar com o Google'));
    await tester.pump();

    expect(auth.pendingSignIns, 1);
  });

  testWidgets('deve caber sem overflow com fonte grande', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await openSheet(tester);

    expect(tester.takeException(), isNull);
  });
}

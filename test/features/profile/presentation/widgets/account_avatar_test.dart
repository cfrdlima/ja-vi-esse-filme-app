import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/features/auth/domain/entities/app_user.dart';
import 'package:ja_vi_esse_filme/features/profile/presentation/widgets/account_avatar.dart';

import '../../../../helpers/test_app.dart';

void main() {
  Future<void> pumpAvatar(WidgetTester tester, AppUser user) =>
      tester.pumpWidget(
        testApp(
          home: Scaffold(body: AccountAvatar(user: user)),
        ),
      );

  AppUser userWithPhoto(String url) =>
      AppUser(uid: 'abc123', displayName: 'Ana', photoUrl: url);

  group('sem foto', () {
    testWidgets('deve mostrar a inicial do nome', (tester) async {
      await pumpAvatar(tester, AppUser(uid: 'abc123', displayName: 'ana'));

      expect(find.text('A'), findsOneWidget);
    });

    testWidgets('deve mostrar o ícone de pessoa sem nome', (tester) async {
      await pumpAvatar(tester, AppUser(uid: 'abc123'));

      expect(find.byIcon(Icons.person), findsOneWidget);
    });
  });

  group('host da foto', () {
    testWidgets('deve carregar a foto do googleusercontent.com', (
      tester,
    ) async {
      await pumpAvatar(
        tester,
        userWithPhoto('https://lh3.googleusercontent.com/a/foto=s96-c'),
      );

      // Só em memória (NetworkImage): a foto não fica gravada no aparelho.
      expect(
        find.image(
          const NetworkImage('https://lh3.googleusercontent.com/a/foto=s96-c'),
        ),
        findsOneWidget,
      );
    });

    for (final url in [
      'http://lh3.googleusercontent.com/a/foto',
      'https://example.com/foto.png',
      'https://googleusercontent.com.example.com/foto.png',
      'https://evilgoogleusercontent.com/foto.png',
      'não é url',
    ]) {
      testWidgets('não deve carregar a foto de $url', (tester) async {
        await pumpAvatar(tester, userWithPhoto(url));

        expect(find.byType(Image), findsNothing);
      });
    }
  });

  testWidgets('deve ficar fora do leitor de tela, porque o nome está ao lado', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpAvatar(tester, AppUser(uid: 'abc123', displayName: 'Ana'));

    expect(find.bySemanticsLabel('A'), findsNothing);
    semantics.dispose();
  });

  testWidgets('deve mostrar a inicial quando a foto não baixa', (tester) async {
    // Nos widget tests, todo pedido HTTP responde 400.
    await pumpAvatar(
      tester,
      userWithPhoto('https://lh3.googleusercontent.com/a/foto=s96-c'),
    );
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();

    expect(find.text('A'), findsOneWidget);
  });
}

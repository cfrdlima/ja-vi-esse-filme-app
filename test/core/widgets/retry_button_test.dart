import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/core/widgets/retry_button.dart';

import '../../helpers/test_app.dart';

void main() {
  Future<void> pumpButton(
    WidgetTester tester, {
    Duration wait = Duration.zero,
    VoidCallback? onPressed,
  }) => tester.pumpWidget(
    testApp(
      home: Scaffold(
        body: RetryButton.filled(onPressed: onPressed ?? () {}, wait: wait),
      ),
    ),
  );

  bool isEnabled(WidgetTester tester) =>
      tester.widget<FilledButton>(find.byType(FilledButton)).enabled;

  group('sem espera', () {
    testWidgets('deve mostrar "Tentar de novo"', (tester) async {
      await pumpButton(tester);

      expect(find.text('Tentar de novo'), findsOneWidget);
    });

    testWidgets('deve chamar a ação ao tocar', (tester) async {
      var calls = 0;
      await pumpButton(tester, onPressed: () => calls++);

      await tester.tap(find.byType(FilledButton));

      expect(calls, 1);
    });

    testWidgets('deve tratar espera negativa como sem espera', (tester) async {
      await pumpButton(tester, wait: const Duration(seconds: -5));

      expect(isEnabled(tester), isTrue);
    });
  });

  group('com espera', () {
    testWidgets('deve começar desabilitado', (tester) async {
      await pumpButton(tester, wait: const Duration(seconds: 3));

      expect(isEnabled(tester), isFalse);
    });

    testWidgets('deve mostrar os segundos que faltam', (tester) async {
      await pumpButton(tester, wait: const Duration(seconds: 3));

      expect(find.text('Tentar de novo em 3 s'), findsOneWidget);
    });

    testWidgets('deve anunciar os segundos por extenso ao leitor de tela', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpButton(tester, wait: const Duration(seconds: 3));

      expect(
        find.bySemanticsLabel('Tentar de novo em 3 segundos'),
        findsOneWidget,
      );
      semantics.dispose();
    });

    testWidgets('deve anunciar 1 segundo no singular', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpButton(tester, wait: const Duration(seconds: 1));

      expect(
        find.bySemanticsLabel('Tentar de novo em 1 segundo'),
        findsOneWidget,
      );
      semantics.dispose();
    });

    testWidgets('deve arredondar a fração de segundo para cima', (
      tester,
    ) async {
      await pumpButton(tester, wait: const Duration(milliseconds: 2100));

      expect(find.text('Tentar de novo em 3 s'), findsOneWidget);
    });

    testWidgets('deve descontar a cada segundo', (tester) async {
      await pumpButton(tester, wait: const Duration(seconds: 3));

      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Tentar de novo em 2 s'), findsOneWidget);
    });

    testWidgets('deve habilitar quando a espera acaba', (tester) async {
      await pumpButton(tester, wait: const Duration(seconds: 3));

      await tester.pump(const Duration(seconds: 3));

      expect(isEnabled(tester), isTrue);
    });

    testWidgets('deve voltar ao texto normal quando a espera acaba', (
      tester,
    ) async {
      await pumpButton(tester, wait: const Duration(seconds: 3));

      await tester.pump(const Duration(seconds: 3));

      expect(find.text('Tentar de novo'), findsOneWidget);
    });

    testWidgets('deve limitar a espera a 60 segundos', (tester) async {
      await pumpButton(tester, wait: const Duration(hours: 2));

      expect(find.text('Tentar de novo em 60 s'), findsOneWidget);
    });

    testWidgets('deve recomeçar a contagem com uma espera nova', (
      tester,
    ) async {
      await pumpButton(tester, wait: const Duration(seconds: 3));
      await tester.pump(const Duration(seconds: 2));

      await pumpButton(tester, wait: const Duration(seconds: 10));

      expect(find.text('Tentar de novo em 10 s'), findsOneWidget);
    });

    testWidgets('deve reconstruir com a mesma espera sem recomeçar', (
      tester,
    ) async {
      await pumpButton(tester, wait: const Duration(seconds: 3));
      await tester.pump(const Duration(seconds: 1));

      await pumpButton(tester, wait: const Duration(seconds: 3));

      expect(find.text('Tentar de novo em 2 s'), findsOneWidget);
    });

    // Sem expect próprio: quem verifica é o flutter_test, que reprova o teste
    // se sobrar um timer pendente no fim.
    testWidgets('deve cancelar o timer ao sair da tela', (tester) async {
      await pumpButton(tester, wait: const Duration(seconds: 30));

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('não deve vazar com fonte grande', (tester) async {
      await tester.pumpWidget(
        testApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 640),
              textScaler: TextScaler.linear(1.5),
            ),
            child: Scaffold(
              body: Center(
                child: RetryButton.text(
                  onPressed: () {},
                  wait: const Duration(seconds: 42),
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}

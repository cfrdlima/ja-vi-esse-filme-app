import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ja_vi_esse_filme/core/routing/app_router.dart';
import 'package:ja_vi_esse_filme/core/theme/app_theme.dart';

Future<GoRouter> pumpAppRouter(WidgetTester tester) async {
  final router = createAppRouter();
  addTearDown(router.dispose);
  await tester.pumpWidget(
    MaterialApp.router(theme: AppTheme.dark(), routerConfig: router),
  );
  await tester.pumpAndSettle();
  return router;
}

void main() {
  group('shell de navegação', () {
    testWidgets('deve abrir na aba Descobrir', (tester) async {
      final router = await pumpAppRouter(tester);

      expect(router.state.matchedLocation, AppRoutes.discover);
    });

    testWidgets('deve mostrar a barra com as 4 abas em PT-BR', (tester) async {
      await pumpAppRouter(tester);

      final labels = tester
          .widgetList<NavigationDestination>(find.byType(NavigationDestination))
          .map((destination) => destination.label);
      expect(labels, ['Descobrir', 'Buscar', 'Minha estante', 'Perfil']);
    });
  });
}

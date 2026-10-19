import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/error/error_handlers.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  registerErrorHandlers();
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  // Criado uma vez só: recriar o router a cada build perderia a pilha de
  // navegação.
  late final GoRouter _router = createAppRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(theme: AppTheme.dark(), routerConfig: _router);
  }
}

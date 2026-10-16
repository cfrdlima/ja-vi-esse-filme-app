import 'package:flutter/material.dart';

import 'core/error/error_handlers.dart';
import 'core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  registerErrorHandlers();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.dark(),
      home: const Scaffold(body: Center(child: Text('Hello World!'))),
    );
  }
}

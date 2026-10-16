import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

abstract final class AppRoutes {
  static const discover = '/descobrir';
  static const search = '/buscar';
  static const shelf = '/estante';
  static const profile = '/perfil';
}

GoRouter createAppRouter() => GoRouter(
  routes: [GoRoute(path: '/', builder: (_, _) => const SizedBox.shrink())],
);

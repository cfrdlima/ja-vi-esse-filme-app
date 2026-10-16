import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'app_shell.dart';

abstract final class AppRoutes {
  static const discover = '/descobrir';
  static const search = '/buscar';
  static const shelf = '/estante';
  static const profile = '/perfil';
}

GoRouter createAppRouter() => GoRouter(
  initialLocation: AppRoutes.discover,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (_, _, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: [
        _branch(AppRoutes.discover),
        _branch(AppRoutes.search),
        _branch(AppRoutes.shelf),
        _branch(AppRoutes.profile),
      ],
    ),
  ],
);

StatefulShellBranch _branch(String path) => StatefulShellBranch(
  routes: [GoRoute(path: path, builder: (_, _) => const SizedBox.shrink())],
);

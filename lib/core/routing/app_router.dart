import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../widgets/placeholder_screen.dart';
import 'app_shell.dart';
import 'not_found_screen.dart';

abstract final class AppRoutes {
  static const discover = '/descobrir';
  static const search = '/buscar';
  static const shelf = '/estante';
  static const profile = '/perfil';
}

GoRouter createAppRouter() => GoRouter(
  initialLocation: AppRoutes.discover,
  errorBuilder: (context, _) =>
      NotFoundScreen(onGoHome: () => context.go(AppRoutes.discover)),
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (_, _, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: [
        _branch(
          AppRoutes.discover,
          const PlaceholderScreen(title: 'Descobrir'),
        ),
        _branch(
          AppRoutes.search,
          const BackToFirstTab(child: PlaceholderScreen(title: 'Buscar')),
        ),
        _branch(
          AppRoutes.shelf,
          const BackToFirstTab(
            child: PlaceholderScreen(title: 'Minha estante'),
          ),
        ),
        _branch(
          AppRoutes.profile,
          const BackToFirstTab(child: PlaceholderScreen(title: 'Perfil')),
        ),
      ],
    ),
  ],
);

StatefulShellBranch _branch(String path, Widget root) => StatefulShellBranch(
  routes: [GoRoute(path: path, builder: (_, _) => root)],
);

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
        _branch(AppRoutes.discover, title: 'Descobrir'),
        _branch(AppRoutes.search, title: 'Buscar'),
        _branch(AppRoutes.shelf, title: 'Minha estante'),
        _branch(AppRoutes.profile, title: 'Perfil'),
      ],
    ),
  ],
);

StatefulShellBranch _branch(String path, {required String title}) =>
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: path,
          builder: (_, _) => PlaceholderScreen(title: title),
        ),
      ],
    );

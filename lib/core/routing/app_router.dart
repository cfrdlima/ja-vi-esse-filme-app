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
    appShellRoute([
      firstTabBranch(
        path: AppRoutes.discover,
        root: const PlaceholderScreen(title: 'Descobrir'),
      ),
      tabBranch(
        path: AppRoutes.search,
        root: const PlaceholderScreen(title: 'Buscar'),
      ),
      tabBranch(
        path: AppRoutes.shelf,
        root: const PlaceholderScreen(title: 'Minha estante'),
      ),
      tabBranch(
        path: AppRoutes.profile,
        root: const PlaceholderScreen(title: 'Perfil'),
      ),
    ]),
  ],
);

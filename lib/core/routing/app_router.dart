import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
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
        root: _placeholder((l10n) => l10n.tabDiscover),
      ),
      tabBranch(
        path: AppRoutes.search,
        root: _placeholder((l10n) => l10n.tabSearch),
      ),
      tabBranch(
        path: AppRoutes.shelf,
        root: _placeholder((l10n) => l10n.shelfTitle),
      ),
      tabBranch(
        path: AppRoutes.profile,
        root: _placeholder((l10n) => l10n.tabProfile),
      ),
    ]),
  ],
);

/// O router é montado sem `BuildContext`, então o título só é lido do
/// catálogo quando a tela é construída. Sai junto com os placeholders na
/// Fase 1.
Widget _placeholder(String Function(AppLocalizations) titleOf) => Builder(
  builder: (context) =>
      PlaceholderScreen(title: titleOf(AppLocalizations.of(context))),
);

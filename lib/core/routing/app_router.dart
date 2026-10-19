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
        root: const _Placeholder(_discoverTitle),
      ),
      tabBranch(path: AppRoutes.search, root: const _Placeholder(_searchTitle)),
      tabBranch(path: AppRoutes.shelf, root: const _Placeholder(_shelfTitle)),
      tabBranch(
        path: AppRoutes.profile,
        root: const _Placeholder(_profileTitle),
      ),
    ]),
  ],
);

String _discoverTitle(AppLocalizations l10n) => l10n.tabDiscover;
String _searchTitle(AppLocalizations l10n) => l10n.tabSearch;
String _shelfTitle(AppLocalizations l10n) => l10n.shelfTitle;
String _profileTitle(AppLocalizations l10n) => l10n.tabProfile;

/// O router é montado sem `BuildContext`, então o título só é lido do
/// catálogo quando a tela é construída. Sai junto com os placeholders na
/// Fase 1.
class _Placeholder extends StatelessWidget {
  const _Placeholder(this.title);

  final String Function(AppLocalizations) title;

  @override
  Widget build(BuildContext context) =>
      PlaceholderScreen(title: title(AppLocalizations.of(context)));
}

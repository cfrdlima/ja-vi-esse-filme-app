import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../features/movies/domain/repositories/movie_repository.dart';
import '../../features/movies/presentation/screens/discover_screen.dart';
import '../../features/movies/presentation/screens/movie_details_screen.dart';
import '../../features/movies/presentation/screens/search_screen.dart';
import '../../features/movies/presentation/state/discover_notifier.dart';
import '../../features/movies/presentation/state/movie_details_notifier.dart';
import '../../features/movies/presentation/state/search_notifier.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/placeholder_screen.dart';
import 'app_routes.dart';
import 'app_shell.dart';
import 'not_found_screen.dart';

/// As dependências chegam já montadas pelo `main.dart` (ou por fakes nos
/// testes).
GoRouter createAppRouter({required MovieRepository movieRepository}) =>
    GoRouter(
      initialLocation: AppRoutes.discover,
      errorBuilder: (context, _) =>
          NotFoundScreen(onGoHome: () => context.go(AppRoutes.discover)),
      routes: [
        appShellRoute([
          firstTabBranch(
            path: AppRoutes.discover,
            // O shell mantém a aba viva, então a lista e a rolagem sobrevivem à
            // troca de aba.
            root: ChangeNotifierProvider(
              create: (_) => DiscoverNotifier(repository: movieRepository),
              child: const DiscoverScreen(),
            ),
            routes: [_movieDetailsRoute(movieRepository)],
          ),
          tabBranch(
            path: AppRoutes.search,
            root: ChangeNotifierProvider(
              create: (_) => SearchNotifier(repository: movieRepository),
              child: const SearchScreen(),
            ),
            routes: [_movieDetailsRoute(movieRepository)],
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

/// Sub-rota de uma aba: empilha os detalhes sobre a grade, que fica viva por
/// baixo com a rolagem.
GoRoute _movieDetailsRoute(MovieRepository movieRepository) => GoRoute(
  path: 'filme/:id',
  builder: (_, state) => ChangeNotifierProvider(
    create: (_) {
      final notifier = MovieDetailsNotifier(
        repository: movieRepository,
        // O id vem da URL e pode ser qualquer texto; o que não é número vai
        // para o "não encontrado" (o notifier trata também o id < 1).
        movieId: int.tryParse(state.pathParameters['id']!),
      );
      unawaited(notifier.load());
      return notifier;
    },
    child: const MovieDetailsScreen(),
  ),
);

/// O router é montado sem `BuildContext`, então o título só é lido do
/// catálogo quando a tela é construída. Sai junto com os placeholders na
/// Fase 1.
Widget _placeholder(String Function(AppLocalizations) titleOf) => Builder(
  builder: (context) =>
      PlaceholderScreen(title: titleOf(AppLocalizations.of(context))),
);

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/l10n/failure_message.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/state/session_notifier.dart';
import '../../../auth/presentation/state/session_state.dart';
import '../../../auth/presentation/widgets/google_sign_in_button.dart';
import '../../../movies/presentation/widgets/paged_movies_view.dart';
import '../../../movies/presentation/widgets/poster_grid.dart';
import '../../domain/entities/shelf_mark.dart';
import '../widgets/shelf_tab.dart';

/// A aba Estante (override `estante.md`): sem conta, o convite para entrar;
/// com conta, as abas Assistidos, Quero assistir e Favoritos. Lê do contexto
/// o `SessionNotifier`, o `ShelfRepository`, o `AuthRepository` e o
/// `MovieCopySource`.
class ShelfScreen extends StatelessWidget {
  const ShelfScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final title = Text(AppLocalizations.of(context).shelfTitle);
    return switch (context.watch<SessionNotifier>().state) {
      SessionSignedOut() ||
      SessionSigningIn() ||
      SessionSignInFailed() => Scaffold(
        appBar: AppBar(title: title),
        body: const _SignInInvite(),
      ),
      // As abas nascem com a conta e morrem quando a saída começa, antes do
      // `closeStreams()`: nenhum stream nem renovação da Estante sobrevive à
      // limpeza do cache (decisão 010).
      SessionLoading() ||
      SessionSignedIn() ||
      SessionDeleteAccountFailed() => _ShelfTabs(title: title),
      SessionSigningOut() ||
      SessionUnsyncedSignOut() ||
      SessionDeletingAccount() => Scaffold(
        appBar: AppBar(title: title),
        body: PosterGridSkeleton(
          label: AppLocalizations.of(context).profileSigningOut,
        ),
      ),
      SessionSignOutFailed() => Scaffold(
        appBar: AppBar(title: title),
        body: const _SignOutFailed(),
      ),
    };
  }
}

class _ShelfTabs extends StatelessWidget {
  const _ShelfTabs({required this.title});

  final Widget title;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DefaultTabController(
      length: ShelfMark.values.length,
      child: Scaffold(
        appBar: AppBar(
          title: title,
          bottom: TabBar(
            // Com a fonte grande, rola em vez de cortar o rótulo.
            isScrollable: MediaQuery.textScalerOf(context).scale(1) > 1,
            tabs: [
              for (final mark in ShelfMark.values)
                Tab(text: shelfTabLabel(l10n, mark)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            for (final (index, mark) in ShelfMark.values.indexed)
              ShelfTab(mark: mark, index: index),
          ],
        ),
      ),
    );
  }
}

/// O rótulo de cada aba, na ordem da fileira de marcas dos Detalhes.
String shelfTabLabel(AppLocalizations l10n, ShelfMark mark) => switch (mark) {
  ShelfMark.watched => l10n.shelfTabWatched,
  ShelfMark.watchlist => l10n.shelfTabWatchlist,
  ShelfMark.favorite => l10n.shelfTabFavorite,
};

class _SignInInvite extends StatelessWidget {
  const _SignInInvite();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.extension<AppThemeTokens>()!.spacing;
    final l10n = AppLocalizations.of(context);
    final session = context.watch<SessionNotifier>();
    final state = session.state;
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(spacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: Icon(
                Icons.video_library_outlined,
                size: theme.iconTheme.size,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: spacing.md),
            Text(
              l10n.shelfSignInBody,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: spacing.lg),
            if (state case SessionSignInFailed(:final failure)) ...[
              Semantics(
                liveRegion: true,
                child: Text(
                  failureMessage(l10n, failure),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
              SizedBox(height: spacing.md),
            ],
            if (state is SessionSigningIn)
              const GoogleSignInButton.loading()
            else
              GoogleSignInButton(onPressed: () => unawaited(session.signIn())),
          ],
        ),
      ),
    );
  }
}

/// A saída falhou depois de fechar a Estante: as abas não voltam, porque
/// reabririam o Firestore no cache que ficou. O Perfil tem o "tentar de
/// novo" da saída.
class _SignOutFailed extends StatelessWidget {
  const _SignOutFailed();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return MoviesMessage(
      message: l10n.shelfSignOutFailed,
      action: FilledButton(
        onPressed: () => context.go(AppRoutes.profile),
        child: Text(l10n.shelfGoToProfile),
      ),
    );
  }
}

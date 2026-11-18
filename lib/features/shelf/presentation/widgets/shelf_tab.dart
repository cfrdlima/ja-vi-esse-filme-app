import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/error/retry_wait.dart';
import '../../../../core/l10n/failure_message.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../../../../core/widgets/retry_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../movies/domain/entities/movie.dart';
import '../../../movies/presentation/state/paged_movies_state.dart';
import '../../../movies/presentation/widgets/movie_poster.dart';
import '../../../movies/presentation/widgets/paged_movies_view.dart';
import '../../../movies/presentation/widgets/poster_grid.dart';
import '../../../movies/presentation/widgets/poster_hero.dart';
import '../../domain/entities/shelf_mark.dart';
import '../../domain/entities/shelf_movie.dart';
import '../../domain/repositories/movie_copy_source.dart';
import '../../domain/repositories/shelf_repository.dart';
import '../../domain/usecases/expired_copy_renewer.dart';
import '../state/shelf_tab_notifier.dart';
import '../state/shelf_tab_state.dart';

/// Uma aba da Estante com o notifier dela. Fica viva no `TabBarView`, com os
/// filmes e a rolagem, depois da primeira vez que é aberta.
class ShelfTab extends StatefulWidget {
  const ShelfTab({required this.mark, required this.index, super.key});

  final ShelfMark mark;

  /// A posição no `TabController`, para só a aba visível ter o Hero.
  final int index;

  @override
  State<ShelfTab> createState() => _ShelfTabState();
}

class _ShelfTabState extends State<ShelfTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ChangeNotifierProvider(
      create: (context) {
        final shelf = context.read<ShelfRepository>();
        final source = context.read<MovieCopySource>();
        return ShelfTabNotifier(
          mark: widget.mark,
          shelf: shelf,
          account: context.read<AuthRepository>().authStateChanges,
          newRenewer: () => ExpiredCopyRenewer(
            shelf: shelf,
            source: source,
            now: () => DateTime.now().toUtc(),
          ),
        );
      },
      child: ShelfTabView(mark: widget.mark, index: widget.index),
    );
  }
}

/// Os 4 estados de uma aba (override `estante.md`).
class ShelfTabView extends StatelessWidget {
  const ShelfTabView({required this.mark, required this.index, super.key});

  final ShelfMark mark;
  final int index;

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ShelfTabNotifier>();
    final l10n = AppLocalizations.of(context);
    return switch (notifier.state) {
      // Sem conta, a tela inteira já é o convite; o deslogado só aparece
      // aqui no instante em que a conta sai.
      ShelfTabLoading() ||
      ShelfTabSignedOut() => PosterGridSkeleton(label: l10n.shelfLoading),
      ShelfTabEmpty() => MoviesMessage(
        message: _emptyMessage(l10n, mark),
        action: FilledButton(
          onPressed: () => context.go(AppRoutes.discover),
          child: Text(l10n.shelfDiscoverAction),
        ),
      ),
      ShelfTabError(:final failure) => MoviesMessage(
        message: failureMessage(l10n, failure),
        action: RetryButton.filled(
          onPressed: notifier.retry,
          wait: retryWaitOf(failure),
        ),
      ),
      final ShelfTabReady state => PosterGridWidthGuard(
        child: _ShelfGrid(
          state: state,
          index: index,
          scrollKey: 'estante-${mark.name}',
          onLoadMore: notifier.loadMore,
          onRetry: notifier.retry,
        ),
      ),
    };
  }

  static String _emptyMessage(AppLocalizations l10n, ShelfMark mark) =>
      switch (mark) {
        ShelfMark.watched => l10n.shelfEmptyWatched,
        ShelfMark.watchlist => l10n.shelfEmptyWatchlist,
        ShelfMark.favorite => l10n.shelfEmptyFavorite,
      };
}

class _ShelfGrid extends StatefulWidget {
  const _ShelfGrid({
    required this.state,
    required this.index,
    required this.scrollKey,
    required this.onLoadMore,
    required this.onRetry,
  });

  final ShelfTabReady state;
  final int index;
  final String scrollKey;
  final VoidCallback onLoadMore;
  final VoidCallback onRetry;

  @override
  State<_ShelfGrid> createState() => _ShelfGridState();
}

class _ShelfGridState extends State<_ShelfGrid> {
  // Pede mais quando faltam cerca de 2 telas para o fim, como o Descobrir.
  // O notifier ignora o pedido sem mais filmes ou com outro a caminho.
  static const _screensAhead = 2;

  final _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_loadMoreIfNearEnd);
    _checkAfterLayout();
  }

  @override
  void didUpdateWidget(_ShelfGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkAfterLayout();
  }

  // Sem rolagem não há evento: se os filmes não enchem a tela, a
  // conferência depois do layout pede mais.
  void _checkAfterLayout() =>
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadMoreIfNearEnd());

  void _loadMoreIfNearEnd() {
    if (!mounted || !_controller.hasClients) return;
    final position = _controller.position;
    if (position.extentAfter < position.viewportDimension * _screensAhead) {
      widget.onLoadMore();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final movies = widget.state.movies;
    final tabs = DefaultTabController.of(context);
    return CustomScrollView(
      key: PageStorageKey(widget.scrollKey),
      controller: _controller,
      slivers: [
        SliverPadding(
          padding: PosterGrid.padding(tokens),
          sliver: SliverGrid.builder(
            gridDelegate: PosterGrid.delegate(tokens),
            itemCount: movies.length,
            itemBuilder: (_, index) => ListenableBuilder(
              key: ValueKey(movies[index].copy.movieId),
              listenable: tabs,
              builder: (context, _) => _ShelfPoster(
                movie: movies[index],
                // O mesmo filme pode estar em duas abas vivas, e os
                // Detalhes esperam a tag `poster-<id>`: só a aba visível
                // tem o Hero.
                withHero: tabs.index == widget.index,
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: _Footer(state: widget.state, onRetry: widget.onRetry),
        ),
      ],
    );
  }
}

class _ShelfPoster extends StatelessWidget {
  const _ShelfPoster({required this.movie, required this.withHero});

  final ShelfMovie movie;
  final bool withHero;

  @override
  Widget build(BuildContext context) {
    final copy = movie.copy;
    // A cópia vencida não aparece como atual (decisão 013): sem o título e
    // o pôster velhos, até a renovação chegar pelo stream.
    final expired = movie.isCopyExpired(DateTime.now().toUtc());
    final shown = expired
        ? Movie(
            id: copy.movieId,
            title: AppLocalizations.of(context).shelfCopyUpdating,
          )
        : Movie(
            id: copy.movieId,
            title: copy.title,
            posterPath: copy.posterPath,
          );
    final poster = MoviePoster(
      movie: shown,
      onTap: () => context.go(
        AppRoutes.movieDetails(AppRoutes.shelf, copy.movieId),
        // Os Detalhes mostram o `extra` antes de o TMDB responder; a cópia
        // vencida não vai.
        extra: expired ? null : shown,
      ),
    );
    if (!withHero) return poster;
    return PosterHero(movieId: copy.movieId, child: poster);
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.state, required this.onRetry});

  final ShelfTabReady state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.extension<AppThemeTokens>()!.spacing;
    return Padding(
      padding: EdgeInsets.only(bottom: spacing.lg),
      child: switch (state.nextPage) {
        NextPageFailed(:final failure) => Column(
          children: [
            _FooterText(AppLocalizations.of(context).shelfUpdateFailed),
            RetryButton.text(onPressed: onRetry, wait: retryWaitOf(failure)),
          ],
        ),
        NextPageLoading() => const Center(child: CircularProgressIndicator()),
        NextPageIdle() when state.capped => _FooterText(
          AppLocalizations.of(context).shelfCapped(ShelfTabNotifier.maxLimit),
        ),
        NextPageIdle() => const SizedBox.shrink(),
      },
    );
  }
}

class _FooterText extends StatelessWidget {
  const _FooterText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      textAlign: TextAlign.center,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

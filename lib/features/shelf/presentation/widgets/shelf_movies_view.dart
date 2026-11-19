import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/error/retry_wait.dart';
import '../../../../core/l10n/failure_message.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../../../../core/widgets/retry_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../movies/domain/entities/movie.dart';
import '../../../movies/presentation/state/paged_movies_state.dart';
import '../../../movies/presentation/widgets/movie_poster.dart';
import '../../../movies/presentation/widgets/paged_movies_view.dart';
import '../../../movies/presentation/widgets/poster_grid.dart';
import '../../../movies/presentation/widgets/poster_hero.dart';
import '../../domain/entities/shelf_movie.dart';
import '../state/shelf_tab_notifier.dart';
import '../state/shelf_tab_state.dart';

/// Os 4 estados de uma grade da Estante, com o [ShelfTabNotifier] do
/// contexto: as abas das marcas e a tela de uma lista (decisão 019).
class ShelfMoviesView extends StatelessWidget {
  const ShelfMoviesView({
    required this.emptyMessage,
    required this.scrollKey,
    required this.detailsPath,
    this.heroListenable,
    this.withHero,
    this.onLongPress,
    this.longPressLabel,
    super.key,
  });

  final String emptyMessage;
  final String scrollKey;

  /// Onde ficam os Detalhes do filme, na pilha de quem mostra a grade.
  final String Function(int movieId) detailsPath;

  /// Avisa quando o [withHero] pode ter mudado.
  final Listenable? heroListenable;

  /// Se os pôsteres têm o Hero agora; sem ele, sempre têm.
  final bool Function()? withHero;

  /// O toque longo num pôster, também oferecido ao leitor de tela como a
  /// ação [longPressLabel].
  final ValueChanged<ShelfMovie>? onLongPress;
  final String? longPressLabel;

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
        message: emptyMessage,
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
          view: this,
          onLoadMore: notifier.loadMore,
          onRetry: notifier.retry,
        ),
      ),
    };
  }
}

class _ShelfGrid extends StatefulWidget {
  const _ShelfGrid({
    required this.state,
    required this.view,
    required this.onLoadMore,
    required this.onRetry,
  });

  final ShelfTabReady state;
  final ShelfMoviesView view;
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
    final view = widget.view;
    return CustomScrollView(
      key: PageStorageKey(view.scrollKey),
      controller: _controller,
      slivers: [
        SliverPadding(
          padding: PosterGrid.padding(tokens),
          sliver: SliverGrid.builder(
            gridDelegate: PosterGrid.delegate(tokens),
            itemCount: movies.length,
            itemBuilder: (_, index) => ListenableBuilder(
              key: ValueKey(movies[index].copy.movieId),
              listenable: view.heroListenable ?? const _NeverChanges(),
              builder: (context, _) => _ShelfPoster(
                movie: movies[index],
                view: view,
                withHero: view.withHero?.call() ?? true,
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
  const _ShelfPoster({
    required this.movie,
    required this.view,
    required this.withHero,
  });

  final ShelfMovie movie;
  final ShelfMoviesView view;
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
        view.detailsPath(copy.movieId),
        // Os Detalhes mostram o `extra` antes de o TMDB responder; a cópia
        // vencida não vai.
        extra: expired ? null : shown,
      ),
    );
    final shownPoster = withHero
        ? PosterHero(movieId: copy.movieId, child: poster)
        : poster;
    final onLongPress = view.onLongPress;
    if (onLongPress == null) return shownPoster;
    return Semantics(
      customSemanticsActions: {
        CustomSemanticsAction(label: view.longPressLabel ?? ''): () =>
            onLongPress(movie),
      },
      child: GestureDetector(
        onLongPress: () => onLongPress(movie),
        child: shownPoster,
      ),
    );
  }
}

/// Um `Listenable` que nunca avisa, para a grade sem Hero condicional.
class _NeverChanges implements Listenable {
  const _NeverChanges();

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}
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

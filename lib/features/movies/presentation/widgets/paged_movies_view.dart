import 'package:flutter/material.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/error/retry_wait.dart';
import '../../../../core/l10n/failure_message.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../../../../core/widgets/retry_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/movie.dart';
import '../state/paged_movies_notifier.dart';
import '../state/paged_movies_state.dart';
import 'movie_poster.dart';
import 'poster_grid.dart';
import 'poster_hero.dart';

/// Os 4 estados de uma lista paginada de filmes, com paginação infinita. O
/// vazio muda de tela para tela e vem em [empty].
class PagedMoviesView extends StatelessWidget {
  const PagedMoviesView({
    required this.notifier,
    required this.empty,
    required this.onMovieTap,
    this.scrollKey,
    super.key,
  });

  final PagedMoviesNotifier notifier;

  /// Chave do `PageStorage` em que a rolagem da grade fica guardada. Sem ela,
  /// a rolagem só vive enquanto a grade estiver montada.
  final String? scrollKey;

  final Widget empty;

  /// Toque num pôster da grade; a tela diz para onde ele leva.
  final ValueChanged<Movie> onMovieTap;

  @override
  Widget build(BuildContext context) => switch (notifier.state) {
    PagedMoviesLoading() => PosterGridSkeleton(
      label: AppLocalizations.of(context).moviesLoading,
    ),
    PagedMoviesEmpty() => empty,
    PagedMoviesError(:final failure) => _ErrorView(
      failure: failure,
      onRetry: notifier.load,
    ),
    final PagedMoviesLoaded state => PosterGridWidthGuard(
      child: _MovieGrid(
        scrollKey: scrollKey,
        state: state,
        onLoadMore: notifier.loadMore,
        onRetryNextPage: notifier.retryNextPage,
        onMovieTap: onMovieTap,
      ),
    ),
  };
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.failure, required this.onRetry});

  final Failure failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => MoviesMessage(
    message: failureMessage(AppLocalizations.of(context), failure),
    action: RetryButton.filled(onPressed: onRetry, wait: retryWaitOf(failure)),
  );
}

/// Mensagem centralizada do vazio e do erro, com uma [action] opcional
/// abaixo.
class MoviesMessage extends StatelessWidget {
  const MoviesMessage({required this.message, this.action, super.key});

  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.extension<AppThemeTokens>()!.spacing;
    final action = this.action;
    // Rolável para a fonte grande não vazar em telas baixas.
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(spacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Região viva: na Buscar o foco fica no campo, e sem o anúncio
            // quem usa leitor de tela não sabe que a busca terminou vazia ou
            // falhou.
            Semantics(
              liveRegion: true,
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            if (action != null) ...[SizedBox(height: spacing.md), action],
          ],
        ),
      ),
    );
  }
}

class _MovieGrid extends StatefulWidget {
  const _MovieGrid({
    required this.scrollKey,
    required this.state,
    required this.onLoadMore,
    required this.onRetryNextPage,
    required this.onMovieTap,
  });

  final String? scrollKey;
  final PagedMoviesLoaded state;
  final VoidCallback onLoadMore;
  final VoidCallback onRetryNextPage;
  final ValueChanged<Movie> onMovieTap;

  @override
  State<_MovieGrid> createState() => _MovieGridState();
}

class _MovieGridState extends State<_MovieGrid> {
  // Pede a próxima página quando faltam cerca de 2 telas para o fim
  // (override `descobrir.md`). O notifier ignora pedidos repetidos e, depois
  // de uma falha, espera o "Tentar de novo".
  static const _screensAhead = 2;

  final _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_loadMoreIfNearEnd);
    _checkAfterLayout();
  }

  @override
  void didUpdateWidget(_MovieGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkAfterLayout();
  }

  // Sem rolagem não há evento: se a página não encheu a tela (tablet,
  // página só com repetidos), a conferência depois do layout pede a próxima.
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
    return CustomScrollView(
      key: switch (widget.scrollKey) {
        final key? => PageStorageKey(key),
        null => null,
      },
      // Arrastar a grade tira o teclado da frente dos pôsteres.
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      controller: _controller,
      slivers: [
        SliverPadding(
          padding: PosterGrid.padding(tokens),
          sliver: SliverGrid.builder(
            gridDelegate: PosterGrid.delegate(tokens),
            itemCount: movies.length,
            itemBuilder: (_, index) => PosterHero(
              key: ValueKey(movies[index].id),
              movieId: movies[index].id,
              child: MoviePoster(
                movie: movies[index],
                onTap: () => widget.onMovieTap(movies[index]),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: _NextPageFooter(
            status: widget.state.nextPage,
            onRetry: widget.onRetryNextPage,
          ),
        ),
      ],
    );
  }
}

class _NextPageFooter extends StatelessWidget {
  const _NextPageFooter({required this.status, required this.onRetry});

  final NextPageStatus status;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.extension<AppThemeTokens>()!.spacing;
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: spacing.lg),
      child: switch (status) {
        NextPageIdle() => const SizedBox.shrink(),
        NextPageLoading() => const Center(child: CircularProgressIndicator()),
        NextPageFailed(:final failure) => Column(
          children: [
            Text(
              l10n.moviesLoadMoreFailed,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            RetryButton.text(onPressed: onRetry, wait: retryWaitOf(failure)),
          ],
        ),
      },
    );
  }
}

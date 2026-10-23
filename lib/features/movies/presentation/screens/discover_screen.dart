import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/l10n/failure_message.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../state/popular_movies_notifier.dart';
import '../state/popular_movies_state.dart';
import '../widgets/movie_poster.dart';
import '../widgets/poster_skeleton.dart';

/// Aba Descobrir: grade de filmes populares com paginação infinita.
class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<PopularMoviesNotifier>();
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).discoverTitle)),
      body: switch (notifier.state) {
        PopularMoviesLoading() => const _LoadingView(),
        PopularMoviesEmpty() => _MessageView(
          message: AppLocalizations.of(context).discoverEmpty,
          onRetry: notifier.load,
        ),
        PopularMoviesError(:final failure) => _ErrorView(
          failure: failure,
          onRetry: notifier.load,
        ),
        final PopularMoviesLoaded state => _MovieGrid(
          state: state,
          onLoadMore: notifier.loadMore,
        ),
      },
    );
  }
}

/// Delegate comum à grade real e ao skeleton, para o layout não pular.
SliverGridDelegate _gridDelegate(AppThemeTokens tokens) =>
    SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: AppSizes.posterGridMaxExtent,
      childAspectRatio: 2 / 3,
      mainAxisSpacing: tokens.spacing.sm,
      crossAxisSpacing: tokens.spacing.sm,
    );

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  static const _cellCount = 12;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    return Semantics(
      label: AppLocalizations.of(context).discoverLoading,
      liveRegion: true,
      child: ExcludeSemantics(
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.all(tokens.spacing.md),
          gridDelegate: _gridDelegate(tokens),
          itemCount: _cellCount,
          itemBuilder: (_, _) => const PosterSkeleton(),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.failure, required this.onRetry});

  final Failure failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => _MessageView(
    message: failureMessage(AppLocalizations.of(context), failure),
    onRetry: onRetry,
  );
}

/// Mensagem centralizada com "Tentar de novo", usada no vazio e no erro.
class _MessageView extends StatelessWidget {
  const _MessageView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.extension<AppThemeTokens>()!.spacing;
    // Rolável para a fonte grande não vazar em telas baixas.
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(spacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: spacing.md),
            FilledButton(
              onPressed: onRetry,
              child: Text(AppLocalizations.of(context).retry),
            ),
          ],
        ),
      ),
    );
  }
}

class _MovieGrid extends StatefulWidget {
  const _MovieGrid({required this.state, required this.onLoadMore});

  final PopularMoviesLoaded state;
  final VoidCallback onLoadMore;

  @override
  State<_MovieGrid> createState() => _MovieGridState();
}

class _MovieGridState extends State<_MovieGrid> {
  // Pede a próxima página quando faltam cerca de 2 telas para o fim
  // (override `descobrir.md`). O notifier ignora pedidos repetidos.
  static const _screensAhead = 2;

  bool _onScroll(ScrollNotification notification) {
    final metrics = notification.metrics;
    if (metrics.extentAfter < metrics.viewportDimension * _screensAhead) {
      widget.onLoadMore();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final movies = widget.state.movies;
    return NotificationListener<ScrollUpdateNotification>(
      onNotification: _onScroll,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.all(tokens.spacing.md),
            sliver: SliverGrid.builder(
              gridDelegate: _gridDelegate(tokens),
              itemCount: movies.length,
              itemBuilder: (_, index) => MoviePoster(
                key: ValueKey(movies[index].id),
                movie: movies[index],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _NextPageFooter(
              status: widget.state.nextPage,
              onRetry: widget.onLoadMore,
            ),
          ),
        ],
      ),
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
        NextPageStatus.idle => const SizedBox.shrink(),
        NextPageStatus.loading => const Center(
          child: CircularProgressIndicator(),
        ),
        NextPageStatus.failed => Column(
          children: [
            Text(
              l10n.discoverLoadMoreFailed,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            TextButton(onPressed: onRetry, child: Text(l10n.retry)),
          ],
        ),
      },
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/l10n/failure_message.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../../../../core/widgets/retry_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/movie_category.dart';
import '../state/discover_notifier.dart';
import '../state/paged_movies_notifier.dart';
import '../state/paged_movies_state.dart';
import '../widgets/movie_poster.dart';
import '../widgets/poster_skeleton.dart';

/// Aba Descobrir: seletor de categoria e a grade da categoria escolhida, com
/// paginação infinita.
class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final discover = context.watch<DiscoverNotifier>();
    final list = discover.current;
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).discoverTitle)),
      body: Column(
        children: [
          _CategorySelector(
            selected: discover.category,
            onSelected: discover.select,
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: list,
              builder: (_, _) => _PagedMoviesView(
                key: ValueKey(discover.category),
                notifier: list,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Chips que quebram linha com fonte grande, em vez de cortar o rótulo
/// (`ui-ux-pro-max`, "Chip Collection Reflow").
class _CategorySelector extends StatelessWidget {
  const _CategorySelector({required this.selected, required this.onSelected});

  final MovieCategory selected;
  final ValueChanged<MovieCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    final spacing = Theme.of(context).extension<AppThemeTokens>()!.spacing;
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(spacing.md, spacing.sm, spacing.md, 0),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Wrap(
          spacing: spacing.sm,
          runSpacing: spacing.sm,
          children: [
            for (final category in MovieCategory.values)
              ChoiceChip(
                label: Text(_labelOf(l10n, category)),
                selected: category == selected,
                onSelected: (_) => onSelected(category),
              ),
          ],
        ),
      ),
    );
  }

  String _labelOf(AppLocalizations l10n, MovieCategory category) =>
      switch (category) {
        MovieCategory.popular => l10n.categoryPopular,
        MovieCategory.nowPlaying => l10n.categoryNowPlaying,
        MovieCategory.topRated => l10n.categoryTopRated,
      };
}

/// Os 4 estados de uma lista paginada.
class _PagedMoviesView extends StatelessWidget {
  const _PagedMoviesView({required this.notifier, super.key});

  final PagedMoviesNotifier notifier;

  @override
  Widget build(BuildContext context) => switch (notifier.state) {
    PagedMoviesLoading() => const _GridWidthGuard(child: _LoadingView()),
    PagedMoviesEmpty() => _MessageView(
      message: AppLocalizations.of(context).discoverEmpty,
      onRetry: notifier.load,
    ),
    PagedMoviesError(:final failure) => _ErrorView(
      failure: failure,
      onRetry: notifier.load,
    ),
    final PagedMoviesLoaded state => _GridWidthGuard(
      child: _MovieGrid(
        state: state,
        onLoadMore: notifier.loadMore,
        onRetryNextPage: notifier.retryNextPage,
      ),
    ),
  };
}

/// Padding e delegate comuns à grade real e ao skeleton, para o layout não
/// pular entre os estados.
EdgeInsets _gridPadding(AppThemeTokens tokens) =>
    EdgeInsets.all(tokens.spacing.md);

SliverGridDelegate _gridDelegate(AppThemeTokens tokens) =>
    SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: AppSizes.posterGridMaxExtent,
      childAspectRatio: 2 / 3,
      mainAxisSpacing: tokens.spacing.sm,
      crossAxisSpacing: tokens.spacing.sm,
    );

/// Só monta a grade quando sobra largura depois do padding. O Android pode
/// fazer o primeiro layout com a janela ainda sem largura, e o
/// `SliverGridDelegateWithMaxCrossAxisExtent` não aceita largura zero.
class _GridWidthGuard extends StatelessWidget {
  const _GridWidthGuard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final horizontalPadding = _gridPadding(tokens).horizontal;
    return LayoutBuilder(
      builder: (_, constraints) => constraints.maxWidth > horizontalPadding
          ? child
          : const SizedBox.shrink(),
    );
  }
}

/// Grade de skeleton. Um controller só faz todas as células pulsarem; com o
/// "reduzir movimento" ligado, elas ficam paradas.
class _LoadingView extends StatefulWidget {
  const _LoadingView();

  @override
  State<_LoadingView> createState() => _LoadingViewState();
}

class _LoadingViewState extends State<_LoadingView>
    with SingleTickerProviderStateMixin {
  static const _cellCount = 12;

  late final _controller = AnimationController(
    vsync: this,
    duration: AppMotion.skeletonPulse,
  );
  late final _opacity =
      Tween<double>(begin: 1, end: AppMotion.skeletonMinOpacity).animate(
        CurvedAnimation(parent: _controller, curve: AppMotion.skeletonCurve),
      );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller
        ..stop()
        ..value = 0;
    } else if (!_controller.isAnimating) {
      unawaited(_controller.repeat(reverse: true));
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
    return Semantics(
      label: AppLocalizations.of(context).discoverLoading,
      liveRegion: true,
      child: ExcludeSemantics(
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          padding: _gridPadding(tokens),
          gridDelegate: _gridDelegate(tokens),
          itemCount: _cellCount,
          itemBuilder: (_, _) => PosterSkeleton(opacity: _opacity),
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
    retryWait: retryWaitOf(failure),
    // Cada falha recomeça a contagem, mesmo com a mesma espera.
    retryKey: ObjectKey(failure),
  );
}

/// Mensagem centralizada com "Tentar de novo", usada no vazio e no erro.
class _MessageView extends StatelessWidget {
  const _MessageView({
    required this.message,
    required this.onRetry,
    this.retryWait = Duration.zero,
    this.retryKey,
  });

  final String message;
  final VoidCallback onRetry;
  final Duration retryWait;
  final Key? retryKey;

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
            RetryButton.filled(
              key: retryKey,
              onPressed: onRetry,
              wait: retryWait,
            ),
          ],
        ),
      ),
    );
  }
}

class _MovieGrid extends StatefulWidget {
  const _MovieGrid({
    required this.state,
    required this.onLoadMore,
    required this.onRetryNextPage,
  });

  final PagedMoviesLoaded state;
  final VoidCallback onLoadMore;
  final VoidCallback onRetryNextPage;

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
      controller: _controller,
      slivers: [
        SliverPadding(
          padding: _gridPadding(tokens),
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
              l10n.discoverLoadMoreFailed,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            RetryButton.text(
              key: ObjectKey(failure),
              onPressed: onRetry,
              wait: retryWaitOf(failure),
            ),
          ],
        ),
      },
    );
  }
}

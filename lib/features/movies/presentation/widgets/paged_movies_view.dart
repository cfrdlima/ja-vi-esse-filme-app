import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/error/retry_wait.dart';
import '../../../../core/l10n/failure_message.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../../../../core/widgets/retry_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../state/paged_movies_notifier.dart';
import '../state/paged_movies_state.dart';
import 'movie_poster.dart';
import 'poster_skeleton.dart';

/// Os 4 estados de uma lista paginada de filmes, com paginação infinita. O
/// vazio muda de tela para tela e vem em [empty].
class PagedMoviesView extends StatelessWidget {
  const PagedMoviesView({
    required this.notifier,
    required this.empty,
    this.scrollKey,
    super.key,
  });

  final PagedMoviesNotifier notifier;

  /// Chave do `PageStorage` em que a rolagem da grade fica guardada. Sem ela,
  /// a rolagem só vive enquanto a grade estiver montada.
  final String? scrollKey;

  final Widget empty;

  @override
  Widget build(BuildContext context) => switch (notifier.state) {
    PagedMoviesLoading() => const _GridWidthGuard(child: _LoadingView()),
    PagedMoviesEmpty() => empty,
    PagedMoviesError(:final failure) => _ErrorView(
      failure: failure,
      onRetry: notifier.load,
    ),
    final PagedMoviesLoaded state => _GridWidthGuard(
      child: _MovieGrid(
        scrollKey: scrollKey,
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
      label: AppLocalizations.of(context).moviesLoading,
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
  });

  final String? scrollKey;
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
      key: switch (widget.scrollKey) {
        final key? => PageStorageKey(key),
        null => null,
      },
      // Arrastar a grade tira o teclado da frente dos pôsteres.
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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

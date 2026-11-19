import 'dart:async';

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
import '../../../movies/presentation/widgets/paged_movies_view.dart';
import '../../../movies/presentation/widgets/poster_grid.dart';
import '../../domain/entities/movie_list.dart';
import '../../domain/entities/shelf_movie.dart';
import '../../domain/repositories/movie_copy_source.dart';
import '../../domain/repositories/movie_lists_repository.dart';
import '../../domain/repositories/shelf_repository.dart';
import '../../domain/usecases/add_movie_to_list.dart';
import '../../domain/usecases/expired_copy_renewer.dart';
import '../state/movie_list_notifier.dart';
import '../state/movie_list_state.dart';
import '../state/shelf_tab_notifier.dart';
import '../widgets/delete_list_dialog.dart';
import '../widgets/list_name_dialog.dart';
import '../widgets/shelf_movies_view.dart';
import '../widgets/write_notice.dart';

/// Uma lista personalizada, empilhada na aba Estante (override `estante.md`,
/// decisão 019). Lê do contexto o [MovieListsRepository], o
/// [ShelfRepository], o [MovieCopySource] e o [AuthRepository].
class MovieListScreen extends StatelessWidget {
  const MovieListScreen({required this.listId, this.initial, super.key});

  final String listId;

  /// A lista tocada na Estante, para o nome já aparecer; nula na URL direta.
  final MovieList? initial;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        final lists = context.read<MovieListsRepository>();
        return MovieListNotifier(
          listId: listId,
          initial: initial?.id == listId ? initial : null,
          lists: lists,
          addMovie: AddMovieToList(lists),
          account: context.read<AuthRepository>().authStateChanges,
        );
      },
      child: const _MovieListScaffold(),
    );
  }
}

class _MovieListScaffold extends StatelessWidget {
  const _MovieListScaffold();

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<MovieListNotifier>();
    final l10n = AppLocalizations.of(context);
    final state = notifier.state;
    return Scaffold(
      appBar: AppBar(
        title: switch (state) {
          MovieListFound(:final list) => Text(
            list.name.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          _ => Text(l10n.shelfTabLists),
        },
        actions: [
          if (state case MovieListFound(:final list)) _ListMenu(list: list),
        ],
      ),
      body: switch (state) {
        MovieListLoading() => PosterGridSkeleton(label: l10n.shelfLoading),
        MovieListError(:final failure) => MoviesMessage(
          message: failureMessage(l10n, failure),
          action: RetryButton.filled(
            onPressed: notifier.retry,
            wait: retryWaitOf(failure),
          ),
        ),
        MovieListGone() || MovieListSignedOut() => MoviesMessage(
          message: l10n.listGone,
          action: FilledButton(
            onPressed: () => context.go(AppRoutes.shelf),
            child: Text(l10n.listBackToLists),
          ),
        ),
        MovieListFound(:final list) => _ListMovies(
          // Outra lista é outro notifier, com outra assinatura.
          key: ValueKey(list.id),
          list: list,
        ),
      },
    );
  }
}

class _ListMovies extends StatelessWidget {
  const _ListMovies({required this.list, super.key});

  final MovieList list;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ChangeNotifierProvider(
      create: (context) {
        final lists = context.read<MovieListsRepository>();
        final shelf = context.read<ShelfRepository>();
        final source = context.read<MovieCopySource>();
        return ShelfTabNotifier(
          watchPage: (limit) => lists.watchList(list, limit: limit),
          account: context.read<AuthRepository>().authStateChanges,
          newRenewer: () => ExpiredCopyRenewer(
            shelf: shelf,
            source: source,
            now: () => DateTime.now().toUtc(),
          ),
        );
      },
      child: ShelfMoviesView(
        emptyMessage: l10n.listEmpty,
        scrollKey: 'lista-${list.id}',
        detailsPath: (movieId) =>
            AppRoutes.movieDetails(AppRoutes.shelfList(list.id), movieId),
        onLongPress: (movie) => unawaited(_offerRemoval(context, movie)),
        longPressLabel: l10n.listRemoveMovie,
      ),
    );
  }

  /// A folha do toque longo, com o título do filme e o "Tirar da lista".
  Future<void> _offerRemoval(BuildContext context, ShelfMovie movie) async {
    final remove = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (_) => _RemovalSheet(movie: movie),
    );
    if (remove != true || !context.mounted) return;
    final notifier = context.read<MovieListNotifier>();
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    await runWithNotice(
      messenger,
      l10n,
      () => notifier.removeMovie(movie),
      onSuccess: SnackBar(
        content: Text(l10n.listMovieRemoved),
        action: SnackBarAction(
          label: l10n.listUndo,
          onPressed: () => unawaited(
            runWithNotice(messenger, l10n, () => notifier.undoRemove(movie)),
          ),
        ),
      ),
    );
  }
}

class _RemovalSheet extends StatelessWidget {
  const _RemovalSheet({required this.movie});

  final ShelfMovie movie;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.extension<AppThemeTokens>()!.spacing;
    final l10n = AppLocalizations.of(context);
    // A cópia vencida não aparece como atual (decisão 013).
    final title = movie.isCopyExpired(DateTime.now().toUtc())
        ? l10n.shelfCopyUpdating
        : movie.copy.title;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: spacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: spacing.lg),
              child: Text(title, style: theme.textTheme.titleLarge),
            ),
            SizedBox(height: spacing.sm),
            ListTile(
              leading: const Icon(Icons.playlist_remove),
              title: Text(l10n.listRemoveMovie),
              onTap: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      ),
    );
  }
}

enum _ListAction { rename, delete }

class _ListMenu extends StatelessWidget {
  const _ListMenu({required this.list});

  final MovieList list;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopupMenuButton<_ListAction>(
      tooltip: l10n.listsOptions(list.name.value),
      icon: const Icon(Icons.more_vert),
      onSelected: (action) => unawaited(_onAction(context, action)),
      itemBuilder: (_) => [
        PopupMenuItem(value: _ListAction.rename, child: Text(l10n.listsRename)),
        PopupMenuItem(value: _ListAction.delete, child: Text(l10n.listsDelete)),
      ],
    );
  }

  Future<void> _onAction(BuildContext context, _ListAction action) async {
    final notifier = context.read<MovieListNotifier>();
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    switch (action) {
      case _ListAction.rename:
        final name = await ListNameDialog.show(context, initial: list.name);
        if (name == null || name == list.name) return;
        await runWithNotice(messenger, l10n, () => notifier.rename(name));
      case _ListAction.delete:
        if (!await DeleteListDialog.confirm(context, list)) return;
        if (!context.mounted) return;
        final router = GoRouter.of(context);
        await runWithNotice(messenger, l10n, () async {
          await notifier.delete();
          router.go(AppRoutes.shelf);
        }, onSuccess: SnackBar(content: Text(l10n.listsDeleted)));
    }
  }
}

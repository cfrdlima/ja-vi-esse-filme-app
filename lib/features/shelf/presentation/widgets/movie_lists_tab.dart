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
import '../../domain/entities/movie_list.dart';
import '../../domain/repositories/movie_lists_repository.dart';
import '../../domain/usecases/create_movie_list.dart';
import '../state/movie_lists_notifier.dart';
import '../state/movie_lists_state.dart';
import 'delete_list_dialog.dart';
import 'list_name_dialog.dart';
import 'list_rows_skeleton.dart';
import 'write_notice.dart';

/// A aba Listas da Estante com o notifier dela (decisão 019). Fica viva no
/// `TabBarView`, como as abas das marcas. Lê do contexto o
/// [MovieListsRepository] e o [AuthRepository].
class MovieListsTab extends StatefulWidget {
  const MovieListsTab({super.key});

  @override
  State<MovieListsTab> createState() => _MovieListsTabState();
}

class _MovieListsTabState extends State<MovieListsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ChangeNotifierProvider(
      create: (context) {
        final lists = context.read<MovieListsRepository>();
        return MovieListsNotifier(
          lists: lists,
          createList: CreateMovieList(lists),
          account: context.read<AuthRepository>().authStateChanges,
        );
      },
      child: MovieListsTabView(
        onOpen: (list) => context.go(AppRoutes.shelfList(list.id), extra: list),
      ),
    );
  }
}

/// Os 4 estados da aba Listas (override `estante.md`).
class MovieListsTabView extends StatelessWidget {
  const MovieListsTabView({required this.onOpen, super.key});

  final ValueChanged<MovieList> onOpen;

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<MovieListsNotifier>();
    final l10n = AppLocalizations.of(context);
    return switch (notifier.state) {
      // Sem conta, a Estante inteira já é o convite.
      MovieListsLoading() || MovieListsSignedOut() => SingleChildScrollView(
        child: ListRowsSkeleton(label: l10n.listsLoading),
      ),
      MovieListsEmpty() => MoviesMessage(
        message: l10n.listsEmpty,
        action: FilledButton(
          onPressed: () => unawaited(createList(context)),
          child: Text(l10n.listsCreateAction),
        ),
      ),
      MovieListsError(:final failure) => MoviesMessage(
        message: failureMessage(l10n, failure),
        action: RetryButton.filled(
          onPressed: notifier.retry,
          wait: retryWaitOf(failure),
        ),
      ),
      final MovieListsReady state => _ListsView(state: state, onOpen: onOpen),
    };
  }
}

/// Abre o diálogo do nome e cria a lista, com o aviso da recusa.
Future<void> createList(BuildContext context) async {
  final notifier = context.read<MovieListsNotifier>();
  final name = await ListNameDialog.show(context);
  if (name == null || !context.mounted) return;
  await runWithNotice(
    ScaffoldMessenger.of(context),
    AppLocalizations.of(context),
    () => notifier.create(name),
  );
}

class _ListsView extends StatelessWidget {
  const _ListsView({required this.state, required this.onOpen});

  final MovieListsReady state;
  final ValueChanged<MovieList> onOpen;

  @override
  Widget build(BuildContext context) {
    final lists = state.lists;
    return ListView.builder(
      key: const PageStorageKey('estante-listas'),
      itemCount: lists.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) return _NewListHeader(atLimit: state.atLimit);
        final item = lists[index - 1];
        return _ListTile(
          key: ValueKey(item.list.id),
          item: item,
          onOpen: onOpen,
        );
      },
    );
  }
}

class _NewListHeader extends StatelessWidget {
  const _NewListHeader({required this.atLimit});

  final bool atLimit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.extension<AppThemeTokens>()!.spacing;
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.all(spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FilledButton.tonalIcon(
            onPressed: atLimit ? null : () => unawaited(createList(context)),
            icon: const Icon(Icons.add),
            label: Text(l10n.listsNew),
          ),
          if (atLimit) ...[
            SizedBox(height: spacing.sm),
            Text(
              l10n.listsAtLimit(MovieList.maxPerAccount),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

enum _ListAction { rename, delete }

class _ListTile extends StatelessWidget {
  const _ListTile({required this.item, required this.onOpen, super.key});

  final MovieListItem item;
  final ValueChanged<MovieList> onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final list = item.list;
    final name = list.name.value;
    if (item.deleting) {
      return Semantics(
        label: l10n.listsDeleting(name),
        excludeSemantics: true,
        child: ListTile(
          enabled: false,
          leading: const Icon(Icons.list),
          title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: const SizedBox.square(
            dimension: kMinInteractiveDimension,
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      );
    }
    return ListTile(
      leading: const ExcludeSemantics(child: Icon(Icons.list)),
      title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
      onTap: () => onOpen(list),
      trailing: PopupMenuButton<_ListAction>(
        tooltip: l10n.listsOptions(name),
        icon: const Icon(Icons.more_vert),
        onSelected: (action) => unawaited(_onAction(context, action)),
        itemBuilder: (_) => [
          PopupMenuItem(
            value: _ListAction.rename,
            child: Text(l10n.listsRename),
          ),
          PopupMenuItem(
            value: _ListAction.delete,
            child: Text(l10n.listsDelete),
          ),
        ],
      ),
    );
  }

  Future<void> _onAction(BuildContext context, _ListAction action) async {
    final notifier = context.read<MovieListsNotifier>();
    final list = item.list;
    switch (action) {
      case _ListAction.rename:
        final name = await ListNameDialog.show(context, initial: list.name);
        if (name == null || name == list.name || !context.mounted) return;
        await runWithNotice(
          ScaffoldMessenger.of(context),
          AppLocalizations.of(context),
          () => notifier.rename(list, name),
        );
      case _ListAction.delete:
        if (!await DeleteListDialog.confirm(context, list)) return;
        if (!context.mounted) return;
        final l10n = AppLocalizations.of(context);
        await runWithNotice(
          ScaffoldMessenger.of(context),
          l10n,
          () => notifier.delete(list),
          onSuccess: SnackBar(content: Text(l10n.listsDeleted)),
        );
    }
  }
}

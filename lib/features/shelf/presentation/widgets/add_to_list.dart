import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/l10n/failure_message.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../../../../core/widgets/retry_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/widgets/sign_in_sheet.dart';
import '../../domain/entities/movie_copy.dart';
import '../../domain/entities/shelf_entry.dart';
import '../../domain/repositories/movie_lists_repository.dart';
import '../../domain/usecases/add_movie_to_list.dart';
import '../../domain/usecases/create_movie_list.dart';
import '../state/add_to_list_notifier.dart';
import '../state/add_to_list_state.dart';
import '../state/shelf_marks_notifier.dart';
import '../state/shelf_marks_state.dart';
import 'list_name_dialog.dart';
import 'list_rows_skeleton.dart';

/// O "Adicionar à lista" dos Detalhes (override `detalhes.md`, decisão
/// 019). Lê o [ShelfMarksNotifier] do contexto, que diz se há conta e em
/// que listas o filme está, e abre a folha das listas.
class AddToListButton extends StatelessWidget {
  const AddToListButton({required this.copy, super.key});

  final MovieCopy copy;

  @override
  Widget build(BuildContext context) {
    final marks = context.watch<ShelfMarksNotifier>();
    return switch (marks.state) {
      // As marcas já mostram o carregando e o erro.
      ShelfMarksLoading() || ShelfMarksError() => const SizedBox.shrink(),
      ShelfMarksSignedOut() => _Button(
        inLists: false,
        onPressed: () => unawaited(_signInThenOpen(context)),
      ),
      ShelfMarksReady() => ValueListenableBuilder(
        valueListenable: marks.confirmedEntry,
        builder: (context, entry, _) => _Button(
          inLists: switch (entry) {
            OnShelf(:final movie) => movie.listIds.isNotEmpty,
            _ => false,
          },
          onPressed: () => unawaited(_open(context)),
        ),
      ),
    };
  }

  // O notifier é lido antes da folha de login, como nas marcas.
  Future<void> _signInThenOpen(BuildContext context) async {
    final signedIn = await showSignInSheet(context);
    if (signedIn && context.mounted) await _open(context);
  }

  Future<void> _open(BuildContext context) {
    final entry = context.read<ShelfMarksNotifier>().confirmedEntry;
    final lists = context.read<MovieListsRepository>();
    final radius = Theme.of(context).extension<AppThemeTokens>()!.radii.lg;
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
      ),
      builder: (_) => ChangeNotifierProvider(
        create: (_) => AddToListNotifier(
          lists: lists,
          createList: CreateMovieList(lists),
          addMovie: AddMovieToList(lists),
          copy: copy,
          entry: entry,
        ),
        child: const AddToListSheet(),
      ),
    );
  }
}

class _Button extends StatelessWidget {
  const _Button({required this.inLists, required this.onPressed});

  final bool inLists;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final spacing = Theme.of(context).extension<AppThemeTokens>()!.spacing;
    return Padding(
      padding: EdgeInsets.only(top: spacing.sm),
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(inLists ? Icons.playlist_add_check : Icons.playlist_add),
        label: Text(inLists ? l10n.addToListInLists : l10n.addToListAction),
      ),
    );
  }
}

/// A folha com as listas da conta e o filme dentro ou não, com o
/// [AddToListNotifier] do contexto. Cada caixa grava sozinha: fechar a folha
/// não desfaz nada.
class AddToListSheet extends StatelessWidget {
  const AddToListSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.extension<AppThemeTokens>()!.spacing;
    final l10n = AppLocalizations.of(context);
    final notifier = context.watch<AddToListNotifier>();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: spacing.lg),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.addToListAction,
                  style: theme.textTheme.titleLarge,
                ),
              ),
              const CloseButton(),
            ],
          ),
        ),
        Flexible(
          child: switch (notifier.state) {
            AddToListLoading() => SingleChildScrollView(
              child: ListRowsSkeleton(label: l10n.listsLoading, rows: 3),
            ),
            AddToListError(:final failure) => _SheetMessage(
              message: failureMessage(l10n, failure),
              onRetry: notifier.retry,
            ),
            final AddToListReady state => _SheetLists(state: state),
          },
        ),
      ],
    );
  }
}

class _SheetLists extends StatelessWidget {
  const _SheetLists({required this.state});

  final AddToListReady state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.extension<AppThemeTokens>()!.spacing;
    final l10n = AppLocalizations.of(context);
    final notifier = context.read<AddToListNotifier>();
    final failure = state.failure;
    return ListView(
      shrinkWrap: true,
      padding: EdgeInsets.only(bottom: spacing.md),
      children: [
        if (state.items.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.lg,
              vertical: spacing.sm,
            ),
            child: Text(
              l10n.addToListNone,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        for (final item in state.items)
          CheckboxListTile(
            key: ValueKey(item.list.id),
            value: item.checked,
            onChanged: (_) => notifier.toggle(item.list),
            title: Text(
              item.list.name.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ListTile(
          leading: const Icon(Icons.add),
          title: Text(l10n.listsNew),
          onTap: () => unawaited(_createAndAdd(context)),
        ),
        if (failure != null)
          _SheetMessage(
            message: failureMessage(l10n, failure),
            onRetry: notifier.retryToggle,
          ),
      ],
    );
  }

  Future<void> _createAndAdd(BuildContext context) async {
    final notifier = context.read<AddToListNotifier>();
    final name = await ListNameDialog.show(context);
    if (name != null) await notifier.createAndAdd(name);
  }
}

class _SheetMessage extends StatelessWidget {
  const _SheetMessage({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.extension<AppThemeTokens>()!.spacing;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: spacing.lg),
      child: Semantics(
        liveRegion: true,
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: spacing.sm,
          children: [
            Text(message, style: theme.textTheme.bodyMedium),
            RetryButton.text(onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}

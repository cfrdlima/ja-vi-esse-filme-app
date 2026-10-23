import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/search_query.dart';
import '../state/search_notifier.dart';
import '../widgets/paged_movies_view.dart';

/// Aba Buscar: campo de busca e a grade do termo digitado, com paginação
/// infinita.
class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final search = context.watch<SearchNotifier>();
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).searchTitle)),
      body: Column(
        children: [
          _SearchField(
            onChanged: search.onQueryChanged,
            onSubmitted: search.submit,
            onCleared: search.clear,
          ),
          Expanded(child: _SearchBody(state: search.state)),
        ],
      ),
    );
  }
}

/// Campo com rótulo visível (`ui-ux-pro-max`, "Input Labels") e botão de
/// limpar quando há texto.
class _SearchField extends StatefulWidget {
  const _SearchField({
    required this.onChanged,
    required this.onSubmitted,
    required this.onCleared,
  });

  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onCleared;

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  void _clear() {
    _controller.clear();
    widget.onCleared();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spacing = Theme.of(context).extension<AppThemeTokens>()!.spacing;
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(spacing.md, spacing.sm, spacing.md, 0),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        maxLength: SearchQuery.maxLength,
        textInputAction: TextInputAction.search,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        decoration: InputDecoration(
          labelText: l10n.searchFieldLabel,
          prefixIcon: const Icon(Icons.search),
          // O limite existe para o TMDB, e não para a pessoa acompanhar.
          counterText: '',
          suffixIcon: ListenableBuilder(
            listenable: _controller,
            builder: (_, _) => _controller.text.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    tooltip: l10n.searchClear,
                    icon: const Icon(Icons.close),
                    onPressed: _clear,
                  ),
          ),
        ),
      ),
    );
  }
}

class _SearchBody extends StatelessWidget {
  const _SearchBody({required this.state});

  final SearchState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return switch (state) {
      SearchIdle() => const _IdleView(),
      SearchTooLong() => MoviesMessage(
        message: l10n.searchTooLong(SearchQuery.maxLength),
      ),
      SearchActive(:final results) => ListenableBuilder(
        listenable: results,
        builder: (_, _) => PagedMoviesView(
          // Um termo novo é uma grade nova, que começa do topo.
          key: ObjectKey(results),
          notifier: results,
          // Repetir a mesma busca daria o mesmo vazio: a ação é mudar o termo.
          empty: MoviesMessage(message: l10n.searchEmpty(results.query.text)),
        ),
      ),
    };
  }
}

class _IdleView extends StatelessWidget {
  const _IdleView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.extension<AppThemeTokens>()!.spacing;
    // Rolável para a fonte grande não vazar com o teclado aberto.
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(spacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search,
              size: AppSizes.stateIcon,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            SizedBox(height: spacing.md),
            Text(
              AppLocalizations.of(context).searchIdle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

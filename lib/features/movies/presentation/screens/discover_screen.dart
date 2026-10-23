import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme_tokens.dart';
import '../../../../core/widgets/retry_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/movie_category.dart';
import '../state/discover_notifier.dart';
import '../widgets/paged_movies_view.dart';

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
              builder: (_, _) => PagedMoviesView(
                key: ValueKey(list.category),
                notifier: list,
                // A rolagem de cada categoria fica no PageStorage da rota, e
                // voltar a uma categoria volta ao mesmo ponto.
                scrollKey: 'discover-${list.category.name}',
                empty: MoviesMessage(
                  message: AppLocalizations.of(context).discoverEmpty,
                  action: RetryButton.filled(onPressed: list.load),
                ),
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

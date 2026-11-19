import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/entities/shelf_mark.dart';
import '../../domain/repositories/movie_copy_source.dart';
import '../../domain/repositories/shelf_repository.dart';
import '../../domain/usecases/expired_copy_renewer.dart';
import '../state/shelf_tab_notifier.dart';
import 'shelf_movies_view.dart';

/// Uma aba da Estante com o notifier dela. Fica viva no `TabBarView`, com os
/// filmes e a rolagem, depois da primeira vez que é aberta.
class ShelfTab extends StatefulWidget {
  const ShelfTab({required this.mark, required this.index, super.key});

  final ShelfMark mark;

  /// A posição no `TabController`, para só a aba visível ter o Hero.
  final int index;

  @override
  State<ShelfTab> createState() => _ShelfTabState();
}

class _ShelfTabState extends State<ShelfTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ChangeNotifierProvider(
      create: (context) {
        final shelf = context.read<ShelfRepository>();
        final source = context.read<MovieCopySource>();
        return ShelfTabNotifier(
          watchPage: (limit) => shelf.watchShelf(widget.mark, limit: limit),
          account: context.read<AuthRepository>().authStateChanges,
          newRenewer: () => ExpiredCopyRenewer(
            shelf: shelf,
            source: source,
            now: () => DateTime.now().toUtc(),
          ),
        );
      },
      child: ShelfTabView(mark: widget.mark, index: widget.index),
    );
  }
}

/// Os 4 estados de uma aba (override `estante.md`).
class ShelfTabView extends StatelessWidget {
  const ShelfTabView({required this.mark, required this.index, super.key});

  final ShelfMark mark;
  final int index;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tabs = DefaultTabController.of(context);
    return ShelfMoviesView(
      emptyMessage: _emptyMessage(l10n, mark),
      scrollKey: 'estante-${mark.name}',
      // O mesmo filme pode estar em duas abas vivas, e os Detalhes esperam
      // a tag `poster-<id>`: só a aba visível tem o Hero.
      heroListenable: tabs,
      withHero: () => tabs.index == index,
      detailsPath: (movieId) =>
          AppRoutes.movieDetails(AppRoutes.shelf, movieId),
    );
  }

  static String _emptyMessage(AppLocalizations l10n, ShelfMark mark) =>
      switch (mark) {
        ShelfMark.watched => l10n.shelfEmptyWatched,
        ShelfMark.watchlist => l10n.shelfEmptyWatchlist,
        ShelfMark.favorite => l10n.shelfEmptyFavorite,
      };
}

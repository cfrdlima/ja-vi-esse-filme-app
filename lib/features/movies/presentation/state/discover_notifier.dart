import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/entities/movie_category.dart';
import '../../domain/repositories/movie_repository.dart';
import 'paged_movies_notifier.dart';

/// Categoria escolhida na Descobrir e uma lista paginada por categoria. As
/// listas ficam vivas: voltar a uma categoria mostra os filmes e a página já
/// carregados, sem pedir de novo ao TMDB.
class DiscoverNotifier extends ChangeNotifier {
  DiscoverNotifier({required this._repository});

  final MovieRepository _repository;
  final _lists = <MovieCategory, PagedMoviesNotifier>{};
  final _started = <MovieCategory>{};

  MovieCategory _category = MovieCategory.popular;
  MovieCategory get category => _category;

  /// Lista da categoria escolhida. Só [select] dispara o carregamento.
  PagedMoviesNotifier get current => _lists.putIfAbsent(
    _category,
    () => PagedMoviesNotifier(repository: _repository, category: _category),
  );

  /// Mostra a [category] e carrega a lista dela na primeira vez.
  void select(MovieCategory category) {
    final changed = category != _category;
    _category = category;
    // O notifier da lista guarda o resultado, inclusive a falha, no estado.
    if (_started.add(category)) unawaited(current.load());
    if (changed) notifyListeners();
  }

  @override
  void dispose() {
    for (final list in _lists.values) {
      list.dispose();
    }
    super.dispose();
  }
}

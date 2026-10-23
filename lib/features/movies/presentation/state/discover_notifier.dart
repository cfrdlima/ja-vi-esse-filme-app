import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/entities/movie_category.dart';
import '../../domain/repositories/movie_repository.dart';
import 'paged_movies_notifier.dart';

/// Categoria escolhida na Descobrir e uma lista paginada por categoria. As
/// listas ficam vivas: voltar a uma categoria mostra os filmes e a página já
/// carregados, sem pedir de novo ao TMDB.
class DiscoverNotifier extends ChangeNotifier {
  /// Já começa carregando a [initial]: a aba nunca mostra uma lista que
  /// ninguém pediu.
  DiscoverNotifier({
    required this._repository,
    MovieCategory initial = MovieCategory.popular,
  }) : _category = initial {
    _open(initial);
  }

  final MovieRepository _repository;
  final _lists = <MovieCategory, PagedMoviesNotifier>{};

  MovieCategory _category;
  MovieCategory get category => _category;

  PagedMoviesNotifier get current => _lists[_category]!;

  /// Mostra a [category] e carrega a lista dela na primeira vez.
  void select(MovieCategory category) {
    if (category == _category) return;
    _category = category;
    _open(category);
    notifyListeners();
  }

  void _open(MovieCategory category) {
    if (_lists.containsKey(category)) return;
    final list = PagedMoviesNotifier(
      repository: _repository,
      category: category,
    );
    _lists[category] = list;
    // A lista guarda o resultado, inclusive a falha, no estado.
    unawaited(list.load());
  }

  @override
  void dispose() {
    for (final list in _lists.values) {
      list.dispose();
    }
    super.dispose();
  }
}

import 'package:flutter/foundation.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/movie.dart';
import '../../domain/entities/movie_page.dart';
import '../../domain/repositories/movie_repository.dart';
import 'popular_movies_state.dart';

class PopularMoviesNotifier extends ChangeNotifier {
  PopularMoviesNotifier({required this._repository});

  final MovieRepository _repository;

  PopularMoviesState _state = const PopularMoviesLoading();
  PopularMoviesState get state => _state;

  bool _loadingFirstPage = false;
  bool _disposed = false;

  /// Carrega a primeira página. Serve também para "tentar de novo".
  Future<void> load() async {
    if (_loadingFirstPage) return;
    _loadingFirstPage = true;
    _emit(const PopularMoviesLoading());
    try {
      final page = await _repository.popular(page: 1);
      _emit(
        page.movies.isEmpty
            ? const PopularMoviesEmpty()
            : PopularMoviesLoaded(
                movies: page.movies,
                page: page.page,
                hasMore: page.hasMore,
              ),
      );
    } on Failure catch (failure) {
      _emit(PopularMoviesError(failure));
    } finally {
      _loadingFirstPage = false;
    }
  }

  /// Pede a próxima página; serve também para "tentar de novo" no rodapé.
  /// Não faz nada sem lista carregada, na última página ou com um pedido em
  /// andamento.
  Future<void> loadMore() async {
    final current = _state;
    if (current is! PopularMoviesLoaded ||
        !current.hasMore ||
        current.nextPage == NextPageStatus.loading) {
      return;
    }
    _emit(_copy(current, nextPage: NextPageStatus.loading));
    try {
      final page = await _repository.popular(page: current.page + 1);
      _emit(_append(current, page));
    } on Failure {
      _emit(_copy(current, nextPage: NextPageStatus.failed));
    }
  }

  // A ordem por popularidade muda entre pedidos, e o TMDB pode repetir um
  // filme na página seguinte; repetido quebraria o Hero e as chaves da grade.
  PopularMoviesLoaded _append(PopularMoviesLoaded current, MoviePage page) {
    final known = {for (final movie in current.movies) movie.id};
    return PopularMoviesLoaded(
      movies: [
        ...current.movies,
        ...page.movies.where((Movie movie) => known.add(movie.id)),
      ],
      page: page.page,
      hasMore: page.hasMore,
    );
  }

  PopularMoviesLoaded _copy(
    PopularMoviesLoaded current, {
    required NextPageStatus nextPage,
  }) => PopularMoviesLoaded(
    movies: current.movies,
    page: current.page,
    hasMore: current.hasMore,
    nextPage: nextPage,
  );

  void _emit(PopularMoviesState state) {
    if (_disposed) return;
    _state = state;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

import 'package:flutter/foundation.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/movie.dart';
import '../../domain/entities/movie_category.dart';
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

  /// Muda a cada [load]; uma resposta de [loadMore] de uma geração anterior
  /// chega atrasada e é descartada, para não sobrescrever a lista nova.
  int _generation = 0;

  /// Carrega a primeira página. Serve também para "tentar de novo".
  Future<void> load() async {
    if (_loadingFirstPage) return;
    _loadingFirstPage = true;
    final generation = ++_generation;
    _emit(const PopularMoviesLoading());
    try {
      final page = await _fetch(1);
      if (generation != _generation) return;
      final movies = _withoutRepeated(const [], page.movies);
      _emit(
        movies.isEmpty
            ? const PopularMoviesEmpty()
            : PopularMoviesLoaded(
                movies: movies,
                page: 1,
                hasMore: page.hasMore,
              ),
      );
    } on Failure catch (failure) {
      if (generation == _generation) _emit(PopularMoviesError(failure));
    } finally {
      _loadingFirstPage = false;
    }
  }

  /// Pedido da rolagem. Não faz nada sem lista, na última página, com um
  /// pedido em andamento ou depois de uma falha: aí só [retryNextPage] tenta
  /// de novo, para a rolagem não martelar o TMDB (ex.: num 429).
  Future<void> loadMore() async {
    final current = _state;
    if (current is PopularMoviesLoaded &&
        current.hasMore &&
        current.nextPage == NextPageStatus.idle) {
      await _fetchNextPage(current);
    }
  }

  /// "Tentar de novo" do rodapé, depois de a próxima página falhar.
  Future<void> retryNextPage() async {
    final current = _state;
    if (current is PopularMoviesLoaded &&
        current.nextPage == NextPageStatus.failed) {
      await _fetchNextPage(current);
    }
  }

  Future<void> _fetchNextPage(PopularMoviesLoaded current) async {
    final generation = _generation;
    final nextPage = current.page + 1;
    _emit(current.withNextPage(NextPageStatus.loading));
    try {
      final page = await _fetch(nextPage);
      if (generation != _generation) return;
      _emit(
        PopularMoviesLoaded(
          movies: _withoutRepeated(current.movies, page.movies),
          // A página pedida, e não a que a resposta diz, para o avanço não
          // depender do eco do servidor.
          page: nextPage,
          hasMore: page.hasMore,
        ),
      );
    } on Failure {
      if (generation == _generation) {
        _emit(current.withNextPage(NextPageStatus.failed));
      }
    }
  }

  /// O `TmdbClient` só lança [Failure]; qualquer outra exceção vira falha
  /// inesperada, para a tela não ficar carregando para sempre. `Error` (bug)
  /// continua subindo de propósito.
  Future<MoviePage> _fetch(int page) async {
    try {
      return await _repository.byCategory(MovieCategory.popular, page: page);
    } on Failure {
      rethrow;
    } on Exception {
      throw const UnexpectedFailure('exceção fora das falhas tipadas');
    }
  }

  // A ordem por popularidade muda entre pedidos, e o TMDB pode repetir um
  // filme, até na mesma página; repetido quebraria as chaves da grade.
  List<Movie> _withoutRepeated(List<Movie> current, List<Movie> incoming) {
    final known = {for (final movie in current) movie.id};
    return [...current, ...incoming.where((movie) => known.add(movie.id))];
  }

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

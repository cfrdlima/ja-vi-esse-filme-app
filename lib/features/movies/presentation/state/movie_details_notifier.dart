import 'package:flutter/foundation.dart';

import '../../../../core/error/failures.dart';
import '../../domain/repositories/movie_repository.dart';
import 'movie_details_state.dart';

/// Detalhes de um filme, carregados uma vez por tela.
class MovieDetailsNotifier extends ChangeNotifier {
  MovieDetailsNotifier({required this._repository, required this._movieId});

  final MovieRepository _repository;

  /// Vem da URL: `null` quando o texto não é número.
  final int? _movieId;

  MovieDetailsState _state = const MovieDetailsLoading();
  MovieDetailsState get state => _state;

  bool _loading = false;
  bool _disposed = false;

  /// Carrega os detalhes. Serve também para "tentar de novo".
  Future<void> load() async {
    if (_disposed || _loading) return;
    final movieId = _movieId;
    // Um id que não é de filme nenhum é endereço errado, e não bug: vai para
    // o "não encontrado" sem gastar pedido (o repositório recusaria).
    if (movieId == null || movieId < 1) {
      _emit(const MovieDetailsNotFound());
      return;
    }
    _loading = true;
    _emit(const MovieDetailsLoading());
    try {
      _emit(MovieDetailsLoaded(await _repository.details(movieId)));
    } on NotFoundFailure {
      _emit(const MovieDetailsNotFound());
    } on Failure catch (failure) {
      _emit(MovieDetailsError(failure));
    } on Exception {
      // O `TmdbClient` só lança Failure; outra exceção não pode deixar a tela
      // carregando para sempre. `Error` (bug) continua subindo.
      _emit(
        const MovieDetailsError(
          UnexpectedFailure('exceção fora das falhas tipadas'),
        ),
      );
    } finally {
      _loading = false;
    }
  }

  void _emit(MovieDetailsState state) {
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

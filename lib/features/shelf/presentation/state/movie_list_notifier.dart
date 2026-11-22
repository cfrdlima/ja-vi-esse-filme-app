import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/error/failures.dart';
import '../../../auth/domain/entities/auth_state.dart';
import '../../domain/entities/list_name.dart';
import '../../domain/entities/movie_list.dart';
import '../../domain/entities/shelf_entry.dart';
import '../../domain/entities/shelf_movie.dart';
import '../../domain/repositories/movie_copy_source.dart';
import '../../domain/repositories/movie_lists_repository.dart';
import '../../domain/usecases/add_movie_to_list.dart';
import 'movie_list_state.dart';

/// O cabeçalho e as ações da tela de uma lista (decisão 019): acha a lista
/// [listId] no `watchLists` da conta, para o nome ficar em dia e para saber
/// quando ela foi apagada. Os filmes ficam com o `ShelfTabNotifier`.
class MovieListNotifier extends ChangeNotifier {
  MovieListNotifier({
    required this._listId,
    required MovieList? initial,
    required this._lists,
    required this._addMovie,
    required this._copySource,
    required this._now,
    required Stream<AuthState> account,
  }) : _confirmed = initial {
    if (initial != null) _state = MovieListFound(initial);
    _accountSubscription = account.listen(
      _onAccount,
      onError: (Object _) => _onAccount(const SignedOut()),
    );
  }

  final String _listId;
  final MovieListsRepository _lists;
  final AddMovieToList _addMovie;
  final MovieCopySource _copySource;
  final DateTime Function() _now;
  late final StreamSubscription<AuthState> _accountSubscription;
  StreamSubscription<List<MovieList>>? _listsSubscription;

  String? _uid;

  /// A lista do último evento, sem o nome otimista.
  MovieList? _confirmed;
  ListName? _renamed;
  bool _deleting = false;
  bool _disposed = false;

  MovieListState _state = const MovieListLoading();
  MovieListState get state => _state;

  void retry() {
    if (_uid != null) _subscribe();
  }

  /// Mostra o nome novo na hora; a recusa do servidor volta o antigo.
  Future<void> rename(ListName name) async {
    final list = _confirmed;
    if (list == null) return;
    _renamed = name;
    _emitFound();
    try {
      await _lists.renameList(list, name);
    } on Exception {
      _renamed = null;
      _emitFound();
      rethrow;
    }
  }

  /// Espera o servidor (decisão 019); a tela sai quando completa. Um
  /// segundo pedido com o primeiro a caminho não faz nada.
  Future<void> delete() async {
    final list = _confirmed;
    if (list == null || _deleting) return;
    _deleting = true;
    _emitFound();
    try {
      await _lists.deleteList(list);
    } finally {
      _deleting = false;
      _emitFound();
    }
  }

  /// Tira o [movie] da lista; ele some da grade pelo stream.
  Future<void> removeMovie(ShelfMovie movie) async {
    if (_confirmed case final list?) {
      await _lists.removeFromList(movie, list);
    }
  }

  /// Põe de volta o filme tirado, que entra no topo: a hora é a do servidor.
  /// Com a cópia vencida, busca outra no TMDB: regravar a velha renovaria o
  /// prazo de dados de mais de 6 meses (decisão 013).
  Future<void> undoRemove(ShelfMovie movie) async {
    final list = _confirmed;
    if (list == null) return;
    final copy = movie.isCopyExpired(_now())
        ? await _copySource.fetchCopy(movie.copy.movieId)
        : movie.copy;
    await _addMovie(copy, list, current: const NotOnShelf());
  }

  void _onAccount(AuthState account) {
    switch (account) {
      case SignedIn(:final user) when user.uid == _uid:
        return;
      case SignedIn(:final user):
        _uid = user.uid;
        _subscribe();
      case SignedOut():
        unawaited(_listsSubscription?.cancel());
        _listsSubscription = null;
        _uid = null;
        // Um "Desfazer" depois do logout cairia na conta seguinte.
        _confirmed = null;
        _renamed = null;
        _emit(const MovieListSignedOut());
    }
  }

  void _subscribe() {
    unawaited(_listsSubscription?.cancel());
    _listsSubscription = _lists.watchLists().listen(
      _onLists,
      onError: (Object error) => _emit(
        MovieListError(
          error is Failure
              ? error
              : const UnexpectedFailure('erro fora das falhas na lista'),
        ),
      ),
      // O stream só acaba no logout, que a conta avisa logo depois.
      onDone: () => _listsSubscription = null,
    );
  }

  void _onLists(List<MovieList> lists) {
    final found = lists.where((list) => list.id == _listId).firstOrNull;
    _confirmed = found;
    if (found == null) {
      _renamed = null;
      _emit(const MovieListGone());
      return;
    }
    if (_renamed == found.name) _renamed = null;
    _emitFound();
  }

  void _emitFound() {
    final list = _confirmed;
    if (list == null) return;
    _emit(
      MovieListFound(switch (_renamed) {
        final ListName name => list.rename(name),
        null => list,
      }, deleting: _deleting),
    );
  }

  void _emit(MovieListState state) {
    if (_disposed) return;
    _state = state;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_accountSubscription.cancel());
    unawaited(_listsSubscription?.cancel());
    super.dispose();
  }
}

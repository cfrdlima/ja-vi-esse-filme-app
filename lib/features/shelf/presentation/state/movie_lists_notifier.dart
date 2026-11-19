import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/error/failures.dart';
import '../../../auth/domain/entities/auth_state.dart';
import '../../domain/entities/list_name.dart';
import '../../domain/entities/movie_list.dart';
import '../../domain/repositories/movie_lists_repository.dart';
import '../../domain/usecases/create_movie_list.dart';
import 'movie_lists_state.dart';

/// A aba Listas (decisão 019). Segue o `watchLists` da conta logada e assina
/// de novo quando a conta muda, como as abas das marcas.
///
/// Criar e renomear são otimistas, como as marcas: a mudança aparece na hora
/// e só a recusa do servidor a desfaz. Apagar espera o servidor. Os futures
/// de [create], [rename] e [delete] entregam a falha a quem chamou, para a
/// tela mostrar o aviso com "tentar de novo".
class MovieListsNotifier extends ChangeNotifier {
  MovieListsNotifier({
    required this._lists,
    required this._createList,
    required Stream<AuthState> account,
  }) {
    _accountSubscription = account.listen(
      _onAccount,
      onError: (Object _) => _onAccount(const SignedOut()),
    );
  }

  final MovieListsRepository _lists;
  final CreateMovieList _createList;
  late final StreamSubscription<AuthState> _accountSubscription;
  StreamSubscription<List<MovieList>>? _listsSubscription;

  /// O `uid` do stream aberto; nulo sem ninguém logado.
  String? _uid;

  /// As listas do último evento, sem as mudanças otimistas.
  List<MovieList>? _confirmed;

  /// Criadas aqui e ainda não vistas no stream, por id.
  final Map<String, MovieList> _created = {};

  /// Nome pedido e ainda não visto no stream, por id.
  final Map<String, ListName> _renamed = {};

  final Set<String> _deleting = {};
  bool _disposed = false;

  MovieListsState _state = const MovieListsLoading();
  MovieListsState get state => _state;

  /// Assina de novo depois de um erro de leitura.
  void retry() {
    if (_uid != null) _subscribe();
  }

  /// Cria a lista e a mostra na hora. Falha com `ListLimitFailure` no teto,
  /// sem mostrar nada, ou com a recusa do servidor, que a tira da tela.
  Future<void> create(ListName name) async {
    final list = _lists.newList(name);
    final created = await _createList(list);
    _created[list.id] = list;
    _emitLists();
    try {
      await created.saved;
    } on Exception {
      _created.remove(list.id);
      _emitLists();
      rethrow;
    }
  }

  /// Mostra o nome novo na hora; a recusa do servidor volta o antigo.
  Future<void> rename(MovieList list, ListName name) async {
    _renamed[list.id] = name;
    _emitLists();
    try {
      await _lists.renameList(list, name);
    } on Exception {
      _renamed.remove(list.id);
      _emitLists();
      rethrow;
    }
  }

  /// A linha fica desabilitada até o servidor responder; a lista sai da tela
  /// pelo stream.
  Future<void> delete(MovieList list) async {
    _deleting.add(list.id);
    _emitLists();
    try {
      await _lists.deleteList(list);
    } finally {
      _deleting.remove(list.id);
      _emitLists();
    }
  }

  void _onAccount(AuthState account) {
    switch (account) {
      case SignedIn(:final user) when user.uid == _uid:
        return;
      case SignedIn(:final user):
        _reset();
        _uid = user.uid;
        _subscribe();
      case SignedOut():
        _reset();
        _emit(const MovieListsSignedOut());
    }
  }

  void _reset() {
    unawaited(_listsSubscription?.cancel());
    _listsSubscription = null;
    _uid = null;
    _confirmed = null;
    _created.clear();
    _renamed.clear();
    _deleting.clear();
  }

  void _subscribe() {
    unawaited(_listsSubscription?.cancel());
    if (_confirmed == null) _emit(const MovieListsLoading());
    _listsSubscription = _lists.watchLists().listen(
      _onLists,
      onError: _onError,
      onDone: _onDone,
    );
  }

  void _onLists(List<MovieList> lists) {
    _confirmed = lists;
    final confirmedIds = {for (final list in lists) list.id};
    _created.removeWhere((id, _) => confirmedIds.contains(id));
    _renamed.removeWhere(
      (id, name) => lists.any((list) => list.id == id && list.name == name),
    );
    _emitLists();
  }

  void _onError(Object error) {
    _emit(
      MovieListsError(
        error is Failure
            ? error
            : const UnexpectedFailure('erro fora das falhas nas listas'),
      ),
    );
  }

  // O stream só acaba no logout, que fecha as listas antes de a conta sair
  // (decisão 010).
  void _onDone() {
    _listsSubscription = null;
    _confirmed = null;
    _created.clear();
    _renamed.clear();
    _emit(const MovieListsLoading());
  }

  void _emitLists() {
    final confirmed = _confirmed;
    if (confirmed == null) return;
    final shown = MovieList.sortedByName([
      for (final list in [...confirmed, ..._created.values])
        switch (_renamed[list.id]) {
          final ListName name => list.rename(name),
          null => list,
        },
    ]);
    _emit(
      shown.isEmpty
          ? const MovieListsEmpty()
          : MovieListsReady([
              for (final list in shown)
                MovieListItem(list, deleting: _deleting.contains(list.id)),
            ]),
    );
  }

  void _emit(MovieListsState state) {
    if (_disposed) return;
    _state = state;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_accountSubscription.cancel());
    _reset();
    super.dispose();
  }
}

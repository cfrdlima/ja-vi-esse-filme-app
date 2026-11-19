import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/list_name.dart';
import '../../domain/entities/movie_copy.dart';
import '../../domain/entities/movie_list.dart';
import '../../domain/entities/shelf_entry.dart';
import '../../domain/repositories/movie_lists_repository.dart';
import '../../domain/usecases/add_movie_to_list.dart';
import '../../domain/usecases/create_movie_list.dart';
import 'add_to_list_state.dart';

/// A folha Adicionar à lista (decisão 019): as listas da conta, com o filme
/// dentro ou não. Vive enquanto a folha está aberta, que só abre com a
/// conta logada.
///
/// As caixas são otimistas, como as marcas: mudam na hora, e só a recusa
/// volta a caixa. O [entry] é o que a Estante confirmou do filme, e diz em
/// que listas ele está.
class AddToListNotifier extends ChangeNotifier {
  AddToListNotifier({
    required this._lists,
    required this._createList,
    required this._addMovie,
    required this._copy,
    required this._entry,
  }) {
    _entry.addListener(_onEntry);
    _subscribe();
  }

  final MovieListsRepository _lists;
  final CreateMovieList _createList;
  final AddMovieToList _addMovie;
  final MovieCopy _copy;
  final ValueListenable<ShelfEntry?> _entry;
  StreamSubscription<List<MovieList>>? _listsSubscription;

  List<MovieList>? _confirmed;
  Failure? _readFailure;

  /// Criadas aqui e ainda não vistas no stream, por id.
  final Map<String, MovieList> _created = {};

  /// O que a pessoa pediu e a Estante ainda não confirmou, por id da lista.
  final Map<String, bool> _optimistic = {};

  /// A última escrita pedida em cada lista: a recusa de uma antiga não mexe
  /// na caixa.
  final Map<String, int> _latestWrite = {};
  int _writeCount = 0;

  Failure? _failure;
  ({MovieList list, bool wanted})? _failedToggle;
  bool _disposed = false;

  AddToListState _state = const AddToListLoading();
  AddToListState get state => _state;

  void retry() => _subscribe();

  /// Põe o filme na [list] ou o tira dela.
  void toggle(MovieList list) =>
      unawaited(_write(list, wanted: !_isChecked(list)));

  /// Repete a última caixa recusada.
  void retryToggle() {
    if (_failedToggle case (:final list, :final wanted)) {
      unawaited(_write(list, wanted: wanted));
    }
  }

  /// Cria a lista e põe o filme nela, sem esperar o servidor confirmar a
  /// lista. No teto, só mostra a falha.
  Future<void> createAndAdd(ListName name) async {
    final list = _lists.newList(name);
    final ({Future<void> saved}) created;
    try {
      created = await _createList(list);
    } on Failure catch (failure) {
      _failure = failure;
      _emit();
      return;
    }
    if (_disposed) return;
    _created[list.id] = list;
    unawaited(_write(list, wanted: true));
    unawaited(
      created.saved.then<void>(
        (_) {},
        onError: (Object error) {
          _created.remove(list.id);
          _optimistic.remove(list.id);
          _failure = _asFailure(error);
          _emit();
        },
      ),
    );
  }

  void _subscribe() {
    unawaited(_listsSubscription?.cancel());
    _readFailure = null;
    _listsSubscription = _lists.watchLists().listen(
      (lists) {
        _confirmed = lists;
        _readFailure = null;
        final ids = {for (final list in lists) list.id};
        _created.removeWhere((id, _) => ids.contains(id));
        _emit();
      },
      onError: (Object error) {
        _readFailure = _asFailure(error);
        _emit();
      },
    );
    _emit();
  }

  void _onEntry() {
    // A Estante já tem o que foi pedido: o otimista não é mais preciso.
    _optimistic.removeWhere((id, wanted) => _isConfirmedIn(id) == wanted);
    _emit();
  }

  Future<void> _write(MovieList list, {required bool wanted}) async {
    final entry = _entry.value;
    if (_disposed || entry == null) return;
    final Future<void> write;
    if (wanted) {
      write = _addMovie(_copy, list, current: entry);
    } else if (entry case OnShelf(:final movie) when movie.isInList(list.id)) {
      write = _lists.removeFromList(movie, list);
    } else {
      // Tirar o que a Estante ainda não confirmou deixaria o pedido de pôr
      // a caminho; espera a Estante alcançar, como nas marcas.
      return;
    }
    final id = ++_writeCount;
    _latestWrite[list.id] = id;
    _optimistic[list.id] = wanted;
    _failure = null;
    _failedToggle = null;
    _emit();
    try {
      await write;
    } on Exception catch (error) {
      if (_disposed || _latestWrite[list.id] != id) return;
      _optimistic.remove(list.id);
      _failure = _asFailure(error);
      _failedToggle = (list: list, wanted: wanted);
      _emit();
    }
  }

  bool _isConfirmedIn(String listId) => switch (_entry.value) {
    OnShelf(:final movie) => movie.isInList(listId),
    _ => false,
  };

  bool _isChecked(MovieList list) =>
      _optimistic[list.id] ?? _isConfirmedIn(list.id);

  static Failure _asFailure(Object error) => error is Failure
      ? error
      : const UnexpectedFailure('erro fora das falhas na folha das listas');

  void _emit() {
    if (_disposed) return;
    final confirmed = _confirmed;
    if (_readFailure case final failure?) {
      _state = AddToListError(failure);
    } else if (confirmed == null || _entry.value == null) {
      _state = const AddToListLoading();
    } else {
      _state = AddToListReady([
        for (final list in MovieList.sortedByName([
          ...confirmed,
          ..._created.values,
        ]))
          AddToListItem(list, checked: _isChecked(list)),
      ], failure: _failure);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _entry.removeListener(_onEntry);
    unawaited(_listsSubscription?.cancel());
    super.dispose();
  }
}

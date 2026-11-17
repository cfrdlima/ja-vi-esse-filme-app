import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/error/failures.dart';
import '../../../auth/domain/entities/auth_state.dart';
import '../../domain/entities/shelf_mark.dart';
import '../../domain/entities/shelf_movie.dart';
import '../../domain/entities/shelf_page.dart';
import '../../domain/repositories/shelf_repository.dart';
import '../../domain/usecases/expired_copy_renewer.dart';
import 'shelf_tab_state.dart';

/// Uma aba da Estante: os filmes com a [ShelfMark] da aba, a marca mais
/// recente primeiro. Segue o `watchShelf` da conta logada e assina de novo
/// quando a conta muda, como o `ShelfMarksNotifier`.
///
/// Para mostrar mais filmes, assina de novo com o limite maior
/// (`pageSize` a mais por vez): a lista inteira continua ao vivo.
class ShelfTabNotifier extends ChangeNotifier {
  ShelfTabNotifier({
    required this._mark,
    required this._shelf,
    required Stream<AuthState> account,
    required this._newRenewer,
  }) {
    // O erro da conta aparece no login; sem conta lida, a aba convida a
    // entrar.
    _accountSubscription = account.listen(
      _onAccount,
      onError: (Object _) => _onAccount(const SignedOut()),
    );
  }

  /// Quantos filmes cada passo da paginação acrescenta.
  static const pageSize = 20;

  final ShelfMark _mark;
  final ShelfRepository _shelf;

  /// Uma renovação por conta: o que uma conta já pediu não vale para outra.
  final ExpiredCopyRenewer Function() _newRenewer;
  ExpiredCopyRenewer? _renewer;

  late final StreamSubscription<AuthState> _accountSubscription;
  StreamSubscription<ShelfPage>? _shelfSubscription;

  /// O `uid` do stream aberto; nulo sem ninguém logado.
  String? _uid;
  int _limit = pageSize;

  /// Os últimos filmes mostrados, para manter a tela enquanto o limite
  /// maior não chega e quando um erro chega depois deles.
  List<ShelfMovie>? _movies;
  bool _hasMore = false;
  bool _disposed = false;

  ShelfTabState _state = const ShelfTabLoading();
  ShelfTabState get state => _state;

  /// Pede mais filmes quando há mais e o pedido anterior já chegou.
  void loadMore() {
    if (_state case ShelfTabReady(hasMore: true, loadingMore: false)) {
      _limit += pageSize;
      _subscribe();
    }
  }

  /// Assina de novo com o mesmo limite, depois de um erro.
  void retry() {
    if (_uid != null) _subscribe();
  }

  void _onAccount(AuthState account) {
    switch (account) {
      case SignedIn(:final user) when user.uid == _uid:
        return;
      case SignedIn(:final user):
        _reset();
        _uid = user.uid;
        _renewer = _newRenewer();
        _subscribe();
      case SignedOut():
        _reset();
        _emit(const ShelfTabSignedOut());
    }
  }

  void _reset() {
    unawaited(_shelfSubscription?.cancel());
    _shelfSubscription = null;
    _renewer?.dispose();
    _renewer = null;
    _uid = null;
    _limit = pageSize;
    _movies = null;
    _hasMore = false;
  }

  void _subscribe() {
    unawaited(_shelfSubscription?.cancel());
    _emit(switch (_movies) {
      final List<ShelfMovie> movies => ShelfTabReady(
        movies: movies,
        hasMore: _hasMore,
        loadingMore: true,
      ),
      null => const ShelfTabLoading(),
    });
    _shelfSubscription = _shelf
        .watchShelf(_mark, limit: _limit)
        .listen(_onPage, onError: _onError, onDone: _onDone);
  }

  void _onPage(ShelfPage page) {
    _movies = page.movies;
    _hasMore = page.hasMore;
    _renewer?.renew(page.movies);
    _emit(
      page.movies.isEmpty && !page.hasMore
          ? const ShelfTabEmpty()
          : ShelfTabReady(movies: page.movies, hasMore: page.hasMore),
    );
  }

  void _onError(Object error) {
    final failure = error is Failure
        ? error
        : const UnexpectedFailure('erro fora da Estante na aba');
    _emit(switch (_movies) {
      final List<ShelfMovie> movies => ShelfTabReady(
        movies: movies,
        hasMore: _hasMore,
        failure: failure,
      ),
      null => ShelfTabError(failure),
    });
  }

  // O stream só acaba no logout, que fecha a Estante antes de a conta sair
  // (decisão 010). A aba não mostra a conta que está saindo.
  void _onDone() {
    _shelfSubscription = null;
    _movies = null;
    _hasMore = false;
    _emit(const ShelfTabLoading());
  }

  void _emit(ShelfTabState state) {
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

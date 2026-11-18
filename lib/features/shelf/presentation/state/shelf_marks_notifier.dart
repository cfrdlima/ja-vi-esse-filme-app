import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/error/failures.dart';
import '../../../auth/domain/entities/auth_state.dart';
import '../../domain/entities/movie_copy.dart';
import '../../domain/entities/shelf_entry.dart';
import '../../domain/entities/shelf_mark.dart';
import '../../domain/entities/shelf_movie.dart';
import '../../domain/repositories/shelf_repository.dart';
import 'shelf_marks_state.dart';

/// As marcas de um filme nos Detalhes. Segue o `watchMovie` da conta logada
/// e assina de novo quando a conta muda, porque o stream fica preso ao `uid`
/// de quando foi aberto (sessão 021).
///
/// As escritas são otimistas: a marca aparece na hora, e o future da Estante
/// não é esperado para isso, porque offline ele só completa quando o servidor
/// confirma (contrato do [ShelfRepository]). Só a recusa dele volta a marca.
class ShelfMarksNotifier extends ChangeNotifier {
  ShelfMarksNotifier({
    required this._shelf,
    required Stream<AuthState> account,
    required this._copy,
  }) {
    // O erro da conta aparece no login; sem conta lida, as marcas ficam
    // como deslogadas, e tocar numa leva ao login.
    _accountSubscription = account.listen(
      _onAccount,
      onError: (Object _) => _onAccount(const SignedOut()),
    );
  }

  final ShelfRepository _shelf;
  final MovieCopy _copy;
  late final StreamSubscription<AuthState> _accountSubscription;
  StreamSubscription<ShelfEntry>? _watchSubscription;

  /// O `uid` do stream aberto; nulo sem ninguém logado.
  String? _uid;

  /// O último evento da Estante, sem as escritas otimistas.
  ShelfEntry? _confirmed;

  /// O que a pessoa pediu e a Estante ainda não confirmou: marca ligada
  /// (verdadeiro) ou desligada.
  final Map<ShelfMark, bool> _optimistic = {};

  /// Marca pedida no login, posta quando a Estante da conta chega.
  ShelfMark? _queued;

  /// A última escrita pedida em cada marca: a falha de uma escrita antiga
  /// não mexe na tela. Não dá para usar o [_optimistic], porque ele some
  /// quando o Firestore confirma no aparelho, antes de o servidor responder.
  final Map<ShelfMark, int> _latestWrite = {};
  int _writeCount = 0;

  /// Muda a cada assinatura: a falha de uma escrita da conta anterior não
  /// cai na conta nova.
  int _generation = 0;

  ShelfFailedWrite? _failedWrite;
  bool _disposed = false;

  ShelfMarksState _state = const ShelfMarksLoading();
  ShelfMarksState get state => _state;

  final _watchedMovie = ValueNotifier<ShelfMovie?>(null);

  /// O filme que a nota e o dia usam (decisão 018): o último confirmado pela
  /// Estante, só enquanto a tela mostra o Assistido ligado e a Estante já o
  /// confirmou. Nulo nos outros casos, inclusive deslogado.
  ValueListenable<ShelfMovie?> get watchedMovie => _watchedMovie;

  /// Liga ou desliga a [mark]. Sem as marcas lidas (deslogado, carregando ou
  /// com erro), não faz nada: quem está deslogado passa pelo login antes.
  void toggle(ShelfMark mark) {
    if (_state case ShelfMarksReady(:final marks)) {
      _write(mark, marked: !marks.contains(mark));
    }
  }

  /// Põe a [mark] assim que a Estante da conta chegar; com ela já lida, põe
  /// na hora. Serve para o login opcional: a pessoa tocou na marca
  /// deslogada, entrou, e a marca entra sem outro toque. Uma marca que a
  /// conta já tinha fica como está.
  void queueMark(ShelfMark mark) {
    if (_disposed) return;
    _queued = mark;
    _applyQueued();
  }

  /// Assina a Estante de novo depois de um erro de leitura.
  void retry() {
    if (_uid case final uid?) _watch(uid);
  }

  /// Repete a última escrita recusada.
  void retryWrite() {
    if (_failedWrite case final failed?) {
      _write(failed.mark, marked: failed.marked);
    }
  }

  void _onAccount(AuthState account) {
    switch (account) {
      case SignedIn(:final user) when user.uid == _uid:
        return;
      case SignedIn(:final user):
        _watch(user.uid);
      case SignedOut():
        _stopWatching();
        _uid = null;
        _queued = null;
        _emit(const ShelfMarksSignedOut());
    }
  }

  void _watch(String uid) {
    _stopWatching();
    _uid = uid;
    _emit(const ShelfMarksLoading());
    _watchSubscription = _shelf
        .watchMovie(_copy.movieId)
        .listen(_onEntry, onError: _onWatchError, onDone: _onWatchDone);
  }

  // O stream só acaba no logout, que fecha a Estante antes de a conta sair
  // (decisão 010). Sem as marcas lidas, um toque nessa janela não escreve,
  // e o Firestore não reabre com o cache da conta.
  void _onWatchDone() {
    _watchSubscription = null;
    _confirmed = null;
    _optimistic.clear();
    _failedWrite = null;
    _emit(const ShelfMarksLoading());
  }

  void _stopWatching() {
    _generation++;
    _latestWrite.clear();
    unawaited(_watchSubscription?.cancel());
    _watchSubscription = null;
    _confirmed = null;
    _optimistic.clear();
    _failedWrite = null;
  }

  void _onEntry(ShelfEntry entry) {
    _confirmed = entry;
    // A Estante já tem o que foi pedido: o otimista não é mais preciso.
    _optimistic.removeWhere((mark, marked) => _isConfirmed(mark) == marked);
    _emitReady();
    _applyQueued();
  }

  void _onWatchError(Object error) {
    _emit(
      ShelfMarksError(
        error is Failure
            ? error
            : const UnexpectedFailure('erro fora das falhas na Estante'),
      ),
    );
  }

  void _applyQueued() {
    final mark = _queued;
    if (mark == null || _confirmed == null) return;
    _queued = null;
    if (!_currentMarks().contains(mark)) _write(mark, marked: true);
  }

  void _write(ShelfMark mark, {required bool marked}) {
    final entry = _confirmed;
    if (_disposed || entry == null) return;
    final Future<void> write;
    if (marked) {
      write = _shelf.addMark(_copy, mark);
    } else if (entry case OnShelf(:final movie) when movie.isMarked(mark)) {
      write = _shelf.removeMark(movie, mark);
    } else {
      // Tirar o que a Estante ainda não confirmou deixaria o pedido de pôr
      // a marca a caminho; espera a Estante alcançar.
      return;
    }
    final id = ++_writeCount;
    _latestWrite[mark] = id;
    _optimistic[mark] = marked;
    _failedWrite = null;
    _emitReady();
    unawaited(
      _watchWrite(write, (
        mark: mark,
        id: id,
        generation: _generation,
      ), marked: marked),
    );
  }

  Future<void> _watchWrite(
    Future<void> write,
    ({ShelfMark mark, int id, int generation}) request, {
    required bool marked,
  }) async {
    final mark = request.mark;
    try {
      await write;
    } on Exception catch (error) {
      // Outra conta, ou uma escrita nova na mesma marca, já substituiu esta.
      if (request.generation != _generation ||
          _latestWrite[mark] != request.id) {
        return;
      }
      _optimistic.remove(mark);
      _failedWrite = ShelfFailedWrite(
        mark: mark,
        marked: marked,
        failure: error is Failure
            ? error
            : const UnexpectedFailure('exceção fora das falhas na Estante'),
      );
      // Com a leitura em erro, o erro dela continua na tela.
      if (_state is ShelfMarksReady) _emitReady();
    }
  }

  bool _isConfirmed(ShelfMark mark) => switch (_confirmed) {
    OnShelf(:final movie) => movie.isMarked(mark),
    _ => false,
  };

  Set<ShelfMark> _currentMarks() => {
    for (final mark in ShelfMark.values)
      if (_optimistic[mark] ?? _isConfirmed(mark)) mark,
  };

  void _emitReady() =>
      _emit(ShelfMarksReady(_currentMarks(), failedWrite: _failedWrite));

  void _emit(ShelfMarksState state) {
    if (_disposed) return;
    _state = state;
    notifyListeners();
    _watchedMovie.value = switch ((state, _confirmed)) {
      (final ShelfMarksReady ready, OnShelf(:final movie))
          when ready.isMarked(ShelfMark.watched) &&
              movie.isMarked(ShelfMark.watched) =>
        movie,
      _ => null,
    };
  }

  @override
  void dispose() {
    _disposed = true;
    _watchedMovie.dispose();
    unawaited(_accountSubscription.cancel());
    unawaited(_watchSubscription?.cancel());
    super.dispose();
  }
}

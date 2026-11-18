import 'dart:async';
import 'dart:collection';

import '../../../../core/error/failures.dart';
import '../entities/shelf_movie.dart';
import '../repositories/movie_copy_source.dart';
import '../repositories/shelf_repository.dart';

/// Renova com o TMDB as cópias vencidas da Estante (decisão 013), uma de
/// cada vez para não esbarrar no limite de requisições, e cada filme uma
/// vez só enquanto a aba vive.
class ExpiredCopyRenewer {
  ExpiredCopyRenewer({
    required this._shelf,
    required this._source,
    required this._now,
  });

  final ShelfRepository _shelf;
  final MovieCopySource _source;
  final DateTime Function() _now;

  final Set<int> _requested = {};
  final Queue<int> _queue = Queue();
  bool _running = false;
  bool _disposed = false;

  /// Põe na fila os filmes de [movies] com a cópia vencida que ainda não
  /// foram pedidos.
  void renew(Iterable<ShelfMovie> movies) {
    final now = _now();
    for (final movie in movies) {
      final id = movie.copy.movieId;
      if (movie.isCopyExpired(now) && _requested.add(id)) _queue.add(id);
    }
    if (!_running) unawaited(_drain());
  }

  void dispose() {
    _disposed = true;
    _queue.clear();
  }

  Future<void> _drain() async {
    _running = true;
    // Um erro que não é `Failure` é bug e sobe para o relatório de erros,
    // mas não pode deixar a fila travada até a conta mudar.
    try {
      while (_queue.isNotEmpty && !_disposed) {
        final id = _queue.removeFirst();
        try {
          final copy = await _source.fetchCopy(id);
          if (_disposed) break;
          // Sem esperar: offline, o future só completa quando o servidor
          // confirma. Uma recusa deixa a cópia vencida, que é o que a aba já
          // mostra.
          unawaited(_shelf.renewCopy(copy).catchError((Object _) {}));
        } on Failure catch (failure) {
          // Sem rede ou no limite, os próximos falhariam igual. Outra falha
          // (o filme sumiu do TMDB) segue para o próximo, e o placeholder
          // fica.
          if (failure is RateLimitFailure || failure is NetworkFailure) {
            _stop(id);
          }
        }
      }
    } finally {
      _running = false;
    }
  }

  /// Os filmes que não foram buscados voltam a poder ser pedidos.
  void _stop(int failedId) {
    _requested
      ..remove(failedId)
      ..removeAll(_queue);
    _queue.clear();
  }
}

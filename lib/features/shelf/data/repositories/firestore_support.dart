import 'dart:async';

import 'package:firebase_core/firebase_core.dart';

import '../../../../core/error/failures.dart';

// Só o `code` vai para a falha: a `message` da `FirebaseException` pode
// trazer o caminho do documento, com o `uid`.
Failure firestoreFailure(Object error) => switch (error) {
  FirebaseException(code: 'unavailable' || 'deadline-exceeded') =>
    const NetworkFailure(),
  FirebaseException(code: 'resource-exhausted') => const RateLimitFailure(),
  FirebaseException(code: 'unauthenticated') => const SignInRequiredFailure(),
  FirebaseException(:final code) => UnexpectedFailure('cloud_firestore: $code'),
  _ => const UnexpectedFailure('erro fora do Firestore na Estante'),
};

/// Os streams abertos de um repositório, para o logout encerrá-los por fora
/// antes do `terminate()` (decisão 010).
final class OpenWatches {
  final Set<_OpenWatch<Object?>> _open = {};

  int get count => _open.length;

  /// Contado só com alguém ouvindo: antes disso, o Firestore nem foi
  /// assinado, e não há o que fechar.
  Stream<T> track<T>(Stream<T> source) {
    late final _OpenWatch<T> watch;
    watch = _OpenWatch(
      source,
      onStart: () => _open.add(watch),
      onEnd: () => _open.remove(watch),
    );
    return watch.stream;
  }

  Future<void> closeAll() async {
    final open = [..._open];
    _open.clear();
    for (final watch in open) {
      await watch.close();
    }
  }
}

/// Um stream que o [OpenWatches.closeAll] consegue encerrar por fora.
final class _OpenWatch<T> {
  _OpenWatch(
    Stream<T> source, {
    required void Function() onStart,
    required this._onEnd,
  }) {
    _controller = StreamController<T>(
      onListen: () {
        onStart();
        _subscription = source.listen(
          _controller.add,
          onError: _controller.addError,
          onDone: _end,
        );
      },
      onCancel: () {
        _onEnd();
        return _subscription?.cancel();
      },
    );
  }

  late final StreamController<T> _controller;
  StreamSubscription<T>? _subscription;
  final void Function() _onEnd;

  Stream<T> get stream => _controller.stream;

  void _end() {
    _onEnd();
    unawaited(_controller.close());
  }

  /// Para de ouvir o Firestore, que é o que o `terminate()` precisa. O fim
  /// do stream não é esperado: com quem ouve pausado, ele só chegaria na
  /// retomada, e o logout ficaria preso.
  Future<void> close() async {
    final subscription = _subscription;
    _subscription = null;
    await subscription?.cancel();
    unawaited(_controller.close());
  }
}

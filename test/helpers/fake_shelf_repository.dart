import 'dart:async';

import 'package:ja_vi_esse_filme/features/shelf/domain/entities/movie_copy.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/shelf_entry.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/shelf_mark.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/shelf_movie.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/repositories/shelf_repository.dart';

/// Uma escrita que o teste completa quando quiser, como o Firestore offline,
/// em que o future só completa quando o servidor confirma.
final class FakeShelfWrite {
  FakeShelfWrite._(this.mark, {required this.movie, required this.copy});

  final ShelfMark mark;

  /// O filme passado ao `removeMark`; nulo num `addMark`.
  final ShelfMovie? movie;

  /// A cópia passada ao `addMark`; nula num `removeMark`.
  final MovieCopy? copy;

  final _completer = Completer<void>();

  bool get isAdd => copy != null;

  void complete() => _completer.complete();

  void fail(Object error) => _completer.completeError(error);
}

/// Estante controlada pelo teste: cada `watchMovie` abre um stream que o
/// teste alimenta por [emit] e [emitError], e cada escrita fica pendente em
/// [writes] até o teste completá-la.
class FakeShelfRepository implements ShelfRepository {
  final List<StreamController<ShelfEntry>> _watches = [];
  final List<int> watchedMovieIds = [];
  final List<FakeShelfWrite> writes = [];

  int get watchCalls => _watches.length;

  /// Se o último `watchMovie` ainda tem alguém ouvindo.
  bool get isWatching => _watches.isNotEmpty && _watches.last.hasListener;

  /// Quantos dos streams abertos ainda têm alguém ouvindo.
  int get activeWatches => _watches.where((w) => w.hasListener).length;

  void emit(ShelfEntry entry) => _watches.last.add(entry);

  void emitError(Object error) => _watches.last.addError(error);

  /// Encerra o último stream, como o `closeStreams()` do logout.
  void endWatch() => unawaited(_watches.last.close());

  @override
  Stream<ShelfEntry> watchMovie(int movieId) {
    watchedMovieIds.add(movieId);
    final controller = StreamController<ShelfEntry>();
    _watches.add(controller);
    return controller.stream;
  }

  @override
  Future<void> addMark(MovieCopy copy, ShelfMark mark) {
    final write = FakeShelfWrite._(mark, movie: null, copy: copy);
    writes.add(write);
    return write._completer.future;
  }

  @override
  Future<void> removeMark(ShelfMovie movie, ShelfMark mark) {
    final write = FakeShelfWrite._(mark, movie: movie, copy: null);
    writes.add(write);
    return write._completer.future;
  }

  var closeStreamsCalls = 0;

  @override
  Future<void> closeStreams() async {
    closeStreamsCalls++;
    close();
  }

  // Sem `await`: o `close()` de um stream sem ouvinte nunca completa.
  void close() {
    for (final watch in _watches) {
      unawaited(watch.close());
    }
  }
}

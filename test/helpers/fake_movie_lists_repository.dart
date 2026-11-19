import 'dart:async';

import 'package:ja_vi_esse_filme/features/shelf/domain/entities/list_name.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/movie_copy.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/movie_list.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/shelf_movie.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/shelf_page.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/repositories/movie_lists_repository.dart';

/// Uma escrita pendente, como o Firestore offline: o teste completa quando
/// quiser.
final class FakeListWrite {
  FakeListWrite._(this.kind, {required this.list, this.copy, this.movie});

  final ListWriteKind kind;
  final MovieList list;

  /// A cópia do `addToList`.
  final MovieCopy? copy;

  /// O filme do `removeFromList`.
  final ShelfMovie? movie;

  final _completer = Completer<void>();

  void complete() => _completer.complete();

  void fail(Object error) => _completer.completeError(error);
}

enum ListWriteKind { create, rename, delete, add, remove }

/// Listas controladas pelo teste: as contagens vêm de [listsCount] e
/// [moviesCount], e cada escrita fica pendente em [writes].
class FakeMovieListsRepository implements MovieListsRepository {
  final List<FakeListWrite> writes = [];

  int listsCount = 0;

  /// Por id da lista; sem entrada, zero.
  final Map<String, int> moviesCount = {};

  /// Lançado pelas contagens no lugar do número, quando não for nulo.
  Object? countError;

  int _nextId = 0;

  Future<void> _write(
    ListWriteKind kind,
    MovieList list, {
    MovieCopy? copy,
    ShelfMovie? movie,
  }) {
    final write = FakeListWrite._(kind, list: list, copy: copy, movie: movie);
    writes.add(write);
    return write._completer.future;
  }

  @override
  MovieList newList(ListName name) => MovieList(
    id: 'Fake${(_nextId++).toString().padLeft(16, '0')}',
    name: name,
  );

  @override
  Future<int> countLists() async {
    if (countError case final error?) throw error;
    return listsCount;
  }

  @override
  Future<int> countMovies(MovieList list) async {
    if (countError case final error?) throw error;
    return moviesCount[list.id] ?? 0;
  }

  @override
  Future<void> createList(MovieList list) => _write(ListWriteKind.create, list);

  @override
  Future<void> renameList(MovieList list, ListName name) =>
      _write(ListWriteKind.rename, list.rename(name));

  @override
  Future<void> deleteList(MovieList list) => _write(ListWriteKind.delete, list);

  @override
  Future<void> addToList(MovieCopy copy, MovieList list) =>
      _write(ListWriteKind.add, list, copy: copy);

  @override
  Future<void> removeFromList(ShelfMovie movie, MovieList list) =>
      _write(ListWriteKind.remove, list, movie: movie);

  @override
  Stream<List<MovieList>> watchLists() => const Stream.empty();

  @override
  Stream<ShelfPage> watchList(MovieList list, {required int limit}) =>
      const Stream.empty();

  @override
  Future<void> closeStreams() async {}
}

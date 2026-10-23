import 'dart:async';

import 'package:ja_vi_esse_filme/features/movies/domain/entities/movie.dart';
import 'package:ja_vi_esse_filme/features/movies/domain/entities/movie_category.dart';
import 'package:ja_vi_esse_filme/features/movies/domain/entities/movie_page.dart';
import 'package:ja_vi_esse_filme/features/movies/domain/repositories/movie_repository.dart';

/// Repositório controlado pelo teste: cada pedido fica pendente até o teste
/// responder com [complete] ou [fail].
class FakeMovieRepository implements MovieRepository {
  final List<int> requestedPages = [];
  final List<Completer<MoviePage>> _pending = [];

  @override
  Future<MoviePage> byCategory(MovieCategory category, {required int page}) {
    requestedPages.add(page);
    final completer = Completer<MoviePage>();
    _pending.add(completer);
    return completer.future;
  }

  void complete(MoviePage page) => _pending.removeAt(0).complete(page);

  void fail(Object error) => _pending.removeAt(0).completeError(error);
}

MoviePage moviePage({required int page, int totalPages = 3, int count = 2}) =>
    MoviePage(
      movies: [
        for (var i = 0; i < count; i++)
          Movie(id: page * 100 + i, title: 'Filme ${page * 100 + i}'),
      ],
      page: page,
      totalPages: totalPages,
    );

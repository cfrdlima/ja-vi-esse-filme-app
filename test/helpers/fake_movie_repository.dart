import 'dart:async';

import 'package:ja_vi_esse_filme/features/movies/domain/entities/movie.dart';
import 'package:ja_vi_esse_filme/features/movies/domain/entities/movie_category.dart';
import 'package:ja_vi_esse_filme/features/movies/domain/entities/movie_details.dart';
import 'package:ja_vi_esse_filme/features/movies/domain/entities/movie_page.dart';
import 'package:ja_vi_esse_filme/features/movies/domain/entities/search_query.dart';
import 'package:ja_vi_esse_filme/features/movies/domain/repositories/movie_repository.dart';

/// Repositório controlado pelo teste: cada pedido fica pendente até o teste
/// responder com [complete] ou [fail] (listas) e [completeDetails] ou
/// [failDetails] (detalhes).
class FakeMovieRepository implements MovieRepository {
  final List<int> requestedPages = [];
  final List<MovieCategory> requestedCategories = [];
  final List<SearchQuery> requestedQueries = [];
  final List<int> requestedDetails = [];
  final List<Completer<MoviePage>> _pending = [];
  final List<Completer<MovieDetails>> _pendingDetails = [];

  @override
  Future<MoviePage> byCategory(MovieCategory category, {required int page}) {
    requestedPages.add(page);
    requestedCategories.add(category);
    return _enqueue();
  }

  @override
  Future<MoviePage> search(SearchQuery query, {required int page}) {
    requestedPages.add(page);
    requestedQueries.add(query);
    return _enqueue();
  }

  @override
  Future<MovieDetails> details(int id) {
    requestedDetails.add(id);
    final completer = Completer<MovieDetails>();
    _pendingDetails.add(completer);
    return completer.future;
  }

  Future<MoviePage> _enqueue() {
    final completer = Completer<MoviePage>();
    _pending.add(completer);
    return completer.future;
  }

  void complete(MoviePage page) => _pending.removeAt(0).complete(page);

  void fail(Object error) => _pending.removeAt(0).completeError(error);

  void completeDetails(MovieDetails details) =>
      _pendingDetails.removeAt(0).complete(details);

  void failDetails(Object error) =>
      _pendingDetails.removeAt(0).completeError(error);
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

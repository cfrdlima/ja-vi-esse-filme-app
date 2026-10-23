import '../../domain/entities/movie_category.dart';
import '../../domain/entities/movie_page.dart';
import '../../domain/repositories/movie_repository.dart';
import 'paged_movies_notifier.dart';

/// A lista paginada de uma [MovieCategory] da Descobrir.
class CategoryMoviesNotifier extends PagedMoviesNotifier {
  CategoryMoviesNotifier({required this._repository, required this.category});

  final MovieRepository _repository;
  final MovieCategory category;

  @override
  Future<MoviePage> fetchPage(int page) =>
      _repository.byCategory(category, page: page);
}

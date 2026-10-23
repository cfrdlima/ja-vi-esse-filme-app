import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/features/movies/domain/entities/movie_category.dart';
import 'package:ja_vi_esse_filme/features/movies/presentation/state/category_movies_notifier.dart';

import '../../../../helpers/fake_movie_repository.dart';

void main() {
  late FakeMovieRepository repository;
  late CategoryMoviesNotifier notifier;

  setUp(() {
    repository = FakeMovieRepository();
    notifier = CategoryMoviesNotifier(
      repository: repository,
      category: MovieCategory.topRated,
    );
  });

  tearDown(() => notifier.dispose());

  test('deve expor a categoria da lista', () {
    expect(notifier.category, MovieCategory.topRated);
  });

  test('deve pedir a categoria recebida', () async {
    final future = notifier.load();
    repository.complete(moviePage(page: 1));
    await future;

    expect(repository.requestedCategories, [MovieCategory.topRated]);
  });
}

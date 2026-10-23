import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/features/movies/domain/entities/search_query.dart';
import 'package:ja_vi_esse_filme/features/movies/presentation/state/search_results_notifier.dart';

import '../../../../helpers/fake_movie_repository.dart';

void main() {
  late FakeMovieRepository repository;
  late SearchResultsNotifier notifier;

  setUp(() {
    repository = FakeMovieRepository();
    notifier = SearchResultsNotifier(
      repository: repository,
      query: SearchQuery('matrix'),
    );
  });

  tearDown(() => notifier.dispose());

  test('deve expor o termo da busca', () {
    expect(notifier.query, SearchQuery('matrix'));
  });

  test('deve pedir a busca do termo recebido', () async {
    final future = notifier.load();
    repository.complete(moviePage(page: 1));
    await future;

    expect(repository.requestedQueries, [SearchQuery('matrix')]);
  });
}

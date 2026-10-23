import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/features/movies/domain/entities/movie_category.dart';
import 'package:ja_vi_esse_filme/features/movies/presentation/state/discover_notifier.dart';

import '../../../../helpers/fake_movie_repository.dart';

void main() {
  late FakeMovieRepository repository;
  late DiscoverNotifier discover;

  setUp(() {
    repository = FakeMovieRepository();
    discover = DiscoverNotifier(repository: repository);
  });

  tearDown(() => discover.dispose());

  test('deve começar em populares', () {
    expect(discover.category, MovieCategory.popular);
  });

  test('deve carregar populares ao ser criado', () {
    expect(repository.requestedCategories, [MovieCategory.popular]);
  });

  test('deve carregar a categoria escolhida', () {
    discover.select(MovieCategory.nowPlaying);

    expect(repository.requestedCategories.last, MovieCategory.nowPlaying);
  });

  test('deve mostrar a lista da categoria escolhida', () {
    discover.select(MovieCategory.topRated);

    expect(discover.current.category, MovieCategory.topRated);
  });

  test('não deve recarregar uma categoria já aberta', () {
    discover
      ..select(MovieCategory.popular)
      ..select(MovieCategory.topRated)
      ..select(MovieCategory.popular);

    expect(repository.requestedCategories, [
      MovieCategory.popular,
      MovieCategory.topRated,
    ]);
  });

  test('deve manter a lista de cada categoria entre as trocas', () {
    discover.select(MovieCategory.popular);
    final popular = discover.current;

    discover
      ..select(MovieCategory.nowPlaying)
      ..select(MovieCategory.popular);

    expect(discover.current, same(popular));
  });

  test('deve notificar ao trocar de categoria', () {
    var notifications = 0;
    discover.addListener(() => notifications++);

    discover.select(MovieCategory.topRated);

    expect(notifications, 1);
  });

  test('não deve notificar ao escolher a categoria já mostrada', () {
    discover.select(MovieCategory.popular);
    var notifications = 0;
    discover.addListener(() => notifications++);

    discover.select(MovieCategory.popular);

    expect(notifications, 0);
  });

  test('deve descartar as listas ao ser descartado', () {
    final own = DiscoverNotifier(repository: repository);
    final list = own.current;

    own.dispose();

    expect(() => list.addListener(() {}), throwsFlutterError);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/core/error/failures.dart';
import 'package:ja_vi_esse_filme/features/shelf/data/repositories/unavailable_movie_lists_repository.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/list_name.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/movie_copy.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/movie_list.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/shelf_movie.dart';

void main() {
  const repository = UnavailableMovieListsRepository();
  final list = MovieList(id: 'Lst0aBcDeFgHiJkLmNoP', name: ListName('Terror'));
  final copy = MovieCopy(movieId: 550, title: 'Clube da Luta');
  final movie = ShelfMovie(
    copy: copy,
    cachedAt: DateTime.utc(2026, 11, 1),
    marks: const {},
    lists: {list.id: DateTime.utc(2026, 11, 2)},
  );
  final signInRequired = throwsA(isA<SignInRequiredFailure>());

  test('deve falhar as listas com SignInRequiredFailure', () async {
    await expectLater(
      repository.watchLists(),
      emitsError(isA<SignInRequiredFailure>()),
    );
  });

  test('deve falhar os filmes da lista com SignInRequiredFailure', () async {
    await expectLater(
      repository.watchList(list, limit: 20),
      emitsError(isA<SignInRequiredFailure>()),
    );
  });

  test('deve falhar a lista nova com SignInRequiredFailure', () {
    expect(() => repository.newList(ListName('Terror')), signInRequired);
  });

  test('deve falhar as contagens com SignInRequiredFailure', () async {
    await expectLater(repository.countLists(), signInRequired);
  });

  test('deve falhar a contagem dos filmes com SignInRequiredFailure', () async {
    await expectLater(repository.countMovies(list), signInRequired);
  });

  test('deve falhar criar com SignInRequiredFailure', () async {
    await expectLater(repository.createList(list), signInRequired);
  });

  test('deve falhar renomear com SignInRequiredFailure', () async {
    await expectLater(
      repository.renameList(list, ListName('Suspense')),
      signInRequired,
    );
  });

  test('deve falhar apagar com SignInRequiredFailure', () async {
    await expectLater(repository.deleteList(list), signInRequired);
  });

  test('deve falhar pôr na lista com SignInRequiredFailure', () async {
    await expectLater(repository.addToList(copy, list), signInRequired);
  });

  test('deve falhar tirar da lista com SignInRequiredFailure', () async {
    await expectLater(repository.removeFromList(movie, list), signInRequired);
  });

  test('deve fechar os streams sem erro', () async {
    await expectLater(repository.closeStreams(), completes);
  });
}

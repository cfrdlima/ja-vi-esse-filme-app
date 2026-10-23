import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/features/movies/domain/entities/search_query.dart';
import 'package:ja_vi_esse_filme/features/movies/presentation/state/paged_movies_state.dart';
import 'package:ja_vi_esse_filme/features/movies/presentation/state/search_notifier.dart';
import 'package:ja_vi_esse_filme/features/movies/presentation/state/search_results_notifier.dart';

import '../../../../helpers/fake_movie_repository.dart';

void main() {
  late FakeMovieRepository repository;

  setUp(() => repository = FakeMovieRepository());

  /// Roda [body] com o relógio falso e descarta o notifier no fim.
  void withNotifier(void Function(SearchNotifier, FakeAsync) body) {
    fakeAsync((async) {
      final notifier = SearchNotifier(repository: repository);
      body(notifier, async);
      notifier.dispose();
      async.flushMicrotasks();
    });
  }

  SearchResultsNotifier resultsOf(SearchNotifier notifier) =>
      (notifier.state as SearchActive).results;

  test('deve esperar 400 ms depois da última tecla', () {
    expect(SearchNotifier.debounce, const Duration(milliseconds: 400));
  });

  test('deve começar no estado inicial', () {
    withNotifier((notifier, _) {
      expect(notifier.state, isA<SearchIdle>());
    });
  });

  group('debounce', () {
    test('não deve pedir antes do fim da espera', () {
      withNotifier((notifier, async) {
        notifier.onQueryChanged('matrix');
        async.elapse(SearchNotifier.debounce - const Duration(milliseconds: 1));

        expect(repository.requestedQueries, isEmpty);
      });
    });

    test('deve pedir o termo no fim da espera', () {
      withNotifier((notifier, async) {
        notifier.onQueryChanged('matrix');
        async.elapse(SearchNotifier.debounce);

        expect(repository.requestedQueries, [SearchQuery('matrix')]);
      });
    });

    test('deve recomeçar a espera a cada tecla e pedir só o último termo', () {
      withNotifier((notifier, async) {
        notifier.onQueryChanged('ma');
        async.elapse(const Duration(milliseconds: 300));
        notifier.onQueryChanged('mat');
        async.elapse(const Duration(milliseconds: 300));
        notifier.onQueryChanged('matr');
        async.elapse(SearchNotifier.debounce);

        expect(repository.requestedQueries, [SearchQuery('matr')]);
      });
    });

    test('deve abrir a busca do termo no fim da espera', () {
      withNotifier((notifier, async) {
        notifier.onQueryChanged('matrix');
        async.elapse(SearchNotifier.debounce);

        expect(resultsOf(notifier).query, SearchQuery('matrix'));
      });
    });

    test('deve notificar quando abre a busca', () {
      withNotifier((notifier, async) {
        var notified = 0;
        notifier.addListener(() => notified++);

        notifier.onQueryChanged('matrix');
        async.elapse(SearchNotifier.debounce);

        expect(notified, 1);
      });
    });
  });

  group('termo inválido', () {
    test('não deve pedir um termo curto', () {
      withNotifier((notifier, async) {
        notifier.onQueryChanged(' a ');
        async.elapse(SearchNotifier.debounce);

        expect(repository.requestedQueries, isEmpty);
      });
    });

    test('deve voltar ao inicial na hora quando o termo fica curto', () {
      withNotifier((notifier, async) {
        notifier.onQueryChanged('matrix');
        async.elapse(SearchNotifier.debounce);

        notifier.onQueryChanged('m');

        expect(notifier.state, isA<SearchIdle>());
      });
    });

    test('deve cancelar a espera quando o termo fica curto', () {
      withNotifier((notifier, async) {
        notifier.onQueryChanged('matrix');
        notifier.onQueryChanged('m');
        async.elapse(SearchNotifier.debounce);

        expect(repository.requestedQueries, isEmpty);
      });
    });

    test('deve avisar na hora que o termo passou do máximo', () {
      withNotifier((notifier, _) {
        notifier.onQueryChanged('a' * (SearchQuery.maxLength + 1));

        expect(notifier.state, isA<SearchTooLong>());
      });
    });

    test('não deve pedir um termo longo demais', () {
      withNotifier((notifier, async) {
        notifier.onQueryChanged('a' * (SearchQuery.maxLength + 1));
        async.elapse(SearchNotifier.debounce);

        expect(repository.requestedQueries, isEmpty);
      });
    });
  });

  group('termo repetido', () {
    test('não deve pedir de novo o termo já mostrado', () {
      withNotifier((notifier, async) {
        notifier.onQueryChanged('matrix');
        async.elapse(SearchNotifier.debounce);
        notifier.onQueryChanged('matrix ');
        async.elapse(SearchNotifier.debounce);

        expect(repository.requestedQueries, [SearchQuery('matrix')]);
      });
    });

    test('deve cancelar a espera ao voltar para o termo já mostrado', () {
      withNotifier((notifier, async) {
        notifier.onQueryChanged('matrix');
        async.elapse(SearchNotifier.debounce);
        notifier.onQueryChanged('matrix reloaded');
        notifier.onQueryChanged('matrix');
        async.elapse(SearchNotifier.debounce);

        expect(repository.requestedQueries, [SearchQuery('matrix')]);
      });
    });
  });

  group('termo novo', () {
    test('deve descartar a resposta atrasada do termo anterior', () {
      withNotifier((notifier, async) {
        notifier.onQueryChanged('matrix');
        async.elapse(SearchNotifier.debounce);
        notifier.onQueryChanged('matriz');
        async.elapse(SearchNotifier.debounce);

        repository.complete(moviePage(page: 1)); // resposta de "matrix"
        async.flushMicrotasks();

        expect(resultsOf(notifier).state, isA<PagedMoviesLoading>());
      });
    });

    test('deve descartar a lista do termo anterior', () {
      withNotifier((notifier, async) {
        notifier.onQueryChanged('matrix');
        async.elapse(SearchNotifier.debounce);
        final previous = resultsOf(notifier);
        notifier.onQueryChanged('matriz');
        async.elapse(SearchNotifier.debounce);

        expect(() => previous.addListener(() {}), throwsFlutterError);
      });
    });
  });

  group('buscar pelo teclado', () {
    test('deve pedir na hora, sem esperar', () {
      withNotifier((notifier, _) {
        notifier.submit('matrix');

        expect(repository.requestedQueries, [SearchQuery('matrix')]);
      });
    });

    test('deve cancelar a espera do mesmo termo', () {
      withNotifier((notifier, async) {
        notifier.onQueryChanged('matrix');
        notifier.submit('matrix');
        async.elapse(SearchNotifier.debounce);

        expect(repository.requestedQueries, [SearchQuery('matrix')]);
      });
    });

    test('não deve pedir um termo curto', () {
      withNotifier((notifier, _) {
        notifier.submit('a');

        expect(repository.requestedQueries, isEmpty);
      });
    });
  });

  group('limpar', () {
    test('deve voltar ao estado inicial', () {
      withNotifier((notifier, async) {
        notifier.onQueryChanged('matrix');
        async.elapse(SearchNotifier.debounce);

        notifier.clear();

        expect(notifier.state, isA<SearchIdle>());
      });
    });

    test('deve cancelar a espera pendente', () {
      withNotifier((notifier, async) {
        notifier.onQueryChanged('matrix');
        notifier.clear();
        async.elapse(SearchNotifier.debounce);

        expect(repository.requestedQueries, isEmpty);
      });
    });

    test('deve descartar a lista da busca', () {
      withNotifier((notifier, async) {
        notifier.onQueryChanged('matrix');
        async.elapse(SearchNotifier.debounce);
        final results = resultsOf(notifier);

        notifier.clear();

        expect(() => results.addListener(() {}), throwsFlutterError);
      });
    });

    test('deve buscar de novo o mesmo termo depois de limpar', () {
      withNotifier((notifier, async) {
        notifier.onQueryChanged('matrix');
        async.elapse(SearchNotifier.debounce);
        notifier.clear();
        notifier.onQueryChanged('matrix');
        async.elapse(SearchNotifier.debounce);

        expect(repository.requestedQueries, [
          SearchQuery('matrix'),
          SearchQuery('matrix'),
        ]);
      });
    });

    test('não deve notificar quando já está no inicial', () {
      withNotifier((notifier, _) {
        var notified = 0;
        notifier.addListener(() => notified++);

        notifier.clear();

        expect(notified, 0);
      });
    });
  });

  group('dispose', () {
    test('deve cancelar a espera pendente', () {
      fakeAsync((async) {
        SearchNotifier(repository: repository)
          ..onQueryChanged('matrix')
          ..dispose();
        async.elapse(SearchNotifier.debounce);

        expect(repository.requestedQueries, isEmpty);
      });
    });

    test('deve descartar a lista da busca', () {
      fakeAsync((async) {
        final notifier = SearchNotifier(repository: repository)
          ..onQueryChanged('matrix');
        async.elapse(SearchNotifier.debounce);
        final results = resultsOf(notifier);

        notifier.dispose();

        expect(() => results.addListener(() {}), throwsFlutterError);
      });
    });
  });
}

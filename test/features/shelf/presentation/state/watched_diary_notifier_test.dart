import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/core/error/failures.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/movie_copy.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/rating.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/shelf_mark.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/shelf_movie.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/watched_on.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/usecases/choose_watched_on.dart';
import 'package:ja_vi_esse_filme/features/shelf/presentation/state/watched_diary_notifier.dart';
import 'package:ja_vi_esse_filme/features/shelf/presentation/state/watched_diary_state.dart';

import '../../../../helpers/fake_shelf_repository.dart';

/// Conta quem ouve, para o teste ver o dispose tirar o ouvinte.
class _CountingListenable implements ValueListenable<ShelfMovie?> {
  int listeners = 0;

  @override
  ShelfMovie? get value => null;

  @override
  void addListener(VoidCallback listener) => listeners++;

  @override
  void removeListener(VoidCallback listener) => listeners--;
}

void main() {
  // Meio-dia local: longe da virada do dia em qualquer fuso de teste.
  var now = DateTime(2026, 11, 18, 12);
  final watchedAt = DateTime(2026, 11, 10, 20);
  final markedOn = WatchedOn(year: 2026, month: 11, day: 10);
  final chosenDay = WatchedOn(year: 2026, month: 11, day: 1);

  ShelfMovie watched({Rating? rating, WatchedOn? watchedOn}) => ShelfMovie(
    copy: MovieCopy(movieId: 550, title: 'Clube da Luta'),
    cachedAt: watchedAt,
    marks: {ShelfMark.watched: watchedAt},
    rating: rating,
    watchedOn: watchedOn,
  );

  late FakeShelfRepository shelf;
  late ValueNotifier<ShelfMovie?> movie;
  late WatchedDiaryNotifier notifier;

  DiaryReady ready() => switch (notifier.state) {
    final DiaryReady ready => ready,
    DiaryHidden() => fail('esperava a nota e o dia na tela'),
  };

  setUp(() {
    now = DateTime(2026, 11, 18, 12);
    shelf = FakeShelfRepository();
    movie = ValueNotifier(null);
    notifier = WatchedDiaryNotifier(
      shelf: shelf,
      chooseWatchedOn: ChooseWatchedOn(shelf: shelf, now: () => now),
      watchedMovie: movie,
    );
  });

  tearDown(() {
    notifier.dispose();
    movie.dispose();
    shelf.close();
  });

  group('leitura', () {
    test('deve ficar escondido sem o filme assistido', () {
      expect(notifier.state, isA<DiaryHidden>());
    });

    test('deve mostrar a nota do filme', () {
      movie.value = watched(rating: Rating(7));

      expect(ready().rating, Rating(7));
    });

    test('deve mostrar o dia escolhido', () {
      movie.value = watched(watchedOn: chosenDay);

      expect(ready().watchedOn, chosenDay);
    });

    test('deve dar o dia local em que o Assistido entrou', () {
      movie.value = watched();

      expect(ready().markedOn, markedOn);
    });

    test('deve dar o dia de hoje para o seletor', () {
      movie.value = watched();

      expect(notifier.today(), WatchedOn(year: 2026, month: 11, day: 18));
    });

    // A tela pode ficar aberta de um dia para o outro.
    test('deve dar o hoje do relógio na hora em que é pedido', () {
      movie.value = watched();

      now = DateTime(2026, 11, 19, 0, 30);

      expect(notifier.today(), WatchedOn(year: 2026, month: 11, day: 19));
    });

    test('deve começar sem falha', () {
      movie.value = watched();

      expect(ready().failure, isNull);
    });

    test('deve esconder quando o filme deixa de ser assistido', () {
      movie.value = watched();

      movie.value = null;

      expect(notifier.state, isA<DiaryHidden>());
    });

    test('deve avisar quem ouve quando o filme chega', () {
      var notified = 0;
      notifier.addListener(() => notified++);

      movie.value = watched();

      expect(notified, 1);
    });

    test('deve ler o filme que já estava lá ao nascer', () {
      movie.value = watched(rating: Rating(3));
      final late = WatchedDiaryNotifier(
        shelf: shelf,
        chooseWatchedOn: ChooseWatchedOn(shelf: shelf, now: () => now),
        watchedMovie: movie,
      );
      addTearDown(late.dispose);

      expect((late.state as DiaryReady).rating, Rating(3));
    });
  });

  group('nota', () {
    for (final (current, star, expected) in [
      (null, 4, 8),
      (8, 4, 7),
      (7, 4, 8),
      (8, 2, 4),
      (1, 1, 2),
      (2, 1, 1),
    ]) {
      test('deve dar ${expected / 2} estrelas ao tocar na estrela $star com '
          '${current == null ? 'nenhuma' : current / 2}', () {
        movie.value = watched(rating: current == null ? null : Rating(current));

        notifier.tapStar(star);

        expect(shelf.personalWrites.single.value, Rating(expected));
      });
    }

    test('deve mostrar a nota tocada na hora', () {
      movie.value = watched();

      notifier.tapStar(4);

      expect(ready().rating, Rating(8));
    });

    test('deve subir meia estrela', () {
      movie.value = watched(rating: Rating(7));

      notifier.increase();

      expect(shelf.personalWrites.single.value, Rating(8));
    });

    test('deve dar meia estrela ao subir sem nota', () {
      movie.value = watched();

      notifier.increase();

      expect(shelf.personalWrites.single.value, Rating(1));
    });

    test('não deve passar de cinco estrelas', () {
      movie.value = watched(rating: Rating(10));

      notifier.increase();

      expect(shelf.personalWrites, isEmpty);
    });

    test('deve descer meia estrela', () {
      movie.value = watched(rating: Rating(7));

      notifier.decrease();

      expect(shelf.personalWrites.single.value, Rating(6));
    });

    test('deve tirar a nota ao descer de meia estrela', () {
      movie.value = watched(rating: Rating(1));

      notifier.decrease();

      expect(ready().rating, isNull);
    });

    test('não deve descer sem nota', () {
      movie.value = watched();

      notifier.decrease();

      expect(shelf.personalWrites, isEmpty);
    });

    test('deve tirar a nota', () {
      movie.value = watched(rating: Rating(7));

      notifier.clearRating();

      expect(
        (shelf.personalWrites.single.field, shelf.personalWrites.single.value),
        (PersonalField.rating, null),
      );
    });

    test('deve mostrar a nota tirada na hora', () {
      movie.value = watched(rating: Rating(7));

      notifier.clearRating();

      expect(ready().rating, isNull);
    });

    test('deve gravar no filme confirmado', () {
      final confirmed = watched();
      movie.value = confirmed;

      notifier.tapStar(3);

      expect(shelf.personalWrites.single.movie, confirmed);
    });

    test('não deve gravar com o bloco escondido', () {
      notifier.tapStar(3);

      expect(shelf.personalWrites, isEmpty);
    });
  });

  group('dia', () {
    test('deve gravar o dia escolhido', () {
      movie.value = watched();

      notifier.chooseWatchedOn(chosenDay);

      expect(shelf.personalWrites.single.value, chosenDay);
    });

    test('deve mostrar o dia escolhido na hora', () {
      movie.value = watched();

      notifier.chooseWatchedOn(chosenDay);

      expect(ready().watchedOn, chosenDay);
    });

    test('deve recusar o dia no futuro sem gravar', () {
      movie.value = watched();

      expect(
        () =>
            notifier.chooseWatchedOn(WatchedOn(year: 2026, month: 11, day: 19)),
        throwsArgumentError,
      );
      expect(shelf.personalWrites, isEmpty);
    });

    test('deve tirar o dia', () {
      movie.value = watched(watchedOn: chosenDay);

      notifier.clearWatchedOn();

      expect(
        (shelf.personalWrites.single.field, shelf.personalWrites.single.value),
        (PersonalField.watchedOn, null),
      );
    });

    test('deve mostrar o dia tirado na hora', () {
      movie.value = watched(watchedOn: chosenDay);

      notifier.clearWatchedOn();

      expect(ready().watchedOn, isNull);
    });
  });

  group('dados pessoais', () {
    test('deve dizer que há dados com a nota', () {
      movie.value = watched(rating: Rating(7));

      expect(ready().hasPersonalData, isTrue);
    });

    test('deve dizer que há dados com o dia', () {
      movie.value = watched(watchedOn: chosenDay);

      expect(ready().hasPersonalData, isTrue);
    });

    test('deve dizer que não há dados sem nota nem dia', () {
      movie.value = watched();

      expect(ready().hasPersonalData, isFalse);
    });

    test('deve contar a nota ainda não confirmada', () {
      movie.value = watched();

      notifier.tapStar(3);

      expect(ready().hasPersonalData, isTrue);
    });
  });

  group('confirmação e recusa', () {
    test('deve manter a nota pedida enquanto a Estante não a mostra', () {
      movie.value = watched();
      notifier.tapStar(4);

      movie.value = watched();

      expect(ready().rating, Rating(8));
    });

    test('deve seguir a Estante depois que o servidor confirma', () async {
      movie.value = watched();
      notifier.tapStar(4);
      movie.value = watched(rating: Rating(8));
      shelf.personalWrites.single.complete();
      await pumpEventQueue();

      movie.value = watched(rating: Rating(3));

      expect(ready().rating, Rating(3));
    });

    // O Firestore mostra a escrita no aparelho antes de o servidor
    // responder: a recusa chega depois de a Estante já ter o valor.
    test(
      'deve mostrar a recusa que chega depois de a Estante mostrar a nota',
      () async {
        movie.value = watched();
        notifier.tapStar(2);
        movie.value = watched(rating: Rating(4));

        shelf.personalWrites.single.fail(const NetworkFailure());
        await pumpEventQueue();

        expect(ready().failure, isA<NetworkFailure>());
      },
    );

    test(
      'deve mostrar a recusa do dia que chega depois de a Estante mostrá-lo',
      () async {
        movie.value = watched();
        notifier.chooseWatchedOn(chosenDay);
        movie.value = watched(watchedOn: chosenDay);

        shelf.personalWrites.single.fail(const NetworkFailure());
        await pumpEventQueue();

        expect(ready().failure, isA<NetworkFailure>());
      },
    );

    test(
      'deve manter a última nota pedida quando a Estante mostra a anterior',
      () {
        movie.value = watched(rating: Rating(6));
        notifier.tapStar(4);
        notifier.tapStar(3);

        movie.value = watched(rating: Rating(8));

        expect(ready().rating, Rating(6));
      },
    );

    test('deve voltar a nota quando o servidor recusa', () async {
      movie.value = watched(rating: Rating(7));
      notifier.tapStar(1);

      shelf.personalWrites.single.fail(const NetworkFailure());
      await pumpEventQueue();

      expect(ready().rating, Rating(7));
    });

    test('deve mostrar a falha da recusa', () async {
      movie.value = watched();
      notifier.chooseWatchedOn(chosenDay);

      shelf.personalWrites.single.fail(const RateLimitFailure());
      await pumpEventQueue();

      expect(ready().failure, isA<RateLimitFailure>());
    });

    test('deve repetir a escrita recusada', () async {
      movie.value = watched();
      notifier.chooseWatchedOn(chosenDay);
      shelf.personalWrites.single.fail(const NetworkFailure());
      await pumpEventQueue();

      notifier.retryWrite();

      expect(shelf.personalWrites.last.value, chosenDay);
    });

    test('deve tirar a falha ao repetir', () async {
      movie.value = watched();
      notifier.tapStar(2);
      shelf.personalWrites.single.fail(const NetworkFailure());
      await pumpEventQueue();

      notifier.retryWrite();

      expect(ready().failure, isNull);
    });

    test('deve ignorar a recusa de uma nota já trocada por outra', () async {
      movie.value = watched();
      notifier.tapStar(2);
      notifier.tapStar(5);

      shelf.personalWrites.first.fail(const NetworkFailure());
      await pumpEventQueue();

      expect((ready().rating, ready().failure), (Rating(10), null));
    });

    test('deve ignorar a recusa que chega depois de o filme sair', () async {
      movie.value = watched();
      notifier.tapStar(2);
      movie.value = null;
      movie.value = watched();

      shelf.personalWrites.single.fail(const NetworkFailure());
      await pumpEventQueue();

      expect(ready().failure, isNull);
    });

    test('deve esquecer a nota pedida quando o filme sai', () {
      movie.value = watched();
      notifier.tapStar(2);
      movie.value = null;

      movie.value = watched();

      expect(ready().rating, isNull);
    });
  });

  group('depois do dispose', () {
    for (final (name, write) in <(String, void Function(WatchedDiaryNotifier))>[
      ('a estrela', (n) => n.tapStar(2)),
      ('a nota a mais', (n) => n.increase()),
      ('tirar a nota', (n) => n.clearRating()),
      ('o dia', (n) => n.chooseWatchedOn(chosenDay)),
      ('tirar o dia', (n) => n.clearWatchedOn()),
    ]) {
      test('não deve gravar $name', () {
        final own = WatchedDiaryNotifier(
          shelf: shelf,
          chooseWatchedOn: ChooseWatchedOn(shelf: shelf, now: () => now),
          watchedMovie: movie,
        );
        movie.value = watched(rating: Rating(4), watchedOn: chosenDay);
        own.dispose();

        write(own);

        expect(shelf.personalWrites, isEmpty);
      });
    }

    test('deve parar de ouvir o filme', () {
      final own = _CountingListenable();
      WatchedDiaryNotifier(
        shelf: shelf,
        chooseWatchedOn: ChooseWatchedOn(shelf: shelf, now: () => now),
        watchedMovie: own,
      ).dispose();

      expect(own.listeners, 0);
    });

    test('deve ignorar a recusa que chega depois', () async {
      final own = WatchedDiaryNotifier(
        shelf: shelf,
        chooseWatchedOn: ChooseWatchedOn(shelf: shelf, now: () => now),
        watchedMovie: movie,
      );
      movie.value = watched();
      own.tapStar(2);
      own.dispose();

      shelf.personalWrites.last.fail(const NetworkFailure());

      await expectLater(pumpEventQueue(), completes);
    });
  });
}

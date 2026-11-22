import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/core/error/failures.dart';
import 'package:ja_vi_esse_filme/features/auth/domain/entities/app_user.dart';
import 'package:ja_vi_esse_filme/features/auth/domain/entities/auth_state.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/movie_copy.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/shelf_entry.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/shelf_mark.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/shelf_movie.dart';
import 'package:ja_vi_esse_filme/features/shelf/presentation/state/shelf_marks_notifier.dart';
import 'package:ja_vi_esse_filme/features/shelf/presentation/state/shelf_marks_state.dart';

import '../../../../helpers/fake_shelf_repository.dart';

void main() {
  late FakeShelfRepository shelf;
  late StreamController<AuthState> account;
  late ShelfMarksNotifier notifier;

  final ana = AppUser(uid: 'ana123', displayName: 'Ana');
  final bia = AppUser(uid: 'bia456', displayName: 'Bia');
  final copy = MovieCopy(movieId: 550, title: 'Clube da Luta');

  ShelfMovie movieWith(Set<ShelfMark> marks) => ShelfMovie(
    copy: copy,
    cachedAt: DateTime.utc(2026, 11),
    marks: {for (final mark in marks) mark: DateTime.utc(2026, 11)},
  );

  Set<ShelfMark>? readyMarks() => switch (notifier.state) {
    ShelfMarksReady(:final marks) => marks,
    _ => null,
  };

  ShelfFailedWrite? failedWrite() => switch (notifier.state) {
    ShelfMarksReady(:final failedWrite) => failedWrite,
    _ => null,
  };

  Future<void> signInAs(AppUser user) async {
    account.add(SignedIn(user));
    await pumpEventQueue();
  }

  Future<void> emitEntry(ShelfEntry entry) async {
    shelf.emit(entry);
    await pumpEventQueue();
  }

  setUp(() {
    shelf = FakeShelfRepository();
    account = StreamController<AuthState>.broadcast();
    notifier = ShelfMarksNotifier(
      shelf: shelf,
      account: account.stream,
      copy: copy,
    );
  });

  tearDown(() async {
    notifier.dispose();
    shelf.close();
    await account.close();
  });

  group('leitura', () {
    test('deve começar carregando, antes do primeiro estado da conta', () {
      expect(notifier.state, isA<ShelfMarksLoading>());
    });

    test('deve ficar deslogado quando a conta emite SignedOut', () async {
      account.add(const SignedOut());
      await pumpEventQueue();

      expect(notifier.state, isA<ShelfMarksSignedOut>());
    });

    test('deve assinar o filme da cópia quando a conta entra', () async {
      await signInAs(ana);

      expect(shelf.watchedMovieIds, [550]);
    });

    test(
      'deve continuar carregando até o primeiro evento da Estante',
      () async {
        await signInAs(ana);

        expect(notifier.state, isA<ShelfMarksLoading>());
      },
    );

    test('deve ficar sem marcas quando o filme não está na Estante', () async {
      await signInAs(ana);
      await emitEntry(const NotOnShelf());

      expect(readyMarks(), isEmpty);
    });

    test('deve mostrar as marcas do filme que está na Estante', () async {
      await signInAs(ana);
      await emitEntry(
        OnShelf(movieWith({ShelfMark.watched, ShelfMark.favorite})),
      );

      expect(readyMarks(), {ShelfMark.watched, ShelfMark.favorite});
    });

    test('deve mostrar o erro quando a leitura da Estante falha', () async {
      await signInAs(ana);
      shelf.emitError(const NetworkFailure());
      await pumpEventQueue();

      expect(
        notifier.state,
        isA<ShelfMarksError>().having(
          (s) => s.failure,
          'failure',
          isA<NetworkFailure>(),
        ),
      );
    });

    test('deve trocar um erro fora das falhas por UnexpectedFailure', () async {
      await signInAs(ana);
      shelf.emitError(StateError('bug'));
      await pumpEventQueue();

      expect(
        notifier.state,
        isA<ShelfMarksError>().having(
          (s) => s.failure,
          'failure',
          isA<UnexpectedFailure>(),
        ),
      );
    });

    test('deve assinar de novo ao tentar de novo depois do erro', () async {
      await signInAs(ana);
      shelf.emitError(const NetworkFailure());
      await pumpEventQueue();

      notifier.retry();
      await pumpEventQueue();

      expect(shelf.watchCalls, 2);
    });

    test('deve voltar a carregar ao tentar de novo', () async {
      await signInAs(ana);
      shelf.emitError(const NetworkFailure());
      await pumpEventQueue();

      notifier.retry();

      expect(notifier.state, isA<ShelfMarksLoading>());
    });

    test('deve avisar os ouvintes quando as marcas chegam', () async {
      await signInAs(ana);
      var notified = 0;
      notifier.addListener(() => notified++);

      await emitEntry(const NotOnShelf());

      expect(notified, 1);
    });
  });

  group('conta', () {
    test('deve parar de ouvir a Estante quando a conta sai', () async {
      await signInAs(ana);
      account.add(const SignedOut());
      await pumpEventQueue();

      expect(shelf.isWatching, isFalse);
    });

    test('deve assinar de novo quando a conta muda', () async {
      await signInAs(ana);
      await signInAs(bia);

      expect(shelf.watchCalls, 2);
    });

    test(
      'deve largar o stream da conta anterior quando a conta muda',
      () async {
        await signInAs(ana);
        await signInAs(bia);

        expect(shelf.activeWatches, 1);
      },
    );

    test('deve voltar a carregar quando a conta muda', () async {
      await signInAs(ana);
      await emitEntry(OnShelf(movieWith({ShelfMark.watched})));

      await signInAs(bia);

      expect(notifier.state, isA<ShelfMarksLoading>());
    });

    test('deve ignorar o SignedIn repetido da mesma conta', () async {
      await signInAs(ana);
      await signInAs(ana);

      expect(shelf.watchCalls, 1);
    });

    test('deve parar de ouvir a conta e a Estante no dispose', () async {
      final otherShelf = FakeShelfRepository();
      final otherAccount = StreamController<AuthState>.broadcast();
      addTearDown(otherAccount.close);
      final other = ShelfMarksNotifier(
        shelf: otherShelf,
        account: otherAccount.stream,
        copy: copy,
      );
      otherAccount.add(SignedIn(ana));
      await pumpEventQueue();

      other.dispose();
      await pumpEventQueue();

      expect((otherAccount.hasListener, otherShelf.isWatching), (false, false));
    });

    // O erro da conta aparece no login; aqui não há o que assinar de novo.
    test('deve ficar deslogado quando o stream da conta falha', () async {
      account.addError(const NetworkFailure());
      await pumpEventQueue();

      expect(notifier.state, isA<ShelfMarksSignedOut>());
    });
  });

  group('marcar e desmarcar', () {
    Future<void> readyWith(Set<ShelfMark> marks) async {
      await signInAs(ana);
      await emitEntry(
        marks.isEmpty ? const NotOnShelf() : OnShelf(movieWith(marks)),
      );
    }

    test('deve mostrar a marca na hora, sem esperar o servidor', () async {
      await readyWith({});

      notifier.toggle(ShelfMark.watched);

      expect(readyMarks(), {ShelfMark.watched});
    });

    test('deve pedir à Estante a marca com a cópia do filme', () async {
      await readyWith({});

      notifier.toggle(ShelfMark.watchlist);

      expect(
        (shelf.writes.single.copy, shelf.writes.single.mark),
        (copy, ShelfMark.watchlist),
      );
    });

    test('deve tirar a marca na hora, sem esperar o servidor', () async {
      await readyWith({ShelfMark.watched, ShelfMark.favorite});

      notifier.toggle(ShelfMark.favorite);

      expect(readyMarks(), {ShelfMark.watched});
    });

    test('deve pedir à Estante para tirar a marca do filme lido', () async {
      final movie = movieWith({ShelfMark.favorite});
      await signInAs(ana);
      await emitEntry(OnShelf(movie));

      notifier.toggle(ShelfMark.favorite);

      expect(
        (shelf.writes.single.movie, shelf.writes.single.mark),
        (movie, ShelfMark.favorite),
      );
    });

    test('deve seguir a Estante quando ela confirma a marca', () async {
      await readyWith({});
      notifier.toggle(ShelfMark.watched);

      await emitEntry(
        OnShelf(movieWith({ShelfMark.watched, ShelfMark.favorite})),
      );

      expect(readyMarks(), {ShelfMark.watched, ShelfMark.favorite});
    });

    test('deve voltar ao que a Estante diz quando o servidor recusa', () async {
      await readyWith({});
      notifier.toggle(ShelfMark.watched);

      shelf.writes.single.fail(const RateLimitFailure());
      await pumpEventQueue();

      expect(readyMarks(), isEmpty);
    });

    test('deve mostrar a escrita recusada com a falha', () async {
      await readyWith({});
      notifier.toggle(ShelfMark.watched);

      shelf.writes.single.fail(const RateLimitFailure());
      await pumpEventQueue();

      expect(
        failedWrite(),
        isA<ShelfFailedWrite>()
            .having((w) => w.mark, 'mark', ShelfMark.watched)
            .having((w) => w.marked, 'marked', true)
            .having((w) => w.failure, 'failure', isA<RateLimitFailure>()),
      );
    });

    test(
      'deve trocar uma exceção fora das falhas por UnexpectedFailure',
      () async {
        await readyWith({});
        notifier.toggle(ShelfMark.watched);

        shelf.writes.single.fail(Exception('sdk'));
        await pumpEventQueue();

        expect(failedWrite()?.failure, isA<UnexpectedFailure>());
      },
    );

    test('deve manter a falha quando a Estante emite de novo', () async {
      await readyWith({});
      notifier.toggle(ShelfMark.watched);
      shelf.writes.single.fail(const RateLimitFailure());
      await pumpEventQueue();

      await emitEntry(const NotOnShelf());

      expect(failedWrite(), isNotNull);
    });

    test('deve repetir a escrita recusada ao tentar de novo', () async {
      await readyWith({});
      notifier.toggle(ShelfMark.watched);
      shelf.writes.single.fail(const RateLimitFailure());
      await pumpEventQueue();

      notifier.retryWrite();

      expect(
        (shelf.writes.length, shelf.writes.last.mark, shelf.writes.last.isAdd),
        (2, ShelfMark.watched, true),
      );
    });

    test('deve limpar a falha ao tentar de novo', () async {
      await readyWith({});
      notifier.toggle(ShelfMark.watched);
      shelf.writes.single.fail(const RateLimitFailure());
      await pumpEventQueue();

      notifier.retryWrite();

      expect(failedWrite(), isNull);
    });

    test('deve limpar a falha ao mexer em outra marca', () async {
      await readyWith({});
      notifier.toggle(ShelfMark.watched);
      shelf.writes.single.fail(const RateLimitFailure());
      await pumpEventQueue();

      notifier.toggle(ShelfMark.favorite);

      expect(failedWrite(), isNull);
    });

    test('deve voltar só a marca recusada, sem mexer nas outras', () async {
      await readyWith({});
      notifier.toggle(ShelfMark.watched);
      notifier.toggle(ShelfMark.favorite);

      shelf.writes.first.fail(const RateLimitFailure());
      await pumpEventQueue();

      expect(readyMarks(), {ShelfMark.favorite});
    });

    test('deve ignorar a falha de uma escrita já substituída', () async {
      await readyWith({});
      notifier.toggle(ShelfMark.watched);
      await emitEntry(OnShelf(movieWith({ShelfMark.watched})));
      notifier.toggle(ShelfMark.watched);

      shelf.writes.first.fail(const RateLimitFailure());
      await pumpEventQueue();

      expect(readyMarks(), isEmpty);
    });

    // O Firestore confirma no aparelho antes de o servidor responder.
    test(
      'deve mostrar a recusa que chega depois da confirmação local',
      () async {
        await readyWith({});
        notifier.toggle(ShelfMark.watched);
        await emitEntry(OnShelf(movieWith({ShelfMark.watched})));

        shelf.writes.single.fail(const RateLimitFailure());
        await pumpEventQueue();

        expect(failedWrite()?.mark, ShelfMark.watched);
      },
    );

    test(
      'deve manter o erro de leitura quando uma escrita falha depois',
      () async {
        await readyWith({});
        notifier.toggle(ShelfMark.watched);
        shelf.emitError(const NetworkFailure());
        await pumpEventQueue();

        shelf.writes.single.fail(const RateLimitFailure());
        await pumpEventQueue();

        expect(notifier.state, isA<ShelfMarksError>());
      },
    );

    test('deve ignorar a falha de uma escrita da conta anterior', () async {
      await readyWith({});
      notifier.toggle(ShelfMark.watched);
      await signInAs(bia);
      await emitEntry(const NotOnShelf());
      notifier.toggle(ShelfMark.watched);

      shelf.writes.first.fail(const RateLimitFailure());
      await pumpEventQueue();

      expect(readyMarks(), {ShelfMark.watched});
    });

    test('deve não desmarcar o que a Estante ainda não confirmou', () async {
      await readyWith({});
      notifier.toggle(ShelfMark.watched);

      notifier.toggle(ShelfMark.watched);

      expect(shelf.writes.length, 1);
    });

    test('deve ignorar o toque sem ninguém logado', () async {
      account.add(const SignedOut());
      await pumpEventQueue();

      notifier.toggle(ShelfMark.watched);

      expect(shelf.writes, isEmpty);
    });
  });

  group('fim do stream', () {
    test('deve voltar a carregar quando a Estante encerra o stream', () async {
      await signInAs(ana);
      await emitEntry(const NotOnShelf());

      shelf.endWatch();
      await pumpEventQueue();

      expect(notifier.state, isA<ShelfMarksLoading>());
    });

    // No logout, a Estante fecha antes de a conta sair: uma marca nessa
    // janela reabriria o Firestore com o cache da conta.
    test(
      'deve ignorar o toque depois que a Estante encerra o stream',
      () async {
        await signInAs(ana);
        await emitEntry(const NotOnShelf());
        shelf.endWatch();
        await pumpEventQueue();

        notifier.toggle(ShelfMark.watched);

        expect(shelf.writes, isEmpty);
      },
    );
  });

  group('depois do dispose', () {
    test('deve ignorar a marca pedida', () async {
      final otherShelf = FakeShelfRepository();
      final otherAccount = StreamController<AuthState>.broadcast();
      addTearDown(otherAccount.close);
      final other = ShelfMarksNotifier(
        shelf: otherShelf,
        account: otherAccount.stream,
        copy: copy,
      );
      otherAccount.add(SignedIn(ana));
      await pumpEventQueue();
      otherShelf.emit(const NotOnShelf());
      await pumpEventQueue();

      other
        ..dispose()
        ..queueMark(ShelfMark.watched);

      expect(otherShelf.writes, isEmpty);
    });
  });

  group('marca pedida antes do login', () {
    test('deve pôr a marca pedida quando a Estante chega', () async {
      account.add(const SignedOut());
      await pumpEventQueue();
      notifier.queueMark(ShelfMark.favorite);

      await signInAs(ana);
      await emitEntry(const NotOnShelf());

      expect(
        (shelf.writes.single.mark, shelf.writes.single.isAdd),
        (ShelfMark.favorite, true),
      );
    });

    test('deve mostrar a marca pedida assim que a Estante chega', () async {
      account.add(const SignedOut());
      await pumpEventQueue();
      notifier.queueMark(ShelfMark.favorite);

      await signInAs(ana);
      await emitEntry(const NotOnShelf());

      expect(readyMarks(), {ShelfMark.favorite});
    });

    test('deve não desmarcar quando a conta já tinha a marca', () async {
      account.add(const SignedOut());
      await pumpEventQueue();
      notifier.queueMark(ShelfMark.favorite);

      await signInAs(ana);
      await emitEntry(OnShelf(movieWith({ShelfMark.favorite})));

      expect(shelf.writes, isEmpty);
    });

    test('deve pôr a marca na hora quando a Estante já chegou', () async {
      await signInAs(ana);
      await emitEntry(const NotOnShelf());

      notifier.queueMark(ShelfMark.watched);

      expect(shelf.writes.single.mark, ShelfMark.watched);
    });

    test('deve esquecer a marca pedida quando a conta sai', () async {
      account.add(const SignedOut());
      await pumpEventQueue();
      notifier.queueMark(ShelfMark.favorite);

      account.add(const SignedOut());
      await pumpEventQueue();
      await signInAs(ana);
      await emitEntry(const NotOnShelf());

      expect(shelf.writes, isEmpty);
    });
  });

  // O filme que a nota e o dia usam (decisão 018): o confirmado pela
  // Estante, só enquanto a tela mostra o Assistido ligado.
  group('filme assistido', () {
    test('deve começar sem filme', () {
      expect(notifier.watchedMovie.value, isNull);
    });

    test('deve dar o filme com o Assistido confirmado', () async {
      final movie = movieWith({ShelfMark.watched});
      await signInAs(ana);

      await emitEntry(OnShelf(movie));

      expect(notifier.watchedMovie.value, movie);
    });

    test('não deve dar o filme sem o Assistido', () async {
      await signInAs(ana);

      await emitEntry(OnShelf(movieWith({ShelfMark.favorite})));

      expect(notifier.watchedMovie.value, isNull);
    });

    test('não deve dar o filme com o Assistido só otimista', () async {
      await signInAs(ana);
      await emitEntry(const NotOnShelf());

      notifier.toggle(ShelfMark.watched);

      expect(notifier.watchedMovie.value, isNull);
    });

    test('deve tirar o filme ao desligar o Assistido na tela', () async {
      await signInAs(ana);
      await emitEntry(OnShelf(movieWith({ShelfMark.watched})));

      notifier.toggle(ShelfMark.watched);

      expect(notifier.watchedMovie.value, isNull);
    });

    test('deve tirar o filme quando a conta sai', () async {
      await signInAs(ana);
      await emitEntry(OnShelf(movieWith({ShelfMark.watched})));

      account.add(const SignedOut());
      await pumpEventQueue();

      expect(notifier.watchedMovie.value, isNull);
    });

    test('deve tirar o filme ao trocar de conta', () async {
      await signInAs(ana);
      await emitEntry(OnShelf(movieWith({ShelfMark.watched})));

      await signInAs(bia);

      expect(notifier.watchedMovie.value, isNull);
    });
  });

  group('filme confirmado, para as listas (decisão 019)', () {
    test('deve começar sem filme confirmado', () {
      expect(notifier.confirmedEntry.value, isNull);
    });

    test('deve dar o que a Estante confirmou', () async {
      final movie = movieWith({ShelfMark.favorite});
      await signInAs(ana);

      await emitEntry(OnShelf(movie));

      expect(notifier.confirmedEntry.value, OnShelf(movie));
    });

    test('deve dar o filme fora da Estante', () async {
      await signInAs(ana);

      await emitEntry(const NotOnShelf());

      expect(notifier.confirmedEntry.value, const NotOnShelf());
    });

    test('deve esquecer o filme quando a conta sai', () async {
      await signInAs(ana);
      await emitEntry(const NotOnShelf());

      account.add(const SignedOut());
      await pumpEventQueue();

      expect(notifier.confirmedEntry.value, isNull);
    });

    test('deve esquecer o filme quando o stream acaba no logout', () async {
      await signInAs(ana);
      await emitEntry(const NotOnShelf());

      shelf.endWatch();
      await pumpEventQueue();

      expect(notifier.confirmedEntry.value, isNull);
    });
  });
}

import { after, beforeEach, describe, test } from 'node:test';
import assert from 'node:assert/strict';
import { assertSucceeds } from '@firebase/rules-unit-testing';
import { Timestamp } from 'firebase-admin/firestore';
import { doc, serverTimestamp, updateDoc } from 'firebase/firestore';
import { MOVIES, renewExpiredCopies } from '../../cleanup/expired-copies.js';
import { collectionsInApp } from '../../cleanup/user-collections.js';
import {
  MissingTitleError,
  MovieNotFoundError,
  RateLimitedError,
  TmdbError,
  UnauthorizedError,
} from '../../cleanup/tmdb-copy.js';
import { clearEmulators, createAccount, createAdmin, movieIds } from './admin-environment.js';
import { createTestEnvironment, googleContext } from '../environment.js';

// Cópias do TMDB com mais de 180 dias (decisões 013 e 017): a limpeza
// mensal renova pelo TMDB as que a Estante não renovou. O NOW longe da hora
// real separa o relógio de quem roda do relógio do servidor.
const DAY = 24 * 60 * 60 * 1000;
const NOW = new Date('2040-01-01T12:00:00Z');
const EMPTY = { expired: 0, renewed: 0, removed: 0, failed: 0, noTitle: 0, skipped: 0, stopped: null };
const NOT_FOUND = () => new MovieNotFoundError('sumiu');
const POSTER = '/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg';
const NEW_POSTER = '/novoPoster123.jpg';

function daysAgo(days) {
  return Timestamp.fromDate(new Date(NOW.getTime() - days * DAY));
}

// Responde cada filme com uma cópia ou um erro, e guarda o que foi pedido.
function fakeSource(answers = {}) {
  const requested = [];
  return {
    requested,
    async fetchCopy(movieId) {
      requested.push(movieId);
      const answer = answers[movieId] ?? { title: 'Título novo', posterPath: NEW_POSTER };
      if (answer instanceof Error) throw answer;
      return answer;
    },
  };
}

describe('cópias vencidas do TMDB', () => {
  test('deve procurar as cópias numa subcoleção que o app conhece', () => {
    assert.ok(collectionsInApp().includes(MOVIES));
  });

  const admin = createAdmin();
  const { auth, db } = admin;

  beforeEach(async () => {
    await clearEmulators();
    await createAccount(auth, 'alice');
  });
  after(() => admin.close());

  function addMovie(movieId, { ageDays, ...fields } = {}) {
    return db.doc(`users/alice/movies/${movieId}`).set({
      title: 'Título antigo',
      posterPath: POSTER,
      cachedAt: daysAgo(ageDays ?? 200),
      watchedAt: daysAgo(300),
      ...fields,
    });
  }

  async function movie(movieId) {
    return (await db.doc(`users/alice/movies/${movieId}`).get()).data();
  }

  function renew(source, options = {}) {
    return renewExpiredCopies({ db, source, now: NOW, ...options });
  }

  test('deve renovar o título e o pôster da cópia vencida', async () => {
    await addMovie('550');

    await renew(fakeSource());

    const { title, posterPath } = await movie('550');
    assert.deepEqual({ title, posterPath }, { title: 'Título novo', posterPath: NEW_POSTER });
  });

  test('deve renovar o cachedAt com a hora do servidor', async () => {
    await addMovie('550');

    await renew(fakeSource());

    assert.ok(Math.abs((await movie('550')).cachedAt.toMillis() - Date.now()) < 60_000);
  });

  test('deve manter as marcas ao renovar a cópia', async () => {
    await addMovie('550', { favoriteAt: daysAgo(250) });

    await renew(fakeSource());

    const { watchedAt, favoriteAt } = await movie('550');
    assert.deepEqual(
      { watchedAt, favoriteAt },
      { watchedAt: daysAgo(300), favoriteAt: daysAgo(250) },
    );
  });

  test('deve tirar o pôster quando o TMDB não manda um', async () => {
    await addMovie('550');

    await renew(fakeSource({ 550: { title: 'Título novo', posterPath: null } }));

    assert.equal('posterPath' in (await movie('550')), false);
  });

  test('não deve mexer na cópia dentro do prazo', async () => {
    await addMovie('550', { ageDays: 179 });
    const source = fakeSource();

    await renew(source);

    assert.deepEqual(source.requested, []);
  });

  test('deve tratar como vencida a cópia com exatamente 180 dias, como o app', async () => {
    await addMovie('550', { ageDays: 180 });
    const source = fakeSource();

    await renew(source);

    assert.deepEqual(source.requested, [550]);
  });

  test('deve apagar o filme que sumiu do TMDB', async () => {
    await addMovie('550');

    await renew(fakeSource({ 550: NOT_FOUND() }));

    assert.deepEqual(await movieIds(db, 'alice'), []);
  });

  test('deve seguir para o próximo filme quando um falha', async () => {
    await addMovie('550');
    await addMovie('603');

    await renew(fakeSource({ 550: new TmdbError('500') }));

    assert.equal((await movie('603')).title, 'Título novo');
  });

  test('deve contar as cópias renovadas, os filmes apagados, as falhas e os sem título', async () => {
    for (const id of ['13', '550', '603', '680', '807']) await addMovie(id);

    const report = await renew(fakeSource({
      603: NOT_FOUND(),
      680: new MissingTitleError('sem título'),
      807: new TmdbError('500'),
    }));

    assert.deepEqual(report, { ...EMPTY, expired: 5, renewed: 2, removed: 1, failed: 1, noTitle: 1 });
  });

  test('deve parar no limite de requisições do TMDB e deixar o resto vencido', async () => {
    await addMovie('13');
    await addMovie('550');
    const source = fakeSource({ 13: new RateLimitedError('429') });

    const report = await renew(source);

    assert.deepEqual(
      { requested: source.requested, report },
      { requested: [13], report: { ...EMPTY, expired: 2, stopped: 'rate-limit' } },
    );
  });

  test('na simulação, deve contar as vencidas sem chamar o TMDB nem gravar', async () => {
    await addMovie('550');
    const source = fakeSource();

    const report = await renew(source, { dryRun: true });

    assert.deepEqual(
      { report, requested: source.requested, title: (await movie('550')).title },
      {
        report: { ...EMPTY, expired: 1 },
        requested: [],
        title: 'Título antigo',
      },
    );
  });

  test('deve parar quando o TMDB recusa o token', async () => {
    await addMovie('13');
    await addMovie('550');
    const source = fakeSource({ 13: new UnauthorizedError('401') });

    const report = await renew(source);

    assert.deepEqual(
      { requested: source.requested, stopped: report.stopped },
      { requested: [13], stopped: 'unauthorized' },
    );
  });

  // Vários 404 seguidos sugerem um problema do lado do TMDB, e não filmes
  // removidos: a limpeza para sem apagar o quinto.
  test('deve parar no quinto 404 seguido sem apagar esse filme', async () => {
    const ids = ['1', '2', '3', '4', '5', '6'];
    for (const id of ids) await addMovie(id);
    const source = fakeSource(Object.fromEntries(ids.map((id) => [id, NOT_FOUND()])));

    const report = await renew(source);

    assert.deepEqual(
      { removed: report.removed, stopped: report.stopped, left: await movieIds(db, 'alice') },
      { removed: 4, stopped: 'not-found-streak', left: ['5', '6'] },
    );
  });

  test('deve recomeçar a contagem de 404 depois de uma cópia renovada', async () => {
    const ids = ['1', '2', '3', '4', '5', '6'];
    for (const id of ids) await addMovie(id);
    const answers = Object.fromEntries(ids.map((id) => [id, NOT_FOUND()]));
    delete answers['3'];

    const report = await renew(fakeSource(answers));

    assert.deepEqual({ removed: report.removed, stopped: report.stopped }, { removed: 5, stopped: null });
  });

  test('deve pular o filme desmarcado enquanto o TMDB respondia', async () => {
    await addMovie('13');
    await addMovie('550');
    const source = {
      async fetchCopy(movieId) {
        if (movieId === 13) await db.doc('users/alice/movies/13').delete();
        return { title: 'Título novo', posterPath: null };
      },
    };

    const report = await renew(source);

    assert.deepEqual({ renewed: report.renewed, skipped: report.skipped }, { renewed: 1, skipped: 1 });
  });

  test('deve parar quando a cota do Firestore acaba', async () => {
    await addMovie('13');
    await addMovie('550');
    const quota = Object.assign(new Error('RESOURCE_EXHAUSTED'), { code: 8 });

    const report = await renew(fakeSource({ 13: quota }));

    assert.equal(report.stopped, 'quota');
  });

  test('deve parar no teto de escritas da execução', async () => {
    await addMovie('13');
    await addMovie('550');

    const report = await renew(fakeSource(), { maxWrites: 1 });

    assert.deepEqual({ renewed: report.renewed, stopped: report.stopped }, { renewed: 1, stopped: 'write-limit' });
  });

  test('deve ignorar as contas da lista de puladas', async () => {
    await addMovie('550');

    const report = await renew(fakeSource(), { dryRun: true, skipUserIds: new Set(['alice']) });

    assert.equal(report.expired, 0);
  });

  test('deve levar no erro inesperado o que já tinha feito', async () => {
    await addMovie('13');
    await addMovie('550');

    await assert.rejects(
      renew(fakeSource({ 550: new TypeError('bug') })),
      (error) => error.partialReport?.renewed === 1,
    );
  });

  test('deve deixar o documento renovado válido para a próxima marca do app', async () => {
    await addMovie('550');
    await renew(fakeSource());
    const testEnv = await createTestEnvironment();

    try {
      const firestore = googleContext(testEnv, 'alice').firestore();
      await assertSucceeds(updateDoc(doc(firestore, 'users/alice/movies/550'), {
        watchlistAt: serverTimestamp(),
      }));
    } finally {
      await testEnv.cleanup();
    }
  });
});

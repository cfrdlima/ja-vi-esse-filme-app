import { after, beforeEach, describe, test } from 'node:test';
import assert from 'node:assert/strict';
import { assertSucceeds } from '@firebase/rules-unit-testing';
import { Timestamp } from 'firebase-admin/firestore';
import { doc, serverTimestamp, updateDoc } from 'firebase/firestore';
import { renewExpiredCopies } from '../../cleanup/expired-copies.js';
import {
  MissingTitleError,
  MovieNotFoundError,
  RateLimitedError,
  TmdbError,
} from '../../cleanup/tmdb-copy.js';
import { clearEmulators, createAccount, createAdmin, movieIds } from './admin-environment.js';
import { createTestEnvironment, googleContext } from '../environment.js';

// Cópias do TMDB com mais de 180 dias (decisões 013 e 017): a limpeza
// mensal renova pelo TMDB as que a Estante não renovou.
const DAY = 24 * 60 * 60 * 1000;
const NOW = new Date('2026-11-18T12:00:00Z');
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

    assert.ok((await movie('550')).cachedAt.toMillis() > NOW.getTime() - DAY);
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

    await renew(fakeSource({ 550: new MovieNotFoundError('sumiu') }));

    assert.deepEqual(await movieIds(db, 'alice'), []);
  });

  test('deve seguir para o próximo filme quando um falha', async () => {
    await addMovie('550');
    await addMovie('603');

    await renew(fakeSource({ 550: new TmdbError('500') }));

    assert.equal((await movie('603')).title, 'Título novo');
  });

  test('deve contar as cópias renovadas, os filmes apagados e as falhas', async () => {
    await addMovie('550');
    await addMovie('603');
    await addMovie('680');
    await addMovie('13');

    const report = await renew(fakeSource({
      603: new MovieNotFoundError('sumiu'),
      680: new MissingTitleError('sem título'),
    }));

    assert.deepEqual(report, { expired: 4, renewed: 2, removed: 1, failed: 1, rateLimited: false });
  });

  test('deve parar no limite de requisições do TMDB e deixar o resto vencido', async () => {
    await addMovie('13');
    await addMovie('550');
    const source = fakeSource({ 13: new RateLimitedError('429') });

    const report = await renew(source);

    assert.deepEqual(
      { requested: source.requested, report },
      {
        requested: [13],
        report: { expired: 2, renewed: 0, removed: 0, failed: 0, rateLimited: true },
      },
    );
  });

  test('na simulação, deve contar as vencidas sem chamar o TMDB nem gravar', async () => {
    await addMovie('550');
    const source = fakeSource();

    const report = await renew(source, { dryRun: true });

    assert.deepEqual(
      { report, requested: source.requested, title: (await movie('550')).title },
      {
        report: { expired: 1, renewed: 0, removed: 0, failed: 0, rateLimited: false },
        requested: [],
        title: 'Título antigo',
      },
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

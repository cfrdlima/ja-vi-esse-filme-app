import { after, beforeEach, describe, test } from 'node:test';
import assert from 'node:assert/strict';
import { Timestamp } from 'firebase-admin/firestore';
import { removeOrphanListKeys } from '../../cleanup/orphan-list-keys.js';
import { clearEmulators, createAccount, createAdmin, movieIds } from './admin-environment.js';

// Uma chave do mapa lists sem o users/{uid}/lists/{id} dela: filme posto
// offline numa lista que outro aparelho apagou, ou numa lista cuja criação
// o servidor recusou (decisão 019, `/revisar` da sessão 029).
const LIVE = 'Lst0aBcDeFgHiJkLmNoP';
const GONE = 'Lst1aBcDeFgHiJkLmNoP';
const AT = Timestamp.fromMillis(1_700_000_000_000);

describe('chaves de lista sem lista', () => {
  const admin = createAdmin();
  const { auth, db } = admin;

  beforeEach(async () => {
    await clearEmulators();
    await createAccount(auth, 'alice');
    await db.doc(`users/alice/lists/${LIVE}`).set({ name: 'Terror' });
  });
  after(() => admin.close());

  function addMovie(movieId, fields) {
    return db.doc(`users/alice/movies/${movieId}`).set({
      title: 'Clube da Luta',
      cachedAt: AT,
      ...fields,
    });
  }

  async function movie(movieId) {
    return (await db.doc(`users/alice/movies/${movieId}`).get()).data();
  }

  test('deve tirar a chave sem lista e manter a que tem lista', async () => {
    await addMovie('550', { lists: { [LIVE]: AT, [GONE]: AT } });

    await removeOrphanListKeys({ db });

    assert.deepEqual((await movie('550')).lists, { [LIVE]: AT });
  });

  test('deve tirar o mapa do filme marcado que só tinha chaves sem lista', async () => {
    await addMovie('550', { watchedAt: AT, rating: 8, lists: { [GONE]: AT } });

    await removeOrphanListKeys({ db });

    const { lists, rating } = await movie('550');
    assert.deepEqual({ lists, rating }, { lists: undefined, rating: 8 });
  });

  test('deve apagar o filme sem marca que só tinha chaves sem lista', async () => {
    await addMovie('550', { lists: { [GONE]: AT } });

    await removeOrphanListKeys({ db });

    assert.deepEqual(await movieIds(db, 'alice'), []);
  });

  test('não deve mexer no filme sem chave sem lista', async () => {
    await addMovie('550', { lists: { [LIVE]: AT } });
    await addMovie('551', { watchedAt: AT });

    const report = await removeOrphanListKeys({ db });

    assert.deepEqual(report, { keys: 0, movies: 0, removed: 0 });
  });

  test('deve contar as chaves, os filmes mexidos e os apagados', async () => {
    await addMovie('550', { lists: { [LIVE]: AT, [GONE]: AT } });
    await addMovie('551', { lists: { [GONE]: AT } });

    const report = await removeOrphanListKeys({ db });

    assert.deepEqual(report, { keys: 2, movies: 2, removed: 1 });
  });

  test('na simulação, deve contar sem gravar', async () => {
    await addMovie('551', { lists: { [GONE]: AT } });

    const report = await removeOrphanListKeys({ db, dryRun: true });

    assert.deepEqual(
      { report, movies: await movieIds(db, 'alice') },
      { report: { keys: 1, movies: 1, removed: 1 }, movies: ['551'] },
    );
  });

  test('deve pular os usuários pedidos', async () => {
    await addMovie('551', { lists: { [GONE]: AT } });

    await removeOrphanListKeys({ db, skipUserIds: new Set(['alice']) });

    assert.deepEqual(await movieIds(db, 'alice'), ['551']);
  });
});

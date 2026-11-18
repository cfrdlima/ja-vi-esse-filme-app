import { after, beforeEach, describe, test } from 'node:test';
import assert from 'node:assert/strict';
import { Timestamp } from 'firebase-admin/firestore';
import { deleteOrphanUserData } from '../../cleanup/orphan-user-data.js';
import { clearEmulators, createAccount, createAdmin, movieIds } from './admin-environment.js';

// Dados que ficaram sem conta no Auth (decisões 015 e 017): outro aparelho
// com um ID token ainda válido pode recriar users/{uid}/movies depois da
// exclusão da conta.
describe('dados sem conta no Auth', () => {
  const admin = createAdmin();
  const { auth, db } = admin;

  beforeEach(clearEmulators);
  after(() => admin.close());

  function addMovie(uid, movieId = '550') {
    return db.doc(`users/${uid}/movies/${movieId}`).set({
      title: 'Clube da Luta',
      cachedAt: Timestamp.now(),
      watchedAt: Timestamp.now(),
    });
  }

  test('deve apagar os filmes de um users/{uid} sem conta no Auth', async () => {
    await addMovie('sem-conta');

    await deleteOrphanUserData({ auth, db });

    assert.deepEqual(await movieIds(db, 'sem-conta'), []);
  });

  test('não deve apagar os filmes de quem tem conta', async () => {
    await createAccount(auth, 'alice');
    await addMovie('alice');

    await deleteOrphanUserData({ auth, db });

    assert.deepEqual(await movieIds(db, 'alice'), ['550']);
  });

  test('deve apagar também o documento users/{uid} quando ele existe', async () => {
    await db.doc('users/sem-conta').set({ antigo: true });
    await addMovie('sem-conta');

    await deleteOrphanUserData({ auth, db });

    assert.equal((await db.doc('users/sem-conta').get()).exists, false);
  });

  test('deve contar quantos users/{uid} sem conta foram apagados', async () => {
    await createAccount(auth, 'alice');
    await addMovie('alice');
    await addMovie('sem-conta-1');
    await addMovie('sem-conta-2');

    const report = await deleteOrphanUserData({ auth, db });

    assert.equal(report.orphanUsers, 2);
  });

  test('deve ler todas as páginas de contas do Auth', async () => {
    for (const uid of ['alice', 'bob', 'carol']) {
      await createAccount(auth, uid);
      await addMovie(uid);
    }

    await deleteOrphanUserData({ auth, db, pageSize: 1 });

    assert.deepEqual(await movieIds(db, 'carol'), ['550']);
  });

  test('na simulação, deve contar sem apagar nada', async () => {
    await addMovie('sem-conta');

    const report = await deleteOrphanUserData({ auth, db, dryRun: true });

    assert.deepEqual(
      { orphanUsers: report.orphanUsers, movies: await movieIds(db, 'sem-conta') },
      { orphanUsers: 1, movies: ['550'] },
    );
  });
});

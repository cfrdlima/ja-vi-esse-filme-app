import { after, beforeEach, describe, test } from 'node:test';
import assert from 'node:assert/strict';
import { Timestamp } from 'firebase-admin/firestore';
import { OrphanSafetyError, deleteOrphanUserData } from '../../cleanup/orphan-user-data.js';
import { clearEmulators, createAccount, createAdmin, movieIds } from './admin-environment.js';

// Dados que ficaram sem conta no Auth (decisões 015 e 017): outro aparelho
// com um ID token ainda válido pode recriar users/{uid}/movies depois da
// exclusão da conta.
describe('dados sem conta no Auth', () => {
  const admin = createAdmin();
  const { auth, db } = admin;

  // Uma conta que não tem dados, para o Auth nunca vir vazio, a não ser no
  // teste da trava de Auth vazio.
  beforeEach(async () => {
    await clearEmulators();
    await createAccount(auth, 'conta-sem-dados');
  });
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

  // Travas contra apagar em massa (`/revisar` da sessão 027): um Auth vazio
  // ou parcial (emulador por engano, falha de API) faria todo mundo parecer
  // sem conta.
  test('deve recusar apagar quando o Auth não devolve nenhuma conta', async () => {
    await addMovie('alice');
    await auth.deleteUser('conta-sem-dados');

    await assert.rejects(deleteOrphanUserData({ auth, db }), OrphanSafetyError);
  });

  test('não deve apagar nada quando o Auth não devolve nenhuma conta', async () => {
    await addMovie('alice');
    await auth.deleteUser('conta-sem-dados');

    await deleteOrphanUserData({ auth, db }).catch(() => {});

    assert.deepEqual(await movieIds(db, 'alice'), ['550']);
  });

  async function addManyOrphans() {
    await createAccount(auth, 'alice');
    await addMovie('alice');
    for (let i = 1; i <= 6; i++) await addMovie(`sem-conta-${i}`);
  }

  test('deve pedir confirmação quando os sem conta passam do limite', async () => {
    await addManyOrphans();

    await assert.rejects(deleteOrphanUserData({ auth, db }), OrphanSafetyError);
  });

  test('deve apagar acima do limite com a confirmação igual à contagem', async () => {
    await addManyOrphans();

    const report = await deleteOrphanUserData({ auth, db, confirmOrphans: 6 });

    assert.equal(report.orphanUsers, 6);
  });

  test('deve recusar a confirmação diferente da contagem', async () => {
    await addManyOrphans();

    await assert.rejects(deleteOrphanUserData({ auth, db, confirmOrphans: 5 }), OrphanSafetyError);
  });

  test('na simulação, deve avisar que a contagem pede confirmação', async () => {
    await addManyOrphans();

    const report = await deleteOrphanUserData({ auth, db, dryRun: true });

    assert.equal(report.needsConfirmation, true);
  });

  test('não deve apagar os dados de quem ganhou conta durante a limpeza', async () => {
    await createAccount(auth, 'alice');
    await addMovie('novo');
    // A conta nasce depois da listagem das contas e antes da exclusão.
    const racingAuth = {
      listUsers: (...args) => auth.listUsers(...args),
      getUsers: async (identifiers) => {
        await createAccount(auth, 'novo');
        return auth.getUsers(identifiers);
      },
    };

    await deleteOrphanUserData({ auth: racingAuth, db });

    assert.deepEqual(await movieIds(db, 'novo'), ['550']);
  });
});

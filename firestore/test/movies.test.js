import { after, before, beforeEach, describe, test } from 'node:test';
import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import {
  collection,
  collectionGroup,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  query,
  setDoc,
  updateDoc,
  where,
} from 'firebase/firestore';
import {
  MOVIE_ID,
  OTHER_UID,
  OWNER_UID,
  createTestEnvironment,
  googleContext,
  validMovie,
} from './environment.js';

describe('users/{uid}/movies/{movieId}', () => {
  let testEnv;

  before(async () => {
    testEnv = await createTestEnvironment();
  });

  beforeEach(async () => {
    await testEnv.clearFirestore();
  });

  after(async () => {
    await testEnv.cleanup();
  });

  function ownerDb() {
    return googleContext(testEnv, OWNER_UID).firestore();
  }

  function ownerMovie(db) {
    return doc(db, 'users', OWNER_UID, 'movies', MOVIE_ID);
  }

  test('deve deixar o dono gravar o próprio filme', async () => {
    await assertSucceeds(setDoc(ownerMovie(ownerDb()), validMovie()));
  });

  test('deve deixar o dono ler o próprio filme', async () => {
    await assertSucceeds(getDoc(ownerMovie(ownerDb())));
  });

  test('deve deixar o dono apagar o próprio filme', async () => {
    const db = ownerDb();
    await setDoc(ownerMovie(db), validMovie());

    await assertSucceeds(deleteDoc(ownerMovie(db)));
  });

  test('deve negar a leitura sem login', async () => {
    const db = testEnv.unauthenticatedContext().firestore();

    await assertFails(getDoc(ownerMovie(db)));
  });

  test('deve negar a escrita sem login', async () => {
    const db = testEnv.unauthenticatedContext().firestore();

    await assertFails(setDoc(ownerMovie(db), validMovie()));
  });

  test('deve negar a leitura do filme de outro usuário', async () => {
    const db = googleContext(testEnv, OTHER_UID).firestore();

    await assertFails(getDoc(ownerMovie(db)));
  });

  test('deve negar a escrita no filme de outro usuário', async () => {
    const db = googleContext(testEnv, OTHER_UID).firestore();

    await assertFails(setDoc(ownerMovie(db), validMovie()));
  });

  test('deve negar a consulta collectionGroup de movies', async () => {
    await assertFails(getDocs(collectionGroup(ownerDb(), 'movies')));
  });

  async function seedOwnerMovie() {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await setDoc(ownerMovie(context.firestore()), validMovie());
    });
  }

  function ownerMovies(db) {
    return collection(db, 'users', OWNER_UID, 'movies');
  }

  test('deve deixar o dono listar os próprios filmes', async () => {
    await assertSucceeds(getDocs(ownerMovies(ownerDb())));
  });

  test('deve negar a listagem dos filmes de outro usuário', async () => {
    const db = googleContext(testEnv, OTHER_UID).firestore();

    await assertFails(getDocs(ownerMovies(db)));
  });

  test('deve negar a listagem sem login', async () => {
    const db = testEnv.unauthenticatedContext().firestore();

    await assertFails(getDocs(ownerMovies(db)));
  });

  test('deve negar a consulta filtrada nos filmes de outro usuário', async () => {
    const db = googleContext(testEnv, OTHER_UID).firestore();
    const favorites = query(ownerMovies(db), where('favorite', '==', true));

    await assertFails(getDocs(favorites));
  });

  test('deve negar a exclusão do filme de outro usuário', async () => {
    await seedOwnerMovie();
    const db = googleContext(testEnv, OTHER_UID).firestore();

    await assertFails(deleteDoc(ownerMovie(db)));
  });

  test('deve negar a exclusão sem login', async () => {
    await seedOwnerMovie();
    const db = testEnv.unauthenticatedContext().firestore();

    await assertFails(deleteDoc(ownerMovie(db)));
  });

  test('deve negar a atualização do filme de outro usuário', async () => {
    await seedOwnerMovie();
    const db = googleContext(testEnv, OTHER_UID).firestore();

    await assertFails(updateDoc(ownerMovie(db), { favorite: true }));
  });

  test('deve negar a atualização sem login', async () => {
    await seedOwnerMovie();
    const db = testEnv.unauthenticatedContext().firestore();

    await assertFails(updateDoc(ownerMovie(db), { favorite: true }));
  });

  test('deve negar a consulta collectionGroup de movies sem login', async () => {
    const db = testEnv.unauthenticatedContext().firestore();

    await assertFails(getDocs(collectionGroup(db, 'movies')));
  });

  function ownerDbSignedInWith(provider) {
    return testEnv
      .authenticatedContext(OWNER_UID, {
        firebase: { sign_in_provider: provider },
      })
      .firestore();
  }

  test('deve negar a escrita do dono entrando como anônimo', async () => {
    const db = ownerDbSignedInWith('anonymous');

    await assertFails(setDoc(ownerMovie(db), validMovie()));
  });

  test('deve negar a leitura do dono entrando com e-mail e senha', async () => {
    const db = ownerDbSignedInWith('password');

    await assertFails(getDoc(ownerMovie(db)));
  });
});

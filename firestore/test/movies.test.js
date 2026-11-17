import { after, before, beforeEach, describe, test } from 'node:test';
import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import {
  collectionGroup,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  setDoc,
} from 'firebase/firestore';
import {
  MOVIE_ID,
  OTHER_UID,
  OWNER_UID,
  createTestEnvironment,
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
    return testEnv.authenticatedContext(OWNER_UID).firestore();
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
    const db = testEnv.authenticatedContext(OTHER_UID).firestore();

    await assertFails(getDoc(ownerMovie(db)));
  });

  test('deve negar a escrita no filme de outro usuário', async () => {
    const db = testEnv.authenticatedContext(OTHER_UID).firestore();

    await assertFails(setDoc(ownerMovie(db), validMovie()));
  });

  test('deve negar a consulta collectionGroup de movies', async () => {
    await assertFails(getDocs(collectionGroup(ownerDb(), 'movies')));
  });
});

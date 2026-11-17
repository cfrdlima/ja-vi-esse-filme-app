import { after, before, beforeEach, describe, test } from 'node:test';
import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import {
  Timestamp,
  deleteField,
  doc,
  serverTimestamp,
  setDoc,
  updateDoc,
} from 'firebase/firestore';
import {
  MOVIE_ID,
  POSTER_PATH,
  OWNER_UID,
  createTestEnvironment,
  googleContext,
  validMovie,
} from './environment.js';

// As datas são sempre do servidor (decisão 013): uma marca ou o cachedAt
// entram com request.time, ou ficam iguais ao que já estava salvo.
describe('datas do documento do filme', () => {
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

  function movieRef() {
    const db = googleContext(testEnv, OWNER_UID).firestore();
    return doc(db, 'users', OWNER_UID, 'movies', MOVIE_ID);
  }

  const clientTime = Timestamp.fromMillis(0);

  test('deve negar uma marca com data escolhida pelo cliente', async () => {
    const movie = { ...validMovie(), watchedAt: clientTime };

    await assertFails(setDoc(movieRef(), movie));
  });

  test('deve negar um cachedAt escolhido pelo cliente', async () => {
    const movie = { ...validMovie(), cachedAt: clientTime };

    await assertFails(setDoc(movieRef(), movie));
  });

  test('deve negar trocar a data de uma marca salva pela do cliente', async () => {
    await setDoc(movieRef(), validMovie());

    await assertFails(updateDoc(movieRef(), { watchedAt: clientTime }));
  });

  test('deve negar uma marca nova com data do cliente numa atualização', async () => {
    await setDoc(movieRef(), validMovie());

    await assertFails(updateDoc(movieRef(), { favoriteAt: clientTime }));
  });

  test('deve deixar remarcar com a hora do servidor', async () => {
    await setDoc(movieRef(), validMovie());

    await assertSucceeds(
      updateDoc(movieRef(), { watchedAt: serverTimestamp() }),
    );
  });

  test('deve negar mudar o title sem renovar o cachedAt', async () => {
    await setDoc(movieRef(), validMovie());

    await assertFails(updateDoc(movieRef(), { title: 'Outro título' }));
  });

  test('deve negar mudar o posterPath sem renovar o cachedAt', async () => {
    await setDoc(movieRef(), validMovie());

    await assertFails(updateDoc(movieRef(), { posterPath: '/outro.jpg' }));
  });

  test('deve deixar renovar a cópia com o cachedAt do servidor', async () => {
    await setDoc(movieRef(), validMovie());

    await assertSucceeds(
      updateDoc(movieRef(), {
        title: 'Outro título',
        posterPath: '/outro.jpg',
        cachedAt: serverTimestamp(),
      }),
    );
  });

  test('deve deixar mudar uma marca mantendo a cópia e o cachedAt', async () => {
    await setDoc(movieRef(), validMovie());

    await assertSucceeds(
      updateDoc(movieRef(), { watchlistAt: serverTimestamp() }),
    );
  });

  // A escrita exata do markFields (ShelfMovieModel): set com merge, a marca
  // e o cachedAt do servidor, e o posterPath apagado quando não há pôster.
  function markWrite(posterPath) {
    return {
      favoriteAt: serverTimestamp(),
      title: 'Clube da Luta',
      posterPath: posterPath ?? deleteField(),
      cachedAt: serverTimestamp(),
    };
  }

  test('deve aceitar o merge do app que cria o filme sem pôster', async () => {
    await assertSucceeds(setDoc(movieRef(), markWrite(), { merge: true }));
  });

  test('deve aceitar o merge do app que cria o filme com pôster', async () => {
    await assertSucceeds(
      setDoc(movieRef(), markWrite(POSTER_PATH), { merge: true }),
    );
  });

  test('deve aceitar o merge do app que apaga o pôster salvo', async () => {
    await setDoc(movieRef(), validMovie());

    await assertSucceeds(setDoc(movieRef(), markWrite(), { merge: true }));
  });

  test('deve negar apagar o posterPath sem renovar o cachedAt', async () => {
    await setDoc(movieRef(), validMovie());

    await assertFails(updateDoc(movieRef(), { posterPath: deleteField() }));
  });
});

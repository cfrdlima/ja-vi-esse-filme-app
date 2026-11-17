import { after, before, beforeEach, describe, test } from 'node:test';
import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import {
  deleteField,
  doc,
  serverTimestamp,
  setDoc,
  updateDoc,
} from 'firebase/firestore';
import {
  MOVIE_ID,
  OWNER_UID,
  createTestEnvironment,
  googleContext,
  validMovie,
} from './environment.js';

// Formato do documento da decisão 013.
describe('validação do documento do filme', () => {
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

  function movieRef(movieId) {
    const db = googleContext(testEnv, OWNER_UID).firestore();
    return doc(db, 'users', OWNER_UID, 'movies', movieId);
  }

  function without(movie, key) {
    const { [key]: _, ...rest } = movie;
    return rest;
  }

  test('deve negar um movieId que não é número', async () => {
    await assertFails(setDoc(movieRef('abc'), validMovie()));
  });

  test('deve negar um movieId com zero à esquerda', async () => {
    await assertFails(setDoc(movieRef('0550'), validMovie()));
  });

  test('deve negar um movieId com mais de 10 dígitos', async () => {
    await assertFails(setDoc(movieRef('12345678901'), validMovie()));
  });

  test('deve aceitar um filme com uma marca e a cópia do TMDB', async () => {
    await assertSucceeds(setDoc(movieRef(MOVIE_ID), validMovie()));
  });

  test('deve aceitar um filme com as três marcas', async () => {
    const movie = {
      ...validMovie(),
      watchlistAt: serverTimestamp(),
      favoriteAt: serverTimestamp(),
    };

    await assertSucceeds(setDoc(movieRef(MOVIE_ID), movie));
  });

  test('deve aceitar um filme sem posterPath', async () => {
    const movie = without(validMovie(), 'posterPath');

    await assertSucceeds(setDoc(movieRef(MOVIE_ID), movie));
  });

  test('deve negar um filme sem nenhuma marca', async () => {
    const movie = without(validMovie(), 'watchedAt');

    await assertFails(setDoc(movieRef(MOVIE_ID), movie));
  });

  test('deve negar o formato antigo com bools', async () => {
    const movie = { watched: true, watchlist: false, favorite: false };

    await assertFails(setDoc(movieRef(MOVIE_ID), movie));
  });

  test('deve negar uma chave fora da lista permitida', async () => {
    const movie = { ...validMovie(), extra: 'x' };

    await assertFails(setDoc(movieRef(MOVIE_ID), movie));
  });

  test('deve negar um filme sem title', async () => {
    const movie = without(validMovie(), 'title');

    await assertFails(setDoc(movieRef(MOVIE_ID), movie));
  });

  test('deve negar um filme sem cachedAt', async () => {
    const movie = without(validMovie(), 'cachedAt');

    await assertFails(setDoc(movieRef(MOVIE_ID), movie));
  });

  test('deve negar title que não é texto', async () => {
    const movie = { ...validMovie(), title: 42 };

    await assertFails(setDoc(movieRef(MOVIE_ID), movie));
  });

  test('deve negar posterPath que não é texto', async () => {
    const movie = { ...validMovie(), posterPath: null };

    await assertFails(setDoc(movieRef(MOVIE_ID), movie));
  });

  test('deve negar watchedAt que não é data', async () => {
    const movie = { ...validMovie(), watchedAt: true };

    await assertFails(setDoc(movieRef(MOVIE_ID), movie));
  });

  test('deve negar cachedAt que não é data', async () => {
    const movie = { ...validMovie(), cachedAt: 'x'.repeat(100000) };

    await assertFails(setDoc(movieRef(MOVIE_ID), movie));
  });

  test('deve deixar acrescentar uma marca', async () => {
    await setDoc(movieRef(MOVIE_ID), validMovie());

    await assertSucceeds(
      updateDoc(movieRef(MOVIE_ID), { favoriteAt: serverTimestamp() }),
    );
  });

  test('deve deixar tirar uma marca quando sobra outra', async () => {
    const movie = { ...validMovie(), favoriteAt: serverTimestamp() };
    await setDoc(movieRef(MOVIE_ID), movie);

    await assertSucceeds(
      updateDoc(movieRef(MOVIE_ID), { favoriteAt: deleteField() }),
    );
  });

  test('deve negar tirar a última marca, que apaga o documento', async () => {
    await setDoc(movieRef(MOVIE_ID), validMovie());

    await assertFails(
      updateDoc(movieRef(MOVIE_ID), { watchedAt: deleteField() }),
    );
  });

  test('deve negar uma atualização que acrescenta chave fora da lista', async () => {
    await setDoc(movieRef(MOVIE_ID), validMovie());

    await assertFails(updateDoc(movieRef(MOVIE_ID), { extra: 'x' }));
  });

  test('deve negar uma atualização que remove o title', async () => {
    await setDoc(movieRef(MOVIE_ID), validMovie());

    await assertFails(updateDoc(movieRef(MOVIE_ID), { title: deleteField() }));
  });

  test('deve negar uma atualização com tipo errado', async () => {
    await setDoc(movieRef(MOVIE_ID), validMovie());

    await assertFails(updateDoc(movieRef(MOVIE_ID), { favoriteAt: 'x' }));
  });
});

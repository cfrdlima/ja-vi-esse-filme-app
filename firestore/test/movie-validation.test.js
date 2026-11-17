import { after, before, beforeEach, describe, test } from 'node:test';
import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { deleteField, doc, setDoc, updateDoc } from 'firebase/firestore';
import {
  MOVIE_ID,
  OWNER_UID,
  createTestEnvironment,
  googleContext,
  validMovie,
} from './environment.js';

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

  test('deve negar um movieId que não é número', async () => {
    await assertFails(setDoc(movieRef('abc'), validMovie()));
  });

  test('deve negar um movieId com zero à esquerda', async () => {
    await assertFails(setDoc(movieRef('0550'), validMovie()));
  });

  test('deve negar um movieId com mais de 10 dígitos', async () => {
    await assertFails(setDoc(movieRef('12345678901'), validMovie()));
  });

  test('deve negar uma chave fora da lista permitida', async () => {
    const movie = { ...validMovie(), extra: 'x' };

    await assertFails(setDoc(movieRef(MOVIE_ID), movie));
  });

  test('deve negar um documento sem uma das chaves obrigatórias', async () => {
    const { favorite: _, ...movie } = validMovie();

    await assertFails(setDoc(movieRef(MOVIE_ID), movie));
  });

  test('deve negar watched que não é booleano', async () => {
    const movie = { ...validMovie(), watched: 'x'.repeat(100000) };

    await assertFails(setDoc(movieRef(MOVIE_ID), movie));
  });

  test('deve negar watchlist que não é booleano', async () => {
    const movie = { ...validMovie(), watchlist: 1 };

    await assertFails(setDoc(movieRef(MOVIE_ID), movie));
  });

  test('deve negar favorite que não é booleano', async () => {
    const movie = { ...validMovie(), favorite: null };

    await assertFails(setDoc(movieRef(MOVIE_ID), movie));
  });

  test('deve negar uma atualização que acrescenta chave fora da lista', async () => {
    await setDoc(movieRef(MOVIE_ID), validMovie());

    await assertFails(updateDoc(movieRef(MOVIE_ID), { extra: 'x' }));
  });

  test('deve negar uma atualização que remove uma chave obrigatória', async () => {
    await setDoc(movieRef(MOVIE_ID), validMovie());

    await assertFails(
      updateDoc(movieRef(MOVIE_ID), { favorite: deleteField() }),
    );
  });

  test('deve negar uma atualização com tipo errado', async () => {
    await setDoc(movieRef(MOVIE_ID), validMovie());

    await assertFails(updateDoc(movieRef(MOVIE_ID), { favorite: 'x' }));
  });

  test('deve deixar atualizar um campo permitido', async () => {
    await setDoc(movieRef(MOVIE_ID), validMovie());

    await assertSucceeds(updateDoc(movieRef(MOVIE_ID), { favorite: true }));
  });
});

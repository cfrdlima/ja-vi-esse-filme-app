import { after, before, beforeEach, describe, test } from 'node:test';
import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import {
  Timestamp,
  deleteDoc,
  deleteField,
  doc,
  serverTimestamp,
  setDoc,
  updateDoc,
} from 'firebase/firestore';
import {
  LIST_ID,
  MOVIE_ID,
  OTHER_LIST_ID,
  OWNER_UID,
  createTestEnvironment,
  googleContext,
  listIdAt,
  validMovie,
} from './environment.js';

// Filme numa lista: o mapa lists de listId para a hora do servidor em que
// entrou, no documento do filme (decisão 019).
describe('mapa lists no documento do filme', () => {
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

  function movieRef(db = googleContext(testEnv, OWNER_UID).firestore()) {
    return doc(db, 'users', OWNER_UID, 'movies', MOVIE_ID);
  }

  // Só a cópia do TMDB, sem marca nenhuma.
  function copyOnly() {
    const { watchedAt: _, ...movie } = validMovie();
    return movie;
  }

  // Grava sem as regras, com as horas já resolvidas (Timestamp fixo).
  async function seed(movie) {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await setDoc(movieRef(context.firestore()), movie);
    });
  }

  function seededCopy() {
    return {
      title: 'Clube da Luta',
      cachedAt: Timestamp.fromMillis(1_700_000_000_000),
    };
  }

  const ADDED = Timestamp.fromMillis(1_700_000_100_000);

  test('deve aceitar o filme só numa lista, sem marca', async () => {
    await assertSucceeds(setDoc(movieRef(), { ...copyOnly(), lists: { [LIST_ID]: serverTimestamp() } }));
  });

  test('deve aceitar o filme marcado e numa lista', async () => {
    await assertSucceeds(setDoc(movieRef(), { ...validMovie(), lists: { [LIST_ID]: serverTimestamp() } }));
  });

  test('deve negar o filme sem marca e sem lista', async () => {
    await assertFails(setDoc(movieRef(), copyOnly()));
  });

  test('deve negar o mapa de listas vazio', async () => {
    await assertFails(setDoc(movieRef(), { ...validMovie(), lists: {} }));
  });

  test('deve negar lists que não é mapa', async () => {
    await assertFails(setDoc(movieRef(), { ...validMovie(), lists: [LIST_ID] }));
  });

  test('deve negar a hora escolhida pelo cliente', async () => {
    await assertFails(setDoc(movieRef(), { ...copyOnly(), lists: { [LIST_ID]: Timestamp.now() } }));
  });

  test('deve negar o valor que não é data', async () => {
    await assertFails(setDoc(movieRef(), { ...copyOnly(), lists: { [LIST_ID]: true } }));
  });

  for (const listId of ['curta', 'Lst0aBcDeFgHiJkLmNoPQ', 'Lst0aBcDeFgHiJk-mNoP', 'Lst0aBcDeFgHiJk,mNoP']) {
    test(`deve negar a chave ${JSON.stringify(listId)}`, async () => {
      await assertFails(setDoc(movieRef(), { ...copyOnly(), lists: { [listId]: serverTimestamp() } }));
    });
  }

  test('deve negar duas listas novas na mesma escrita', async () => {
    await assertFails(setDoc(movieRef(), {
      ...copyOnly(),
      lists: { [LIST_ID]: serverTimestamp(), [OTHER_LIST_ID]: serverTimestamp() },
    }));
  });

  test('deve deixar pôr o filme em mais uma lista', async () => {
    await seed({ ...seededCopy(), lists: { [LIST_ID]: ADDED } });

    await assertSucceeds(updateDoc(movieRef(), { [`lists.${OTHER_LIST_ID}`]: serverTimestamp() }));
  });

  test('deve negar mais uma lista com a hora do cliente', async () => {
    await seed({ ...seededCopy(), lists: { [LIST_ID]: ADDED } });

    await assertFails(updateDoc(movieRef(), { [`lists.${OTHER_LIST_ID}`]: Timestamp.now() }));
  });

  test('deve negar mudar a hora de uma lista que já tem o filme', async () => {
    await seed({ ...seededCopy(), lists: { [LIST_ID]: ADDED } });

    await assertFails(updateDoc(movieRef(), { [`lists.${LIST_ID}`]: serverTimestamp() }));
  });

  test('deve negar trocar uma lista por outra na mesma escrita', async () => {
    await seed({ ...seededCopy(), lists: { [LIST_ID]: ADDED } });

    await assertFails(updateDoc(movieRef(), {
      [`lists.${LIST_ID}`]: deleteField(),
      [`lists.${OTHER_LIST_ID}`]: serverTimestamp(),
    }));
  });

  test('deve deixar tirar o filme de uma lista', async () => {
    await seed({ ...seededCopy(), lists: { [LIST_ID]: ADDED, [OTHER_LIST_ID]: ADDED } });

    await assertSucceeds(updateDoc(movieRef(), { [`lists.${LIST_ID}`]: deleteField() }));
  });

  test('deve deixar tirar da última lista o filme marcado', async () => {
    await seed({ ...seededCopy(), watchedAt: ADDED, lists: { [LIST_ID]: ADDED } });

    await assertSucceeds(updateDoc(movieRef(), { lists: deleteField() }));
  });

  test('deve negar tirar da última lista o filme sem marca sem apagar', async () => {
    await seed({ ...seededCopy(), lists: { [LIST_ID]: ADDED } });

    await assertFails(updateDoc(movieRef(), { lists: deleteField() }));
  });

  test('deve deixar apagar o filme que só estava numa lista', async () => {
    await seed({ ...seededCopy(), lists: { [LIST_ID]: ADDED } });

    await assertSucceeds(deleteDoc(movieRef()));
  });

  test('deve deixar tirar a última marca do filme que está numa lista', async () => {
    await seed({ ...seededCopy(), watchedAt: ADDED, rating: 8, lists: { [LIST_ID]: ADDED } });

    await assertSucceeds(updateDoc(movieRef(), { watchedAt: deleteField(), rating: deleteField() }));
  });

  test('deve negar a nota no filme só numa lista', async () => {
    await seed({ ...seededCopy(), lists: { [LIST_ID]: ADDED } });

    await assertFails(updateDoc(movieRef(), { rating: 8 }));
  });

  test('deve deixar marcar sem mexer nas listas', async () => {
    await seed({ ...seededCopy(), lists: { [LIST_ID]: ADDED } });

    await assertSucceeds(updateDoc(movieRef(), { favoriteAt: serverTimestamp() }));
  });

  test('deve deixar pôr o filme na quinquagésima lista', async () => {
    const lists = Object.fromEntries(Array.from({ length: 49 }, (_, i) => [listIdAt(i), ADDED]));
    await seed({ ...seededCopy(), lists });

    await assertSucceeds(updateDoc(movieRef(), { [`lists.${listIdAt(49)}`]: serverTimestamp() }));
  });

  test('deve negar a quinquagésima primeira lista', async () => {
    const lists = Object.fromEntries(Array.from({ length: 50 }, (_, i) => [listIdAt(i), ADDED]));
    await seed({ ...seededCopy(), lists });

    await assertFails(updateDoc(movieRef(), { [`lists.${listIdAt(50)}`]: serverTimestamp() }));
  });

  test('deve negar a escrita que mantém uma chave inválida já salva', async () => {
    await seed({ ...seededCopy(), lists: { curta: ADDED } });

    await assertFails(updateDoc(movieRef(), { favoriteAt: serverTimestamp() }));
  });
});

import { after, before, beforeEach, describe, test } from 'node:test';
import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import {
  collection,
  collectionGroup,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  setDoc,
  updateDoc,
} from 'firebase/firestore';
import {
  LIST_ID,
  OTHER_UID,
  OWNER_UID,
  createTestEnvironment,
  googleContext,
} from './environment.js';

// Lista personalizada: só o nome, de 1 a 50 caracteres (decisão 019).
describe('users/{uid}/lists/{listId}', () => {
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

  function listRef(db, listId = LIST_ID, uid = OWNER_UID) {
    return doc(db, 'users', uid, 'lists', listId);
  }

  async function seedList() {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await setDoc(listRef(context.firestore()), { name: 'Terror' });
    });
  }

  test('deve deixar o dono criar uma lista', async () => {
    await assertSucceeds(setDoc(listRef(ownerDb()), { name: 'Terror' }));
  });

  test('deve deixar o dono ler a própria lista', async () => {
    await seedList();

    await assertSucceeds(getDoc(listRef(ownerDb())));
  });

  test('deve deixar o dono consultar as próprias listas', async () => {
    await seedList();

    await assertSucceeds(getDocs(collection(ownerDb(), 'users', OWNER_UID, 'lists')));
  });

  test('deve deixar o dono renomear a lista', async () => {
    await seedList();

    await assertSucceeds(updateDoc(listRef(ownerDb()), { name: 'Suspense' }));
  });

  test('deve deixar o dono apagar a lista', async () => {
    await seedList();

    await assertSucceeds(deleteDoc(listRef(ownerDb())));
  });

  test('deve negar a leitura da lista de outro usuário', async () => {
    await seedList();
    const db = googleContext(testEnv, OTHER_UID).firestore();

    await assertFails(getDoc(listRef(db)));
  });

  test('deve negar a criação na conta de outro usuário', async () => {
    const db = googleContext(testEnv, OTHER_UID).firestore();

    await assertFails(setDoc(listRef(db), { name: 'Terror' }));
  });

  test('deve negar a leitura sem login', async () => {
    await seedList();
    const db = testEnv.unauthenticatedContext().firestore();

    await assertFails(getDoc(listRef(db)));
  });

  test('deve negar a criação com outro provedor', async () => {
    const db = testEnv
      .authenticatedContext(OWNER_UID, { firebase: { sign_in_provider: 'anonymous' } })
      .firestore();

    await assertFails(setDoc(listRef(db), { name: 'Terror' }));
  });

  test('deve negar a consulta collectionGroup de lists', async () => {
    await assertFails(getDocs(collectionGroup(ownerDb(), 'lists')));
  });

  for (const listId of [
    'Lst0aBcDeFgHiJkLmNo',
    'Lst0aBcDeFgHiJkLmNoPQ',
    'Lst0aBcDeFgHiJk-mNoP',
    'Lst0aBcDeFgHiJk_mNoP',
    'Lst0aBcDeFgHiJk mNoP',
  ]) {
    test(`deve negar a lista com o id ${JSON.stringify(listId)}`, async () => {
      await assertFails(setDoc(listRef(ownerDb(), listId), { name: 'Terror' }));
    });
  }

  // As regras contam unidades UTF-16, como o length do Dart: um emoji
  // fora do plano básico conta 2 (conferido no emulador na sessão 029).
  for (const name of ['A', 'a'.repeat(50), 'Filmes de 2026 ✨', '😀'.repeat(25)]) {
    test(`deve aceitar o nome ${JSON.stringify(name)}`, async () => {
      await assertSucceeds(setDoc(listRef(ownerDb()), { name }));
    });
  }

  for (const name of ['', '   ', 'a'.repeat(51), '😀'.repeat(26), 'Ter\nror', 'Ter\tror', 'Ter\u0000ror', 7, null]) {
    test(`deve negar o nome ${JSON.stringify(name)}`, async () => {
      await assertFails(setDoc(listRef(ownerDb()), { name }));
    });
  }

  test('deve negar a lista sem o nome', async () => {
    await assertFails(setDoc(listRef(ownerDb()), {}));
  });

  test('deve negar a lista com uma chave a mais', async () => {
    await assertFails(setDoc(listRef(ownerDb()), { name: 'Terror', color: 'red' }));
  });

  test('deve negar o rename para um nome inválido', async () => {
    await seedList();

    await assertFails(updateDoc(listRef(ownerDb()), { name: ' ' }));
  });

  test('deve negar a escrita abaixo do documento da lista', async () => {
    const nested = doc(ownerDb(), 'users', OWNER_UID, 'lists', LIST_ID, 'items', '550');

    await assertFails(setDoc(nested, { a: 1 }));
  });
});

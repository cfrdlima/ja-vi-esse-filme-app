import assert from 'node:assert/strict';
import { after, before, beforeEach, describe, test } from 'node:test';
import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import {
  collection,
  doc,
  getDocs,
  limit,
  query,
  setDoc,
  writeBatch,
} from 'firebase/firestore';
import {
  OTHER_UID,
  OWNER_UID,
  collectionsInApp,
  createTestEnvironment,
  googleContext,
  validMovie,
} from './environment.js';

// O mesmo laço do FirestoreAccountDocuments (decisão 015): lê um lote,
// apaga num WriteBatch e repete até a leitura voltar vazia. O lote aqui é
// pequeno para o laço dar mais de uma volta.
async function deleteAccountDocuments(db, uid, batchLimit = 2) {
  for (const name of collectionsInApp()) {
    const documents = collection(db, 'users', uid, name);
    while (true) {
      const snapshot = await getDocs(query(documents, limit(batchLimit)));
      if (snapshot.empty) break;
      const batch = writeBatch(db);
      snapshot.docs.forEach((document) => batch.delete(document.ref));
      await batch.commit();
    }
  }
}

describe('exclusão dos documentos da conta', () => {
  let testEnv;

  before(async () => {
    testEnv = await createTestEnvironment();
  });

  beforeEach(async () => {
    await testEnv.clearFirestore();
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      for (const id of ['550', '551', '552', '553', '554']) {
        await setDoc(doc(db, 'users', OWNER_UID, 'movies', id), validMovie());
      }
      await setDoc(doc(db, 'users', OTHER_UID, 'movies', '550'), validMovie());
    });
  });

  after(async () => {
    await testEnv.cleanup();
  });

  // Conta com as regras desligadas, para enxergar tudo o que sobrou.
  async function remainingIn(uid) {
    let count = 0;
    await testEnv.withSecurityRulesDisabled(async (context) => {
      for (const name of collectionsInApp()) {
        const snapshot = await getDocs(
          collection(context.firestore(), 'users', uid, name),
        );
        count += snapshot.size;
      }
    });
    return count;
  }

  test('deve deixar o dono apagar todos os documentos dele', async () => {
    const db = googleContext(testEnv, OWNER_UID).firestore();

    await assertSucceeds(deleteAccountDocuments(db, OWNER_UID));
  });

  test('não deve sobrar nenhum documento em users/{uid}', async () => {
    const db = googleContext(testEnv, OWNER_UID).firestore();

    await deleteAccountDocuments(db, OWNER_UID);

    assert.equal(await remainingIn(OWNER_UID), 0);
  });

  test('não deve apagar os documentos de outro usuário', async () => {
    const db = googleContext(testEnv, OWNER_UID).firestore();

    await deleteAccountDocuments(db, OWNER_UID);

    assert.equal(await remainingIn(OTHER_UID), 1);
  });

  test('deve negar a outro usuário apagar os documentos do dono', async () => {
    const db = googleContext(testEnv, OTHER_UID).firestore();

    await assertFails(deleteAccountDocuments(db, OWNER_UID));
  });

  test('deve negar a exclusão sem login', async () => {
    const db = testEnv.unauthenticatedContext().firestore();

    await assertFails(deleteAccountDocuments(db, OWNER_UID));
  });

  // O lote é atômico: o documento alheio no meio derruba o lote inteiro.
  test('deve negar um lote com um documento de outro usuário', async () => {
    const db = googleContext(testEnv, OWNER_UID).firestore();
    const batch = writeBatch(db);
    batch.delete(doc(db, 'users', OWNER_UID, 'movies', '550'));
    batch.delete(doc(db, 'users', OTHER_UID, 'movies', '550'));

    await assertFails(batch.commit());
  });
});

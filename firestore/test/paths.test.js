import { after, before, describe, test } from 'node:test';
import { assertFails } from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc } from 'firebase/firestore';
import {
  OWNER_UID,
  createTestEnvironment,
  googleContext,
} from './environment.js';

describe('caminhos fora de users/{uid}/movies', () => {
  let testEnv;

  before(async () => {
    testEnv = await createTestEnvironment();
  });

  after(async () => {
    await testEnv.cleanup();
  });

  function ownerDb() {
    return googleContext(testEnv, OWNER_UID).firestore();
  }

  test('deve negar a escrita numa coleção da raiz', async () => {
    await assertFails(setDoc(doc(ownerDb(), 'anything', 'doc'), { a: 1 }));
  });

  test('deve negar a escrita no documento users/{uid}', async () => {
    await assertFails(setDoc(doc(ownerDb(), 'users', OWNER_UID), { a: 1 }));
  });

  test('deve negar a leitura do documento users/{uid}', async () => {
    await assertFails(getDoc(doc(ownerDb(), 'users', OWNER_UID)));
  });

  test('deve negar a escrita numa subcoleção não listada do dono', async () => {
    const other = doc(ownerDb(), 'users', OWNER_UID, 'secrets', 'doc');

    await assertFails(setDoc(other, { a: 1 }));
  });

  test('deve negar a escrita abaixo do documento do filme', async () => {
    const nested = doc(
      ownerDb(), 'users', OWNER_UID, 'movies', '550', 'extra', 'doc',
    );

    await assertFails(setDoc(nested, { a: 1 }));
  });

  test('deve negar a leitura numa subcoleção não listada do dono', async () => {
    const other = doc(ownerDb(), 'users', OWNER_UID, 'secrets', 'doc');

    await assertFails(getDoc(other));
  });
});

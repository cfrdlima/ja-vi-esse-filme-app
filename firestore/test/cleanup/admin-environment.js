import { randomUUID } from 'node:crypto';
import { deleteApp, initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';

// O mesmo projeto demo- dos testes das regras: o emulador nunca fala com o
// projeto real (decisão 012). O `emulators:exec` exporta o
// FIRESTORE_EMULATOR_HOST e o FIREBASE_AUTH_EMULATOR_HOST, que o Admin SDK
// usa no lugar do Google.
export const PROJECT_ID = 'demo-ja-vi-esse-filme';

export function requireEmulators() {
  for (const name of ['FIRESTORE_EMULATOR_HOST', 'FIREBASE_AUTH_EMULATOR_HOST']) {
    if (!process.env[name]) throw new Error(`${name} ausente: rode com npm test`);
  }
}

export function createAdmin() {
  requireEmulators();
  const app = initializeApp({ projectId: PROJECT_ID }, randomUUID());
  return {
    auth: getAuth(app),
    db: getFirestore(app),
    close: () => deleteApp(app),
  };
}

// Endpoints de limpeza dos emuladores, para cada teste começar do zero.
export async function clearEmulators() {
  requireEmulators();
  const firestore = process.env.FIRESTORE_EMULATOR_HOST;
  const auth = process.env.FIREBASE_AUTH_EMULATOR_HOST;
  await Promise.all([
    fetch(`http://${firestore}/emulator/v1/projects/${PROJECT_ID}/databases/(default)/documents`, { method: 'DELETE' }),
    fetch(`http://${auth}/emulator/v1/projects/${PROJECT_ID}/accounts`, { method: 'DELETE' }),
  ]);
}

export async function createAccount(auth, uid) {
  await auth.createUser({ uid });
}

export async function movieIds(db, uid) {
  const snapshot = await db.collection(`users/${uid}/movies`).get();
  return snapshot.docs.map((doc) => doc.id).sort();
}

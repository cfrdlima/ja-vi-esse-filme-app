import { readFileSync } from 'node:fs';
import { initializeTestEnvironment } from '@firebase/rules-unit-testing';

export const RULES_PATH = new URL('../../firestore.rules', import.meta.url);

// O prefixo demo- impede o emulador de falar com o projeto real (decisão 012).
export function createTestEnvironment() {
  return initializeTestEnvironment({
    projectId: 'demo-ja-vi-esse-filme',
    firestore: { rules: readFileSync(RULES_PATH, 'utf8') },
  });
}

export const OWNER_UID = 'alice';
export const OTHER_UID = 'bob';
export const MOVIE_ID = '550';

export function validMovie() {
  return { watched: true, watchlist: false, favorite: false };
}

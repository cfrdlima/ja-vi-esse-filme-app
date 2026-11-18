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
  OWNER_UID,
  createTestEnvironment,
  googleContext,
  validMovie,
} from './environment.js';

// Nota de meia em meia estrela (rating, 1 a 10) e dia em que assistiu
// (watchedOn, AAAA-MM-DD), só com a marca Assistido (decisão 018).
describe('nota e dia em que assistiu', () => {
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

  // Só na lista de quero assistir, sem o watchedAt.
  function unwatchedMovie() {
    const { watchedAt: _, ...movie } = validMovie();
    return { ...movie, watchlistAt: serverTimestamp() };
  }

  for (const rating of [1, 10]) {
    test(`deve aceitar a nota ${rating}`, async () => {
      await assertSucceeds(setDoc(movieRef(), { ...validMovie(), rating }));
    });
  }

  for (const rating of [0, 11, -1, 3.5, '7', null]) {
    test(`deve negar a nota ${JSON.stringify(rating)}`, async () => {
      await assertFails(setDoc(movieRef(), { ...validMovie(), rating }));
    });
  }

  // 2026-02-29 não existe: as regras conferem só o formato e os intervalos,
  // e o domínio recusa o dia fora do calendário e o futuro (decisão 018).
  for (const watchedOn of ['1888-01-01', '2026-11-18', '2026-02-29', '1999-12-31']) {
    test(`deve aceitar o dia ${watchedOn}`, async () => {
      await assertSucceeds(setDoc(movieRef(), { ...validMovie(), watchedOn }));
    });
  }

  for (const watchedOn of [
    '1887-12-31',
    '2026-13-01',
    '2026-00-10',
    '2026-11-32',
    '2026-11-00',
    '2026-1-18',
    '18/11/2026',
    '2026-11-18T10:00:00Z',
    ' 2026-11-18',
    '',
    20261118,
    null,
  ]) {
    test(`deve negar o dia ${JSON.stringify(watchedOn)}`, async () => {
      await assertFails(setDoc(movieRef(), { ...validMovie(), watchedOn }));
    });
  }

  test('deve negar a nota sem a marca Assistido', async () => {
    await assertFails(setDoc(movieRef(), { ...unwatchedMovie(), rating: 7 }));
  });

  test('deve negar o dia sem a marca Assistido', async () => {
    await assertFails(
      setDoc(movieRef(), { ...unwatchedMovie(), watchedOn: '2026-11-18' }),
    );
  });

  // O caminho do app: o update só da nota num filme que já existe.
  test('deve negar dar a nota a um filme só na lista de quero assistir', async () => {
    await setDoc(movieRef(), unwatchedMovie());

    await assertFails(updateDoc(movieRef(), { rating: 7 }));
  });

  // A nota não recria o filme que saiu da Estante (decisão 018).
  test('deve negar a nota com merge num filme que não existe', async () => {
    await assertFails(setDoc(movieRef(), { rating: 9 }, { merge: true }));
  });

  test('deve negar a nota junto com um watchedAt escolhido pelo cliente', async () => {
    await setDoc(movieRef(), validMovie());

    await assertFails(
      updateDoc(movieRef(), {
        rating: 9,
        watchedAt: Timestamp.fromDate(new Date('2020-01-01T00:00:00Z')),
      }),
    );
  });

  test('deve deixar dar a nota sem mexer na cópia nem nas marcas', async () => {
    await setDoc(movieRef(), validMovie());

    await assertSucceeds(updateDoc(movieRef(), { rating: 9 }));
  });

  test('deve deixar escolher o dia sem mexer na cópia nem nas marcas', async () => {
    await setDoc(movieRef(), validMovie());

    await assertSucceeds(updateDoc(movieRef(), { watchedOn: '2026-11-17' }));
  });

  test('deve deixar tirar a nota', async () => {
    await setDoc(movieRef(), { ...validMovie(), rating: 9 });

    await assertSucceeds(updateDoc(movieRef(), { rating: deleteField() }));
  });

  test('deve negar tirar o Assistido e manter a nota', async () => {
    await setDoc(movieRef(), {
      ...validMovie(),
      favoriteAt: serverTimestamp(),
      rating: 9,
    });

    await assertFails(updateDoc(movieRef(), { watchedAt: deleteField() }));
  });

  test('deve deixar tirar o Assistido junto com a nota e o dia', async () => {
    await setDoc(movieRef(), {
      ...validMovie(),
      favoriteAt: serverTimestamp(),
      rating: 9,
      watchedOn: '2026-11-17',
    });

    await assertSucceeds(
      updateDoc(movieRef(), {
        watchedAt: deleteField(),
        rating: deleteField(),
        watchedOn: deleteField(),
      }),
    );
  });
});

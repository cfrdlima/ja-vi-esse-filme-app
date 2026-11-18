import { after, beforeEach, describe, test } from 'node:test';
import assert from 'node:assert/strict';
import { Timestamp } from 'firebase-admin/firestore';
import { UsageError, formatReport, parseArgs, runCleanup } from '../../cleanup/cleanup.js';
import { clearEmulators, createAccount, createAdmin, movieIds } from './admin-environment.js';

const TOKEN = 'token-de-teste';
const ENV = { TMDB_READ_TOKEN: TOKEN };

describe('argumentos da limpeza mensal', () => {
  test('deve exigir o projeto explícito', () => {
    assert.throws(() => parseArgs([], ENV), UsageError);
  });

  test('deve ler o projeto e o token do TMDB do ambiente', () => {
    const options = parseArgs(['--project', 'meu-projeto'], ENV);

    assert.deepEqual(options, {
      projectId: 'meu-projeto',
      dryRun: false,
      tmdbToken: TOKEN,
      confirmOrphans: null,
    });
  });

  test('deve exigir o token do TMDB fora da simulação', () => {
    assert.throws(() => parseArgs(['--project', 'meu-projeto'], {}), UsageError);
  });

  test('na simulação, não deve exigir o token do TMDB', () => {
    const options = parseArgs(['--project', 'meu-projeto', '--dry-run'], {});

    assert.equal(options.tmdbToken, null);
  });

  test('deve recusar argumento desconhecido', () => {
    assert.throws(() => parseArgs(['--project', 'meu-projeto', '--force'], ENV), UsageError);
  });

  test('deve recusar --project sem o nome do projeto', () => {
    assert.throws(() => parseArgs(['--project', '--dry-run'], {}), UsageError);
  });

  // Um emulador do Auth ligado com o Firestore real faria todo mundo parecer
  // sem conta (`/revisar` da sessão 027).
  for (const name of ['FIRESTORE_EMULATOR_HOST', 'FIREBASE_AUTH_EMULATOR_HOST', 'FIREBASE_EMULATOR_HUB']) {
    test(`deve recusar rodar com ${name} no ambiente`, () => {
      assert.throws(
        () => parseArgs(['--project', 'meu-projeto'], { ...ENV, [name]: '127.0.0.1:9099' }),
        UsageError,
      );
    });
  }

  test('deve recusar projeto demo-, que é só dos emuladores', () => {
    assert.throws(() => parseArgs(['--project', 'demo-ja-vi-esse-filme', '--dry-run'], {}), UsageError);
  });

  test('deve ler a confirmação dos dados sem conta', () => {
    const options = parseArgs(['--project', 'meu-projeto', '--confirm-orphans', '12'], ENV);

    assert.equal(options.confirmOrphans, 12);
  });

  test('deve recusar confirmação que não é um número inteiro positivo', () => {
    assert.throws(
      () => parseArgs(['--project', 'meu-projeto', '--confirm-orphans', 'todos'], ENV),
      UsageError,
    );
  });
});

describe('relatório da limpeza mensal', () => {
  const copies = {
    expired: 6, renewed: 3, removed: 1, failed: 1, noTitle: 1, skipped: 0, stopped: null,
  };
  const report = { projectId: 'meu-projeto', dryRun: false, orphanUsers: 2, needsConfirmation: false, copies };

  test('deve mostrar só as contagens e o projeto', () => {
    assert.equal(formatReport(report), [
      'Limpeza mensal do Firestore — projeto meu-projeto',
      'Dados sem conta apagados: 2 users/{uid}',
      'Cópias vencidas: 6 (renovadas: 3, filmes apagados: 1, falhas: 1, sem título no TMDB: 1, puladas: 0)',
    ].join('\n'));
  });

  test('na simulação, deve dizer que os dados sem conta foram só encontrados', () => {
    assert.match(formatReport({ ...report, dryRun: true }), /Dados sem conta encontrados: 2/);
  });

  test('deve avisar que a simulação não gravou nada', () => {
    assert.match(formatReport({ ...report, dryRun: true }), /simulação: nada foi gravado/);
  });

  test('na simulação, deve dizer como confirmar os dados sem conta acima do limite', () => {
    const above = { ...report, dryRun: true, needsConfirmation: true };

    assert.match(formatReport(above), /--confirm-orphans 2/);
  });

  for (const [stopped, text] of [
    ['rate-limit', /limite de requisições do TMDB/],
    ['unauthorized', /recusou o token/],
    ['not-found-streak', /404 seguidos/],
    ['quota', /cota do Firestore/],
    ['write-limit', /teto de escritas/],
  ]) {
    test(`deve explicar a parada ${stopped}`, () => {
      assert.match(formatReport({ ...report, copies: { ...copies, stopped } }), text);
    });
  }

  test('deve dizer quando a etapa das cópias não terminou', () => {
    assert.match(formatReport({ ...report, copies: null }), /Cópias vencidas: a etapa não terminou/);
  });
});

describe('limpeza mensal completa', () => {
  const admin = createAdmin();
  const { auth, db } = admin;
  const OLD = Timestamp.fromDate(new Date('2020-01-01'));

  beforeEach(async () => {
    await clearEmulators();
    await createAccount(auth, 'alice');
  });
  after(() => admin.close());

  function addMovie(path, cachedAt = OLD) {
    return db.doc(path).set({ title: 'Antigo', cachedAt, watchedAt: Timestamp.now() });
  }

  test('deve apagar os dados sem conta antes de renovar cópias', async () => {
    await addMovie('users/sem-conta/movies/550');
    const requested = [];
    const source = { fetchCopy: async (id) => requested.push(id) };

    await runCleanup({ auth, db, source, dryRun: false });

    assert.deepEqual(
      { requested, movies: await movieIds(db, 'sem-conta') },
      { requested: [], movies: [] },
    );
  });

  test('deve juntar as contagens das duas etapas', async () => {
    await addMovie('users/alice/movies/550');
    await addMovie('users/sem-conta/movies/603', Timestamp.now());
    const source = { fetchCopy: async () => ({ title: 'Novo', posterPath: null }) };

    const report = await runCleanup({ auth, db, source, dryRun: false });

    assert.deepEqual(report, {
      orphanUsers: 1,
      needsConfirmation: false,
      copies: { expired: 1, renewed: 1, removed: 0, failed: 0, noTitle: 0, skipped: 0, stopped: null },
    });
  });

  test('na simulação, não deve contar as cópias de quem vai ser apagado', async () => {
    await addMovie('users/sem-conta/movies/550');

    const report = await runCleanup({ auth, db, source: null, dryRun: true });

    assert.equal(report.copies.expired, 0);
  });

  test('deve levar no erro o que as etapas já tinham feito', async () => {
    await addMovie('users/sem-conta/movies/603', Timestamp.now());
    await addMovie('users/alice/movies/550');
    const source = { fetchCopy: async () => { throw new TypeError('bug'); } };

    await assert.rejects(
      runCleanup({ auth, db, source, dryRun: false }),
      (error) => error.partialReport?.orphanUsers === 1,
    );
  });
});

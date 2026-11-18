import { after, beforeEach, describe, test } from 'node:test';
import assert from 'node:assert/strict';
import { Timestamp } from 'firebase-admin/firestore';
import { UsageError, formatReport, parseArgs, runCleanup } from '../../cleanup/cleanup.js';
import { clearEmulators, createAccount, createAdmin, movieIds } from './admin-environment.js';

const TOKEN = 'token-de-teste';

describe('argumentos da limpeza mensal', () => {
  test('deve exigir o projeto explícito', () => {
    assert.throws(() => parseArgs([], { TMDB_READ_TOKEN: TOKEN }), UsageError);
  });

  test('deve ler o projeto e o token do TMDB do ambiente', () => {
    const options = parseArgs(['--project', 'meu-projeto'], { TMDB_READ_TOKEN: TOKEN });

    assert.deepEqual(options, { projectId: 'meu-projeto', dryRun: false, tmdbToken: TOKEN });
  });

  test('deve exigir o token do TMDB fora da simulação', () => {
    assert.throws(() => parseArgs(['--project', 'meu-projeto'], {}), UsageError);
  });

  test('na simulação, não deve exigir o token do TMDB', () => {
    const options = parseArgs(['--project', 'meu-projeto', '--dry-run'], {});

    assert.deepEqual(options, { projectId: 'meu-projeto', dryRun: true, tmdbToken: null });
  });

  test('deve recusar argumento desconhecido', () => {
    assert.throws(
      () => parseArgs(['--project', 'meu-projeto', '--force'], { TMDB_READ_TOKEN: TOKEN }),
      UsageError,
    );
  });

  test('deve recusar --project sem o nome do projeto', () => {
    assert.throws(() => parseArgs(['--project', '--dry-run'], {}), UsageError);
  });
});

describe('relatório da limpeza mensal', () => {
  const report = {
    projectId: 'meu-projeto',
    dryRun: false,
    orphanUsers: 2,
    copies: { expired: 5, renewed: 3, removed: 1, failed: 1, rateLimited: false },
  };

  test('deve mostrar só as contagens e o projeto', () => {
    assert.equal(formatReport(report), [
      'Limpeza mensal do Firestore — projeto meu-projeto',
      'Dados sem conta apagados: 2 users/{uid}',
      'Cópias vencidas: 5 (renovadas: 3, filmes apagados: 1, falhas: 1)',
    ].join('\n'));
  });

  test('na simulação, deve dizer que os dados sem conta foram só encontrados', () => {
    assert.match(formatReport({ ...report, dryRun: true }), /Dados sem conta encontrados: 2/);
  });

  test('deve avisar que a simulação não gravou nada', () => {
    assert.match(formatReport({ ...report, dryRun: true }), /simulação: nada foi gravado/);
  });

  test('deve avisar quando parou no limite do TMDB', () => {
    const limited = { ...report, copies: { ...report.copies, rateLimited: true } };

    assert.match(formatReport(limited), /limite de requisições do TMDB/);
  });
});

describe('limpeza mensal completa', () => {
  const admin = createAdmin();
  const { auth, db } = admin;

  beforeEach(clearEmulators);
  after(() => admin.close());

  test('deve apagar os dados sem conta antes de renovar cópias', async () => {
    await db.doc('users/sem-conta/movies/550').set({
      title: 'Antigo',
      cachedAt: Timestamp.fromDate(new Date('2020-01-01')),
      watchedAt: Timestamp.now(),
    });
    const requested = [];
    const source = { fetchCopy: async (id) => requested.push(id) };

    await runCleanup({ auth, db, source, dryRun: false });

    assert.deepEqual(
      { requested, movies: await movieIds(db, 'sem-conta') },
      { requested: [], movies: [] },
    );
  });

  test('deve juntar as contagens das duas etapas', async () => {
    await createAccount(auth, 'alice');
    await db.doc('users/alice/movies/550').set({
      title: 'Antigo',
      cachedAt: Timestamp.fromDate(new Date('2020-01-01')),
      watchedAt: Timestamp.now(),
    });
    await db.doc('users/sem-conta/movies/603').set({
      title: 'Antigo',
      cachedAt: Timestamp.now(),
      watchedAt: Timestamp.now(),
    });
    const source = { fetchCopy: async () => ({ title: 'Novo', posterPath: null }) };

    const report = await runCleanup({ auth, db, source, dryRun: false });

    assert.deepEqual(report, {
      orphanUsers: 1,
      copies: { expired: 1, renewed: 1, removed: 0, failed: 0, rateLimited: false },
    });
  });
});

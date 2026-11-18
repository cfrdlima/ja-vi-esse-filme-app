// Limpeza mensal do Firestore (decisão 017). Passo a passo em
// dev/LIMPEZA-MENSAL.md. A credencial é a do dono do projeto (ADC do gcloud).
import { applicationDefault, deleteApp, initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';
import { UsageError, formatReport, parseArgs, runCleanup } from './cleanup.js';
import { OrphanSafetyError } from './orphan-user-data.js';
import { createTmdbCopySource } from './tmdb-copy.js';

const USAGE = 'uso: npm run cleanup -- --project <id> [--dry-run] [--confirm-orphans <n>]';

let options;
try {
  options = parseArgs(process.argv.slice(2), process.env);
} catch (error) {
  if (!(error instanceof UsageError)) throw error;
  console.error(`${error.message}\n${USAGE}`);
  process.exit(2);
}

const { projectId, dryRun, tmdbToken, confirmOrphans } = options;
const app = initializeApp({ credential: applicationDefault(), projectId });
const source = dryRun ? null : createTmdbCopySource({ token: tmdbToken, fetch: globalThis.fetch });

try {
  const result = await runCleanup({ auth: getAuth(app), db: getFirestore(app), source, dryRun, confirmOrphans });
  console.log(formatReport({ projectId, dryRun, ...result }));
  // Um filme sem título no TMDB não é falha da execução: ele volta todo mês.
  if (result.copies.failed > 0 || result.copies.stopped) process.exitCode = 1;
} catch (error) {
  if (error.partialReport) console.log(formatReport({ projectId, dryRun, ...error.partialReport }));
  // A trava só fala de contagens. Outros erros podem trazer o caminho
  // users/{uid} na mensagem: só o tipo e o código.
  const detail = error instanceof OrphanSafetyError
    ? error.message
    : `${error?.name ?? 'Error'}${error?.code ? ` (${error.code})` : ''}`;
  console.error(`A limpeza falhou: ${detail}`);
  process.exitCode = 1;
} finally {
  await deleteApp(app);
}

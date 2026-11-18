// Limpeza mensal do Firestore (decisão 017). Uso, de dentro de firestore/:
//   npm run cleanup -- --project <id> --dry-run
//   TMDB_READ_TOKEN=... npm run cleanup -- --project <id>
// A credencial é a do dono do projeto (gcloud auth application-default login).
import { applicationDefault, initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';
import { UsageError, formatReport, parseArgs, runCleanup } from './cleanup.js';
import { createTmdbCopySource } from './tmdb-copy.js';

const USAGE = 'uso: npm run cleanup -- --project <id> [--dry-run]';

let options;
try {
  options = parseArgs(process.argv.slice(2), process.env);
} catch (error) {
  if (!(error instanceof UsageError)) throw error;
  console.error(`${error.message}\n${USAGE}`);
  process.exit(2);
}

const { projectId, dryRun, tmdbToken } = options;
const app = initializeApp({ credential: applicationDefault(), projectId });
const source = dryRun
  ? { fetchCopy: () => Promise.reject(new Error('a simulação não chama o TMDB')) }
  : createTmdbCopySource({ token: tmdbToken, fetch: globalThis.fetch });

try {
  const result = await runCleanup({ auth: getAuth(app), db: getFirestore(app), source, dryRun });
  console.log(formatReport({ projectId, dryRun, ...result }));
  if (result.copies.failed > 0 || result.copies.rateLimited) process.exitCode = 1;
} catch (error) {
  // A mensagem do Firestore pode trazer o caminho users/{uid}: só o tipo e o código.
  console.error(`A limpeza falhou: ${error?.name ?? 'Error'}${error?.code ? ` (${error.code})` : ''}`);
  process.exitCode = 1;
}

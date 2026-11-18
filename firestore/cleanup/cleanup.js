import { renewExpiredCopies } from './expired-copies.js';
import { deleteOrphanUserData } from './orphan-user-data.js';

export class UsageError extends Error {
  constructor(message) {
    super(message);
    this.name = 'UsageError';
  }
}

// O projeto é sempre explícito, para nunca rodar contra um projeto por
// engano. O token do TMDB vem do ambiente, nunca de argumento (que fica no
// histórico do shell) nem de arquivo do repositório.
export function parseArgs(argv, env) {
  let projectId = null;
  let dryRun = false;
  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i];
    if (arg === '--dry-run') {
      dryRun = true;
    } else if (arg === '--project') {
      const value = argv[++i];
      if (!value || value.startsWith('--')) throw new UsageError('--project precisa do id do projeto');
      projectId = value;
    } else {
      throw new UsageError(`argumento desconhecido: ${arg}`);
    }
  }
  if (!projectId) throw new UsageError('informe o projeto com --project <id>');
  const tmdbToken = env.TMDB_READ_TOKEN || null;
  if (!dryRun && !tmdbToken) throw new UsageError('defina TMDB_READ_TOKEN (token de leitura v4) para renovar as cópias');
  return { projectId, dryRun, tmdbToken };
}

// Primeiro os dados sem conta, para não gastar requisições ao TMDB com
// cópias que vão ser apagadas.
export async function runCleanup({ auth, db, source, dryRun, now = new Date() }) {
  const { orphanUsers } = await deleteOrphanUserData({ auth, db, dryRun });
  const copies = await renewExpiredCopies({ db, source, now, dryRun });
  return { orphanUsers, copies };
}

// Só contagens: nunca uid, e-mail, título nem token (decisão 017).
export function formatReport({ projectId, dryRun, orphanUsers, copies }) {
  const lines = [
    `Limpeza mensal do Firestore — projeto ${projectId}`,
    `Dados sem conta apagados: ${orphanUsers} users/{uid}`,
    `Cópias vencidas: ${copies.expired} (renovadas: ${copies.renewed}, filmes apagados: ${copies.removed}, falhas: ${copies.failed})`,
  ];
  if (copies.rateLimited) lines.push('Parou no limite de requisições do TMDB: rode de novo em alguns minutos.');
  if (dryRun) lines.push('Modo simulação: nada foi gravado.');
  return lines.join('\n');
}

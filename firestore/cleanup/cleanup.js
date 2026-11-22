import { renewExpiredCopies } from './expired-copies.js';
import { removeOrphanListKeys } from './orphan-list-keys.js';
import { deleteOrphanUserData } from './orphan-user-data.js';

export class UsageError extends Error {
  constructor(message) {
    super(message);
    this.name = 'UsageError';
  }
}

// O Admin SDK escolhe o emulador por variável, serviço a serviço: o Auth no
// emulador com o Firestore real faria todo mundo parecer sem conta.
const EMULATOR_VARIABLES = ['FIRESTORE_EMULATOR_HOST', 'FIREBASE_AUTH_EMULATOR_HOST', 'FIREBASE_EMULATOR_HUB'];

// O projeto é sempre explícito, para nunca rodar contra um projeto por
// engano. O token do TMDB vem do ambiente, nunca de argumento (que fica no
// histórico do shell) nem de arquivo do repositório.
export function parseArgs(argv, env) {
  const options = { projectId: null, dryRun: false, confirmOrphans: null };
  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i];
    if (arg === '--dry-run') {
      options.dryRun = true;
    } else if (arg === '--project') {
      options.projectId = valueOf(argv[++i], '--project precisa do id do projeto');
    } else if (arg === '--confirm-orphans') {
      options.confirmOrphans = positiveInteger(argv[++i]);
    } else {
      throw new UsageError(`argumento desconhecido: ${arg}`);
    }
  }
  if (!options.projectId) throw new UsageError('informe o projeto com --project <id>');
  if (options.projectId.startsWith('demo-')) throw new UsageError('projeto demo- é só dos emuladores');
  const emulator = EMULATOR_VARIABLES.find((name) => env[name]);
  if (emulator) throw new UsageError(`${emulator} está definida: rode "unset ${emulator}" antes`);
  const tmdbToken = env.TMDB_READ_TOKEN || null;
  if (!options.dryRun && !tmdbToken) {
    throw new UsageError('defina TMDB_READ_TOKEN (token de leitura v4) para renovar as cópias');
  }
  return { projectId: options.projectId, dryRun: options.dryRun, tmdbToken, confirmOrphans: options.confirmOrphans };
}

function valueOf(value, message) {
  if (!value || value.startsWith('--')) throw new UsageError(message);
  return value;
}

function positiveInteger(value) {
  if (!/^[1-9][0-9]*$/.test(value ?? '')) throw new UsageError('--confirm-orphans precisa de um número inteiro positivo');
  return Number(value);
}

// Primeiro os dados sem conta e os filmes só em listas apagadas, para não
// gastar requisições ao TMDB com cópias que vão ser apagadas. Num erro, o
// relatório parcial vai junto.
export async function runCleanup({ auth, db, source, dryRun, confirmOrphans = null, now = new Date() }) {
  const orphans = await deleteOrphanUserData({ auth, db, dryRun, confirmOrphans });
  const partial = {
    orphanUsers: orphans.orphanUsers,
    needsConfirmation: orphans.needsConfirmation,
    listKeys: null,
    copies: null,
  };
  try {
    // Na simulação, os órfãos continuam lá: os filmes deles não contam.
    const skipUserIds = dryRun ? orphans.orphanIds : new Set();
    partial.listKeys = await removeOrphanListKeys({ db, dryRun, skipUserIds });
    partial.copies = await renewExpiredCopies({ db, source, now, dryRun, skipUserIds });
    return partial;
  } catch (error) {
    partial.copies = error.partialReport ?? null;
    error.partialReport = partial;
    throw error;
  }
}

const STOP_MESSAGES = {
  'rate-limit': 'Parou no limite de requisições do TMDB: rode de novo em alguns minutos.',
  unauthorized: 'Parou porque o TMDB recusou o token: confira o TMDB_READ_TOKEN.',
  'not-found-streak': 'Parou depois de 404 seguidos do TMDB, sem apagar o último: confira o TMDB antes de rodar de novo.',
  quota: 'Parou na cota do Firestore: rode de novo amanhã.',
  'write-limit': 'Parou no teto de escritas da execução: rode de novo amanhã para continuar.',
};

// Só contagens: nunca uid, e-mail, título nem token (decisão 017).
export function formatReport({ projectId, dryRun, orphanUsers, needsConfirmation, listKeys, copies }) {
  const lines = [
    `Limpeza mensal do Firestore — projeto ${projectId}`,
    `Dados sem conta ${dryRun ? 'encontrados' : 'apagados'}: ${orphanUsers} users/{uid}`,
  ];
  if (dryRun && needsConfirmation) {
    lines.push(`Acima do limite: na execução real, confirme com --confirm-orphans ${orphanUsers}.`);
  }
  if (listKeys === null) {
    lines.push('Chaves de lista sem lista: a etapa não terminou.');
  } else {
    lines.push(
      `Chaves de lista sem lista ${dryRun ? 'encontradas' : 'tiradas'}: ${listKeys.keys}, ` +
        `em ${listKeys.movies} filmes (filmes apagados: ${listKeys.removed})`,
    );
  }
  if (copies === null) {
    lines.push('Cópias vencidas: a etapa não terminou.');
  } else {
    lines.push(
      `Cópias vencidas: ${copies.expired} (renovadas: ${copies.renewed}, filmes apagados: ${copies.removed}, ` +
        `falhas: ${copies.failed}, sem título no TMDB: ${copies.noTitle}, puladas: ${copies.skipped})`,
    );
    if (copies.stopped) lines.push(STOP_MESSAGES[copies.stopped]);
  }
  if (dryRun) lines.push('Modo simulação: nada foi gravado.');
  return lines.join('\n');
}

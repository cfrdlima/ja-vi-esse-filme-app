// Apaga users/{uid} (o documento, se existir, e todas as subcoleções) de
// quem não tem conta no Firebase Authentication (decisões 015 e 017), com
// travas contra apagar em massa por engano (`/revisar` da sessão 027).

// Acima disto, só com --confirm-orphans igual à contagem da simulação.
const ORPHAN_LIMIT_ABSOLUTE = 5;
const ORPHAN_LIMIT_RATIO = 0.2;
// O getUsers do Admin SDK aceita até 100 identificadores por chamada.
const GET_USERS_BATCH = 100;

export class OrphanSafetyError extends Error {
  constructor(message) {
    super(message);
    this.name = 'OrphanSafetyError';
  }
}

export async function deleteOrphanUserData({
  auth,
  db,
  dryRun = false,
  confirmOrphans = null,
  pageSize = 1000,
}) {
  const accounts = await listAccountUids(auth, pageSize);
  // O listDocuments traz também o users/{uid} que só existe pelas
  // subcoleções (o app não cria o documento pai).
  const users = await db.collection('users').listDocuments();
  const orphans = users.filter((user) => !accounts.has(user.id));
  const limit = Math.max(ORPHAN_LIMIT_ABSOLUTE, users.length * ORPHAN_LIMIT_RATIO);
  const needsConfirmation = orphans.length > limit;
  const report = {
    orphanUsers: orphans.length,
    needsConfirmation,
    orphanIds: new Set(orphans.map((user) => user.id)),
  };
  if (dryRun) return report;

  if (accounts.size === 0 && users.length > 0) {
    throw new OrphanSafetyError('o Auth não devolveu nenhuma conta: nada foi apagado');
  }
  if (needsConfirmation && confirmOrphans !== orphans.length) {
    throw new OrphanSafetyError(
      `${orphans.length} users/{uid} sem conta passam do limite: rode a simulação e confirme com --confirm-orphans ${orphans.length}`,
    );
  }
  // Quem criou a conta depois da listagem não perde os dados.
  const stillOrphans = await withoutAccount(auth, orphans);
  for (const user of stillOrphans) await db.recursiveDelete(user);
  report.orphanUsers = stillOrphans.length;
  report.orphanIds = new Set(stillOrphans.map((user) => user.id));
  return report;
}

async function listAccountUids(auth, pageSize) {
  const uids = new Set();
  let pageToken;
  do {
    const page = await auth.listUsers(pageSize, pageToken);
    for (const user of page.users) uids.add(user.uid);
    pageToken = page.pageToken;
  } while (pageToken);
  return uids;
}

async function withoutAccount(auth, users) {
  const result = [];
  for (let i = 0; i < users.length; i += GET_USERS_BATCH) {
    const batch = users.slice(i, i + GET_USERS_BATCH);
    const { notFound } = await auth.getUsers(batch.map((user) => ({ uid: user.id })));
    const missing = new Set(notFound.map((identifier) => identifier.uid));
    result.push(...batch.filter((user) => missing.has(user.id)));
  }
  return result;
}

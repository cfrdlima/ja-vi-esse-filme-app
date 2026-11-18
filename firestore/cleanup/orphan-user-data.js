// Apaga users/{uid} (o documento, se existir, e todas as subcoleções) de
// quem não tem conta no Firebase Authentication (decisões 015 e 017).

export async function deleteOrphanUserData({ auth, db, dryRun = false, pageSize = 1000 }) {
  const accounts = await listAccountUids(auth, pageSize);
  // O listDocuments traz também o users/{uid} que só existe pelas
  // subcoleções (o app não cria o documento pai).
  const users = await db.collection('users').listDocuments();
  const orphans = users.filter((user) => !accounts.has(user.id));
  if (!dryRun) {
    for (const user of orphans) await db.recursiveDelete(user);
  }
  return { orphanUsers: orphans.length };
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

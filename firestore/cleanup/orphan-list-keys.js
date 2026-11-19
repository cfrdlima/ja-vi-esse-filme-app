import { FieldValue } from 'firebase-admin/firestore';
import { MOVIES } from './expired-copies.js';

// Subcoleção das listas (UserCollections.lists no app, decisão 019).
export const LISTS = 'lists';

// As marcas do documento do filme (decisão 013): sem nenhuma e sem lista,
// ele não tem motivo para existir.
const MARKS = ['watchedAt', 'watchlistAt', 'favoriteAt'];

// Tira do mapa lists dos filmes as chaves cujo users/{uid}/lists/{id} não
// existe mais: filme posto offline numa lista que outro aparelho apagou, ou
// numa lista cuja criação o servidor recusou (`/revisar` da sessão 029). O
// filme que fica sem marca e sem lista é apagado, como o app faria. O Admin
// SDK ignora as regras: a escrita tira todas as chaves de uma vez.
export async function removeOrphanListKeys({ db, dryRun = false, skipUserIds = new Set() }) {
  const report = { keys: 0, movies: 0, removed: 0 };
  const users = await db.collection('users').listDocuments();
  for (const user of users) {
    if (skipUserIds.has(user.id)) continue;
    const lists = await user.collection(LISTS).listDocuments();
    const liveIds = new Set(lists.map((list) => list.id));
    const movies = await user.collection(MOVIES).where('lists', '!=', null).get();
    for (const movie of movies.docs) {
      const keys = Object.keys(movie.get('lists') ?? {});
      const orphans = keys.filter((id) => !liveIds.has(id));
      if (orphans.length === 0) continue;
      report.keys += orphans.length;
      report.movies++;
      const keepsList = orphans.length < keys.length;
      const keepsMark = MARKS.some((mark) => movie.get(mark) != null);
      if (!keepsList && !keepsMark) report.removed++;
      if (dryRun) continue;
      if (!keepsList && !keepsMark) {
        await movie.ref.delete();
      } else if (!keepsList) {
        await movie.ref.update({ lists: FieldValue.delete() });
      } else {
        await movie.ref.update(
          Object.fromEntries(orphans.map((id) => [`lists.${id}`, FieldValue.delete()])),
        );
      }
    }
  }
  return report;
}

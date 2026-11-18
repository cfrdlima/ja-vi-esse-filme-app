import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { MovieNotFoundError, RateLimitedError, TmdbError } from './tmdb-copy.js';

// Prazo da cópia do TMDB (§1.C dos termos), o mesmo do app
// (ShelfMovie.copyMaxAge) e da decisão 013.
const COPY_MAX_AGE_DAYS = 180;
const DAY_MS = 24 * 60 * 60 * 1000;

// Subcoleção dos filmes marcados (UserCollections.movies no app); um teste
// confere que ela está na lista do app.
export const MOVIES = 'movies';

// Renova pelo TMDB as cópias vencidas que a Estante não renovou (decisão
// 017). Um filme que sumiu do TMDB é apagado, porque o app já não consegue
// mostrá-lo. No limite de requisições, para: o resto fica para a próxima.
export async function renewExpiredCopies({ db, source, now = new Date(), dryRun = false }) {
  const report = { expired: 0, renewed: 0, removed: 0, failed: 0, rateLimited: false };
  const expired = await listExpiredMovies(db, now);
  report.expired = expired.length;
  if (dryRun) return report;

  for (const movie of expired) {
    try {
      const copy = await source.fetchCopy(Number(movie.id));
      await movie.ref.update({
        title: copy.title,
        posterPath: copy.posterPath ?? FieldValue.delete(),
        cachedAt: FieldValue.serverTimestamp(),
      });
      report.renewed++;
    } catch (error) {
      if (error instanceof RateLimitedError) {
        report.rateLimited = true;
        break;
      }
      if (error instanceof MovieNotFoundError) {
        await movie.ref.delete();
        report.removed++;
      } else if (error instanceof TmdbError) {
        report.failed++;
      } else {
        throw error;
      }
    }
  }
  return report;
}

// O app trata como vencida a cópia com cachedAt + 180 dias <= agora.
async function listExpiredMovies(db, now) {
  const cutoff = Timestamp.fromMillis(now.getTime() - COPY_MAX_AGE_DAYS * DAY_MS);
  const users = await db.collection('users').listDocuments();
  const expired = [];
  for (const user of users) {
    const snapshot = await user.collection(MOVIES).where('cachedAt', '<=', cutoff).get();
    expired.push(...snapshot.docs);
  }
  return expired;
}

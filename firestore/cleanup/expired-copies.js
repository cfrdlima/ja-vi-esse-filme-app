import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import {
  MissingTitleError,
  MovieNotFoundError,
  RateLimitedError,
  TmdbError,
  UnauthorizedError,
} from './tmdb-copy.js';

// Prazo da cópia do TMDB (§1.C dos termos), o mesmo do app
// (ShelfMovie.copyMaxAge) e da decisão 013.
const COPY_MAX_AGE_DAYS = 180;
const DAY_MS = 24 * 60 * 60 * 1000;

// Subcoleção dos filmes marcados (UserCollections.movies no app); um teste
// confere que ela está na lista do app.
export const MOVIES = 'movies';

// Vários 404 seguidos sugerem problema do lado do TMDB, e não filmes
// removidos: a limpeza para antes de apagar o quinto.
const NOT_FOUND_STREAK_LIMIT = 5;
// Abaixo da cota diária do Spark (20 mil escritas e 20 mil exclusões).
const DEFAULT_MAX_WRITES = 5000;

// Códigos gRPC do Firestore.
const GRPC_NOT_FOUND = 5;
const GRPC_RESOURCE_EXHAUSTED = 8;

// Renova pelo TMDB as cópias vencidas que a Estante não renovou (decisão
// 017). Um filme que sumiu do TMDB é apagado, porque o app já não consegue
// mostrá-lo. Nas paradas (limite, token, cota, teto), o resto fica para a
// próxima execução, e o relatório diz por quê.
export async function renewExpiredCopies({
  db,
  source,
  now = new Date(),
  dryRun = false,
  maxWrites = DEFAULT_MAX_WRITES,
  skipUserIds = new Set(),
}) {
  const report = { expired: 0, renewed: 0, removed: 0, failed: 0, noTitle: 0, skipped: 0, stopped: null };
  const expired = await listExpiredMovies(db, now, skipUserIds);
  report.expired = expired.length;
  if (dryRun) return report;

  let notFoundStreak = 0;
  for (const movie of expired) {
    if (report.renewed + report.removed >= maxWrites) {
      report.stopped = 'write-limit';
      break;
    }
    try {
      const outcome = await renewOne(movie, source, notFoundStreak);
      if (outcome === 'stop-not-found') {
        report.stopped = 'not-found-streak';
        break;
      }
      notFoundStreak = outcome === 'removed' ? notFoundStreak + 1 : 0;
      report[outcome]++;
    } catch (error) {
      const stop = stopReason(error);
      if (stop) {
        report.stopped = stop;
        break;
      }
      error.partialReport = report;
      throw error;
    }
  }
  return report;
}

async function renewOne(movie, source, notFoundStreak) {
  try {
    const copy = await source.fetchCopy(Number(movie.id));
    await movie.ref.update({
      title: copy.title,
      posterPath: copy.posterPath ?? FieldValue.delete(),
      cachedAt: FieldValue.serverTimestamp(),
    });
    return 'renewed';
  } catch (error) {
    if (error instanceof MovieNotFoundError) {
      if (notFoundStreak + 1 >= NOT_FOUND_STREAK_LIMIT) return 'stop-not-found';
      await movie.ref.delete();
      return 'removed';
    }
    // O usuário desmarcou o filme enquanto o TMDB respondia.
    if (error?.code === GRPC_NOT_FOUND) return 'skipped';
    if (error instanceof MissingTitleError) return 'noTitle';
    if (error instanceof TmdbError && !(error instanceof RateLimitedError || error instanceof UnauthorizedError)) {
      return 'failed';
    }
    throw error;
  }
}

function stopReason(error) {
  if (error instanceof RateLimitedError) return 'rate-limit';
  if (error instanceof UnauthorizedError) return 'unauthorized';
  if (error?.code === GRPC_RESOURCE_EXHAUSTED) return 'quota';
  return null;
}

// O app trata como vencida a cópia com cachedAt + 180 dias <= agora.
async function listExpiredMovies(db, now, skipUserIds) {
  const cutoff = Timestamp.fromMillis(now.getTime() - COPY_MAX_AGE_DAYS * DAY_MS);
  const users = await db.collection('users').listDocuments();
  const expired = [];
  for (const user of users) {
    if (skipUserIds.has(user.id)) continue;
    const snapshot = await user.collection(MOVIES).where('cachedAt', '<=', cutoff).get();
    expired.push(...snapshot.docs);
  }
  return expired;
}

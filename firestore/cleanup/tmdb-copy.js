// Cópia do título e do pôster de um filme pelo TMDB, do mesmo jeito que o
// app faz (TmdbMovieCopySource e MovieCopy): título em pt-BR com o original
// de reserva, cortado em 300 unidades UTF-16, e o pôster só no formato do
// TMDB. Diferença aceita: um título pt-BR só com espaços cai no original
// aqui, e no app vira falha (emenda da decisão 017).

const API_BASE = 'https://api.themoviedb.org/3';
const MAX_TITLE_LENGTH = 300;
const TMDB_IMAGE_PATH = /^\/[A-Za-z0-9_-]{1,64}\.(jpg|png)$/;
const TIMEOUT_MS = 10_000;
// "The resource you requested could not be found." na API do TMDB.
const TMDB_NOT_FOUND_CODE = 34;

export class TmdbError extends Error {
  constructor(message) {
    super(message);
    this.name = new.target.name;
  }
}

export class MovieNotFoundError extends TmdbError {}
export class RateLimitedError extends TmdbError {}
export class UnauthorizedError extends TmdbError {}
export class MissingTitleError extends TmdbError {}

export function createTmdbCopySource({ token, fetch }) {
  return {
    async fetchCopy(movieId) {
      const json = await getDetails(movieId, { token, fetch });
      const title = firstNonBlank(json.title, json.original_title);
      if (title === null) throw new MissingTitleError(`filme ${movieId} sem título`);
      return { title: fitTitle(title), posterPath: imagePath(json.poster_path) };
    },
  };
}

// As mensagens levam só o id e o status, nunca a URL com cabeçalho nem o token.
async function getDetails(movieId, { token, fetch }) {
  const url = new URL(`${API_BASE}/movie/${movieId}`);
  url.searchParams.set('language', 'pt-BR');
  let response;
  let json;
  try {
    response = await fetch(url, {
      headers: { Authorization: `Bearer ${token}`, Accept: 'application/json' },
      signal: AbortSignal.timeout(TIMEOUT_MS),
    });
    json = await readJson(response);
  } catch {
    throw new TmdbError(`sem resposta do TMDB para o filme ${movieId}`);
  }
  if (response.status === 401) throw new UnauthorizedError('o TMDB recusou o token de leitura');
  if (response.status === 429) throw new RateLimitedError('limite de requisições do TMDB');
  if (response.status === 404 && json?.status_code === TMDB_NOT_FOUND_CODE) {
    throw new MovieNotFoundError(`filme ${movieId} não existe no TMDB`);
  }
  if (!response.ok) throw new TmdbError(`TMDB respondeu ${response.status} para o filme ${movieId}`);
  if (json === null) throw new TmdbError(`resposta do TMDB fora do formato para o filme ${movieId}`);
  return json;
}

// Um corpo que não é um objeto JSON vira null, e não exceção.
async function readJson(response) {
  try {
    const json = JSON.parse(await response.text());
    return typeof json === 'object' && json !== null && !Array.isArray(json) ? json : null;
  } catch {
    return null;
  }
}

function fitTitle(title) {
  if (title.length <= MAX_TITLE_LENGTH) return title;
  const lastKept = title.charCodeAt(MAX_TITLE_LENGTH - 1);
  const splitsPair = lastKept >= 0xd800 && lastKept <= 0xdbff;
  return title.substring(0, MAX_TITLE_LENGTH - (splitsPair ? 1 : 0));
}

function firstNonBlank(...values) {
  for (const value of values) {
    if (typeof value === 'string' && value.trim() !== '') return value.trim();
  }
  return null;
}

function imagePath(value) {
  return typeof value === 'string' && TMDB_IMAGE_PATH.test(value) ? value : null;
}

// Cópia do título e do pôster de um filme pelo TMDB, do mesmo jeito que o
// app faz (TmdbMovieCopySource e MovieCopy): título em pt-BR com o original
// de reserva, cortado em 300 caracteres, e o pôster só no formato do TMDB.

const API_BASE = 'https://api.themoviedb.org/3';
const MAX_TITLE_LENGTH = 300;
const TMDB_IMAGE_PATH = /^\/[A-Za-z0-9_-]{1,64}\.(jpg|png)$/;

export class TmdbError extends Error {
  constructor(message) {
    super(message);
    this.name = new.target.name;
  }
}

export class MovieNotFoundError extends TmdbError {}
export class RateLimitedError extends TmdbError {}
export class MissingTitleError extends TmdbError {}

export function createTmdbCopySource({ token, fetch }) {
  return {
    async fetchCopy(movieId) {
      const json = await getDetails(movieId, { token, fetch });
      const title = firstNonBlank(json.title, json.original_title);
      if (title === null) throw new MissingTitleError(`filme ${movieId} sem título`);
      return {
        title: [...title].slice(0, MAX_TITLE_LENGTH).join(''),
        posterPath: imagePath(json.poster_path),
      };
    },
  };
}

// As mensagens levam só o id e o status, nunca a URL com cabeçalho nem o token.
async function getDetails(movieId, { token, fetch }) {
  const url = new URL(`${API_BASE}/movie/${movieId}`);
  url.searchParams.set('language', 'pt-BR');
  let response;
  try {
    response = await fetch(url, {
      headers: { Authorization: `Bearer ${token}`, Accept: 'application/json' },
    });
  } catch {
    throw new TmdbError(`sem resposta do TMDB para o filme ${movieId}`);
  }
  if (response.status === 404) throw new MovieNotFoundError(`filme ${movieId} não existe no TMDB`);
  if (response.status === 429) throw new RateLimitedError('limite de requisições do TMDB');
  if (!response.ok) throw new TmdbError(`TMDB respondeu ${response.status} para o filme ${movieId}`);
  return response.json();
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

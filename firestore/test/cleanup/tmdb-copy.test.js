import { describe, test } from 'node:test';
import assert from 'node:assert/strict';
import {
  MissingTitleError,
  MovieNotFoundError,
  RateLimitedError,
  TmdbError,
  createTmdbCopySource,
} from '../../cleanup/tmdb-copy.js';

// Nunca o TMDB real (CLAUDE.md): um fetch falso responde cada teste.
const TOKEN = 'token-de-teste';
const POSTER = '/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg';

function fakeFetch({ status = 200, body = {} } = {}) {
  const calls = [];
  const fetch = async (url, init) => {
    calls.push({ url: new URL(url), init });
    return new Response(JSON.stringify(body), { status });
  };
  return { fetch, calls };
}

function sourceWith(response) {
  const fake = fakeFetch(response);
  return { source: createTmdbCopySource({ token: TOKEN, fetch: fake.fetch }), calls: fake.calls };
}

describe('cópia do filme pelo TMDB', () => {
  test('deve pedir os detalhes do filme em pt-BR', async () => {
    const { source, calls } = sourceWith({ body: { title: 'Clube da Luta' } });

    await source.fetchCopy(550);

    assert.equal(
      calls[0].url.href,
      'https://api.themoviedb.org/3/movie/550?language=pt-BR',
    );
  });

  test('deve autenticar com o token v4 no cabeçalho, e não na URL', async () => {
    const { source, calls } = sourceWith({ body: { title: 'Clube da Luta' } });

    await source.fetchCopy(550);

    assert.equal(calls[0].init.headers.Authorization, `Bearer ${TOKEN}`);
  });

  test('deve usar o título em pt-BR sem espaços nas bordas', async () => {
    const { source } = sourceWith({ body: { title: '  Clube da Luta ' } });

    const copy = await source.fetchCopy(550);

    assert.equal(copy.title, 'Clube da Luta');
  });

  test('deve usar o título original quando o pt-BR vier vazio', async () => {
    const { source } = sourceWith({
      body: { title: '', original_title: 'Fight Club' },
    });

    const copy = await source.fetchCopy(550);

    assert.equal(copy.title, 'Fight Club');
  });

  test('deve cortar o título em 300 caracteres, como o app e as regras', async () => {
    const { source } = sourceWith({ body: { title: 'á'.repeat(301) } });

    const copy = await source.fetchCopy(550);

    assert.equal([...copy.title].length, 300);
  });

  test('deve devolver o caminho do pôster no formato do TMDB', async () => {
    const { source } = sourceWith({ body: { title: 'Clube da Luta', poster_path: POSTER } });

    const copy = await source.fetchCopy(550);

    assert.equal(copy.posterPath, POSTER);
  });

  test('deve descartar o pôster fora do formato do TMDB', async () => {
    const { source } = sourceWith({
      body: { title: 'Clube da Luta', poster_path: 'https://outro.host/x.jpg' },
    });

    const copy = await source.fetchCopy(550);

    assert.equal(copy.posterPath, null);
  });

  test('deve lançar MovieNotFoundError quando o filme sumiu do TMDB', async () => {
    const { source } = sourceWith({ status: 404 });

    await assert.rejects(source.fetchCopy(550), MovieNotFoundError);
  });

  test('deve lançar RateLimitedError no limite de requisições', async () => {
    const { source } = sourceWith({ status: 429 });

    await assert.rejects(source.fetchCopy(550), RateLimitedError);
  });

  test('deve lançar TmdbError em outra resposta de erro', async () => {
    const { source } = sourceWith({ status: 500 });

    await assert.rejects(source.fetchCopy(550), TmdbError);
  });

  test('deve lançar TmdbError quando a rede falha', async () => {
    const source = createTmdbCopySource({
      token: TOKEN,
      fetch: async () => {
        throw new TypeError('fetch failed');
      },
    });

    await assert.rejects(source.fetchCopy(550), TmdbError);
  });

  test('deve lançar MissingTitleError quando o TMDB não manda título', async () => {
    const { source } = sourceWith({ body: { title: ' ', original_title: null } });

    await assert.rejects(source.fetchCopy(550), MissingTitleError);
  });

  test('não deve pôr o token na mensagem de erro', async () => {
    const { source } = sourceWith({ status: 401 });

    await assert.rejects(source.fetchCopy(550), (error) => !error.message.includes(TOKEN));
  });
});

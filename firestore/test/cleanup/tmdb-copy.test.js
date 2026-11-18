import { describe, test } from 'node:test';
import assert from 'node:assert/strict';
import {
  MissingTitleError,
  MovieNotFoundError,
  RateLimitedError,
  TmdbError,
  UnauthorizedError,
  createTmdbCopySource,
} from '../../cleanup/tmdb-copy.js';

// Nunca o TMDB real (CLAUDE.md): um fetch falso responde cada teste.
const TOKEN = 'token-de-teste';
const POSTER = '/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg';

// O corpo em texto cru permite simular resposta que não é JSON.
function fakeFetch({ status = 200, body = {}, rawBody } = {}) {
  const calls = [];
  const fetch = async (url, init) => {
    calls.push({ url: new URL(url), init });
    return new Response(rawBody ?? JSON.stringify(body), { status });
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

  // As regras e o app contam unidades UTF-16 (MovieCopy._fitTitle), e um
  // título maior impediria o app de desmarcar o filme depois.
  test('deve cortar o título em 300 unidades UTF-16, como o app e as regras', async () => {
    const { source } = sourceWith({ body: { title: '🎬'.repeat(151) } });

    const copy = await source.fetchCopy(550);

    assert.equal(copy.title.length, 300);
  });

  test('não deve partir um emoji ao meio no corte do título', async () => {
    const { source } = sourceWith({ body: { title: `${'a'.repeat(299)}🎬` } });

    const copy = await source.fetchCopy(550);

    assert.equal(copy.title, 'a'.repeat(299));
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

  // O 404 com status_code 34 é o "recurso não encontrado" do TMDB; outro
  // 404 (rota, incidente) não pode apagar as marcas de ninguém.
  test('deve lançar MovieNotFoundError quando o filme sumiu do TMDB', async () => {
    const { source } = sourceWith({ status: 404, body: { status_code: 34 } });

    await assert.rejects(source.fetchCopy(550), MovieNotFoundError);
  });

  test('deve tratar o 404 sem o código 34 do TMDB como falha comum', async () => {
    const { source } = sourceWith({ status: 404, rawBody: 'Not Found' });

    await assert.rejects(
      source.fetchCopy(550),
      (error) => error instanceof TmdbError && !(error instanceof MovieNotFoundError),
    );
  });

  test('deve lançar UnauthorizedError quando o token é recusado', async () => {
    const { source } = sourceWith({ status: 401 });

    await assert.rejects(source.fetchCopy(550), UnauthorizedError);
  });

  test('deve lançar TmdbError quando a resposta não é JSON', async () => {
    const { source } = sourceWith({ rawBody: '<html>erro</html>' });

    await assert.rejects(source.fetchCopy(550), TmdbError);
  });

  test('deve lançar TmdbError quando o JSON não é um objeto', async () => {
    const { source } = sourceWith({ rawBody: 'null' });

    await assert.rejects(source.fetchCopy(550), TmdbError);
  });

  test('deve pedir com prazo, para uma conexão presa não travar a limpeza', async () => {
    const { source, calls } = sourceWith({ body: { title: 'Clube da Luta' } });

    await source.fetchCopy(550);

    assert.ok(calls[0].init.signal instanceof AbortSignal);
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

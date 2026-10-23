# Sessão 010 — Fase 1: busca de filmes

**Data**: 2026-10-23 · **Branch**: `feature/010-busca` · **Status**: aberta

## Objetivo
Trocar o placeholder da aba Buscar por uma busca de filmes (`/search/movie` com `include_adult=false`) com debounce de 400 ms, termo de 2 a 100 caracteres validado no domínio e paginação infinita. A tela tem os estados inicial, carregando, vazio, erro (com a espera do 429) e sucesso, e o app não guarda histórico de busca.

## Checklist
- [ ] Contrato: conferir `/search/movie` na documentação oficial (Context7/web): query (`query`, `page`, `include_adult`, `language`, `region`, `year`) e campos da resposta
- [ ] Design: consultar a `ui-ux-pro-max` (stack Flutter) para campo de busca, estado inicial e vazio; criar o override `pages/buscar.md`
- [ ] Domínio: `SearchQuery` (trim, mínimo 2, máximo 100, falha tipada fora disso) — RED / GREEN / REFACTOR
- [ ] Domínio: `MovieRepository.search(query, page:)` com a mesma guarda de página < 1 — RED / GREEN
- [ ] Fixtures `search_movie_page1.json` e `search_movie_empty.json`
- [ ] Datasource: `search/movie` com `query` e `include_adult=false`, e termo com acento/espaço/`&` codificado na URL — RED / GREEN / REFACTOR
- [ ] Refactor: `PagedMoviesNotifier` recebe a fonte das páginas, para servir a categoria e a busca (testes atuais verdes, refactor puro)
- [ ] Estado: `SearchNotifier` com debounce de 400 ms (relógio do `fakeAsync`), sem pedido para termo inválido, termo repetido ou vazio, e resposta de termo antigo descartada — RED / GREEN / REFACTOR
- [ ] Estado: limpar o campo volta ao estado inicial e cancela o debounce; `dispose` cancela o timer — RED / GREEN
- [ ] Tela Buscar: campo com limite de 100, botão de limpar com `Semantics`, estados inicial, carregando (skeleton), vazio com o termo, erro com `RetryButton` e sucesso com grade e paginação — RED / GREEN, com `textScaler` 1.5 numa tela de 320dp
- [ ] Strings novas no ARB (dica do campo, inicial, vazio com o termo, limpar)
- [ ] Composição: o router monta o `SearchNotifier` na aba Buscar e sai o placeholder dela
- [ ] Política: conferir que a seção 2 (termos de busca vão ao TMDB, sem histórico no app) continua verdadeira
- [ ] Tríade: `flutter analyze` limpo, `flutter test` verde e emulador (digitação, vazio, paginação e fonte grande)
- [ ] `/revisar`: `code-reviewer` + `security-auditor` (a sessão toca rede e entrada do usuário)

## Decisões

## Commits

## Notas

# Sessão 008 — Fase 1: Descobrir, filmes populares

**Data**: 2026-10-23 · **Branch**: `feature/008-descobrir-populares` · **Status**: aberta

## Objetivo
Levar a lista de filmes populares (`/movie/popular`) do domínio até a aba Descobrir, com paginação infinita, os quatro estados e um pôster com placeholder. Junto entram a primeira feature em Clean Architecture (`features/movies`), o `provider` e o `cached_network_image`, a composição das dependências no `main.dart` e a política de privacidade passando a declarar o cache de imagens. Em cartaz e melhor avaliados ficam para a sessão 009.

## Checklist
- [ ] Contrato: conferir `/movie/popular` na documentação oficial (Context7/web) e listar só os campos usados (`id`, `title`, `poster_path`, `release_date`, `vote_average`, `page`, `total_pages`)
- [ ] Design: consultar a `ui-ux-pro-max` (stack Flutter) para a grade de pôsteres, o skeleton e a paginação; gerar override `pages/descobrir.md` se precisar
- [ ] Dependências: `provider` e `cached_network_image` no `pubspec.yaml` (estão na stack do `CLAUDE.md`)
- [ ] Entidades `Movie` e `MoviePage` (domain) — RED / GREEN / REFACTOR
- [ ] Fixtures `movie_popular_page1.json` e uma degradada (`poster_path: null`, `release_date: ""`, `vote_average` int)
- [ ] `MovieModel.fromJson` + `toEntity` com parse defensivo — RED / GREEN / REFACTOR
- [ ] `MovieRemoteDataSource.popular(page)` sobre `TmdbClient` + `MockClient` (path e query certos, falhas repassadas) — RED / GREEN / REFACTOR
- [ ] `MovieRepository` (contrato em domain) e implementação com paginação (`page`, `total_pages`, `hasMore`) — RED / GREEN / REFACTOR
- [ ] Estado `PopularMoviesNotifier` (sealed: carregando, vazio, erro, sucesso), com carregar, carregar a próxima página (sem pedido duplicado nem além da última), falha na próxima página sem perder a lista e tentar de novo — RED / GREEN / REFACTOR por transição
- [ ] Widget `MoviePoster`: 2:3, `w342`, placeholder desenhado sem `poster_path` e `Semantics` com o título — RED / GREEN
- [ ] Tela Descobrir com os 4 estados (skeleton, vazio, erro com "Tentar de novo" e grade), mais o rodapé de carregando ou erro da próxima página — widget tests primeiro, e um teste com `textScaler` 1.5 sem overflow
- [ ] Rolagem infinita: chegar perto do fim pede a próxima página — RED / GREEN
- [ ] Strings novas no ARB (decisão 004), com chave de título própria `discoverTitle` (BACKLOG, revisão 006 item 7)
- [ ] Composição: `AppConfig`, `http.Client`, `TmdbClient` e repositório montados no `main.dart` e injetados, com `main_test` usando um fake; rota Descobrir sem placeholder
- [ ] `docs/PRIVACIDADE.md`: declarar o cache de imagens (prazo e como apagar) e remover o marcador da Fase 1 correspondente
- [ ] Tríade: `flutter analyze` limpo, `flutter test` verde e emulador (os 4 estados, rolagem infinita e fonte grande)
- [ ] `/revisar`: `code-reviewer` + `security-auditor` (a sessão toca rede e composição de config)

## Decisões

## Commits

## Notas

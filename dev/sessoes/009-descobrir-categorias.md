# Sessão 009 — Fase 1: Descobrir, em cartaz e melhor avaliados

**Data**: 2026-10-23 · **Branch**: `feature/009-descobrir-categorias` · **Status**: aberta

## Objetivo
Levar em cartaz (`/movie/now_playing` com `region=BR`) e melhor avaliados (`/movie/top_rated`) para a aba Descobrir, com um seletor de categoria na tela. O `PopularMoviesNotifier` vira um `PagedMoviesNotifier` genérico por categoria (S4 da revisão 008), e o "Tentar de novo" respeita o `retryAfter` do 429 (S11).

## Checklist
- [ ] Contrato: conferir `/movie/now_playing` e `/movie/top_rated` na documentação oficial (Context7/web): query (`page`, `region`) e campos da resposta (o `dates` do em cartaz não é usado)
- [ ] Design: consultar a `ui-ux-pro-max` (stack Flutter) para o seletor de categoria e o botão com espera; atualizar o override `pages/descobrir.md`
- [ ] Domínio: `MovieCategory` (populares, em cartaz, melhor avaliados) e `MovieRepository.byCategory` (ou um método por lista) — RED / GREEN / REFACTOR
- [ ] Fixtures `movie_now_playing_page1.json` e `movie_top_rated_page1.json`
- [ ] Datasource: path certo por categoria e `region=BR` só no em cartaz — RED / GREEN / REFACTOR
- [ ] Repositório: mesma guarda de página < 1 para todas as categorias — RED / GREEN / REFACTOR
- [ ] Refactor: `PopularMoviesNotifier`/`PopularMoviesState` → `PagedMoviesNotifier`/`PagedMoviesState` recebendo a função de busca da categoria, com os testes atuais mantidos verdes (refactor puro, sem mudar comportamento)
- [ ] Estado do seletor: categoria escolhida, um notifier por categoria (trocar de aba não recarrega a lista já carregada) — RED / GREEN / REFACTOR
- [ ] `retryAfter` do 429: botão "Tentar de novo" (tela e rodapé) desabilitado durante a espera, com contagem e reabilitado no fim; sem `retryAfter`, comportamento atual — RED / GREEN / REFACTOR (com `fakeAsync`)
- [ ] Tela Descobrir com o seletor: widget tests da troca de categoria, dos 4 estados por categoria e do `textScaler` 1.5 sem overflow no seletor
- [ ] Strings novas no ARB (rótulos das categorias, texto da espera)
- [ ] Composição: router/`main.dart` montando os notifiers das três categorias
- [ ] Tríade: `flutter analyze` limpo, `flutter test` verde e emulador (troca de categoria, rolagem infinita em cada uma e fonte grande)
- [ ] `/revisar`: `code-reviewer` + `security-auditor` (a sessão toca rede)

## Decisões

## Commits

## Notas

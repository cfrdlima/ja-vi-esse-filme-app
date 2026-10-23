# Sessão 009 — Fase 1: Descobrir, em cartaz e melhor avaliados

**Data**: 2026-10-23 · **Branch**: `feature/009-descobrir-categorias` · **Status**: aberta

## Objetivo
Levar em cartaz (`/movie/now_playing` com `region=BR`) e melhor avaliados (`/movie/top_rated`) para a aba Descobrir, com um seletor de categoria na tela. O `PopularMoviesNotifier` vira um `PagedMoviesNotifier` genérico por categoria (S4 da revisão 008), e o "Tentar de novo" respeita o `retryAfter` do 429 (S11).

## Checklist
- [x] Contrato: conferir `/movie/now_playing` e `/movie/top_rated` na documentação oficial (Context7/web): query (`page`, `region`) e campos da resposta (o `dates` do em cartaz não é usado)
- [x] Design: consultar a `ui-ux-pro-max` (stack Flutter) para o seletor de categoria e o botão com espera; atualizar o override `pages/descobrir.md`
- [x] Domínio: `MovieCategory` (populares, em cartaz, melhor avaliados) e `MovieRepository.byCategory` — RED / GREEN / REFACTOR
- [x] Fixtures `movie_now_playing_page1.json` e `movie_top_rated_page1.json`
- [x] Datasource: path certo por categoria e `region=BR` só no em cartaz — RED / GREEN / REFACTOR
- [x] Repositório: mesma guarda de página < 1 para todas as categorias — RED / GREEN / REFACTOR
- [x] Refactor: `PopularMoviesNotifier`/`PopularMoviesState` → `PagedMoviesNotifier`/`PagedMoviesState`, com os testes atuais verdes (refactor puro); depois a categoria entrou no construtor — RED / GREEN
- [x] `NextPageStatus` sealed com a falha em `NextPageFailed`, para o rodapé ler o `retryAfter` — RED / GREEN
- [x] Estado do seletor: `DiscoverNotifier` com a categoria escolhida e uma lista viva por categoria, carregada só na primeira vez — RED / GREEN / REFACTOR
- [x] `RetryButton` (`core/widgets`): desabilitado com "Tentar de novo em N s" durante o `retryAfter`, teto de 60 s, reabilita no fim e cancela o timer no `dispose` — RED / GREEN
- [x] Tela Descobrir: botão com espera no erro e no rodapé, seletor de chips, troca de categoria e rolagem guardada por categoria (`PageStorageKey`) — RED / GREEN, com `textScaler` 1.5 numa tela de 320dp
- [x] Strings novas no ARB (categorias e `retryIn`); `discoverLoading` e `discoverEmpty` sem "populares"
- [x] Composição: o router monta o `DiscoverNotifier` e escolhe Populares (`select`), que dispara o primeiro carregamento
- [x] Tríade: `flutter analyze` limpo, `flutter test` verde e emulador (troca de categoria, rolagem guardada e fonte grande)
- [ ] `/revisar`: `code-reviewer` + `security-auditor` (a sessão toca rede)

## Decisões
- Nenhuma nova. Valeram a 001 (todo acesso pelo `TmdbClient`), a 002 (`ui-ux-pro-max`) e a 004 (ARB). Sem dependência nova.

## Commits
- `29c71b3` docs: abre sessão 009
- `42d6ee3` add: categorias em cartaz e melhor avaliados no datasource e no repositório
- `83eef88` refactor: PopularMoviesNotifier vira PagedMoviesNotifier
- `58bdb1b` add: PagedMoviesNotifier recebe a categoria da lista
- `30689ae` add: rodapé da próxima página guarda a falha
- `062bca5` add: botão Tentar de novo com contagem do retryAfter do 429
- `e0e3f38` add: Descobrir espera o retryAfter do 429 no erro e no rodapé
- `ba2ee61` add: DiscoverNotifier com uma lista viva por categoria
- `0e12a7e` add: seletor de categoria na Descobrir
- `56ee349` add: cada categoria da Descobrir guarda a própria rolagem
- `4125a51` docs: override da Descobrir com o seletor e a espera do 429

## Notas
- Contrato (developer.themoviedb.org, via Context7):
  - `now_playing`: query `language`, `page` e `region` (ISO-3166-1); a resposta traz `dates` (`minimum`/`maximum`) além de `page`, `results`, `total_pages` e `total_results`. O `dates` é ignorado.
  - `top_rated`: mesma forma do `popular`. A região não é mandada, porque a nota não depende do país.
  - O parse é o mesmo das três listas (`_parsePage`), e o `region=BR` fica fixo no datasource.
- `ui-ux-pro-max`:
  - "Chip Collection Reflow" (ux): chips quebram linha em vez de cortar, então o seletor é `ChoiceChip` num `Wrap`, e não um `SegmentedButton`, que cortaria os três rótulos com fonte grande;
  - "Disabled States" (ux): o botão em espera fica desabilitado e visualmente distinto;
  - a stack Flutter não trouxe resultado para seletor nem para contagem (duas buscas). A contagem é padrão geral (fallback), anotado no override.
- Decisões de modelagem:
  - **`MovieRepository.byCategory(category, page:)`** substituiu o `popular(page:)`, sem método por lista.
  - **`DiscoverNotifier`:** o `current` só cria a lista, e quem carrega é o `select`. Um conjunto `_started` garante que cada categoria carrega uma vez só, mesmo que o `current` seja lido antes. Escolher a categoria já mostrada não notifica. O `dispose` descarta as listas.
  - **`RetryButton`:** a espera vem de `retryWaitOf(failure)`. O teto de 60 s impede que um `Retry-After` enorme (ou malicioso) trave o botão, e uma espera negativa vira zero. A contagem não é região viva do leitor de tela, para não anunciar a cada segundo. A tela passa `ObjectKey(failure)` para que cada falha nova recomece a contagem.
  - **Rolagem:** `PageStorageKey(category)` no `CustomScrollView`; o PageStorage da rota guarda o ponto de cada categoria.
- Testes: dois testes novos tiveram defeito no próprio teste (matcher dentro de record e lista comparada por identidade num record) e foram corrigidos antes do GREEN. O helper `loadFirstPage` da tela passou a carregar pelo `select`, como no app.
- Emulador (Medium Phone API 36):
  - **Populares, Em cartaz e Melhor avaliados** carregam pôsteres em pt-BR; Em cartaz traz os lançamentos brasileiros.
  - **Rolagem guardada:** quatro arrastos em Melhor avaliados, troca para Em cartaz e volta: a grade está no mesmo ponto.
  - **Fonte 1.5x:** os chips quebram linha e não há overflow nem exceção no log.
  - **Observação:** mesmo com fonte 1.0, num celular de 412dp os três chips ocupam duas linhas (o selecionado tem o ícone de check). Isso gasta uma linha da grade.
  - O 429 com `Retry-After` não dá para provocar no TMDB real; está coberto por testes de widget.
- Tríade antes do `/revisar`: `dart format` sem mudanças, `flutter analyze` sem issues, `flutter test` com 364 testes passando (eram 319) e `gitleaks` sem vazamentos.

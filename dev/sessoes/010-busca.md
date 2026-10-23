# Sessão 010 — Fase 1: busca de filmes

**Data**: 2026-10-23 · **Branch**: `feature/010-busca` · **Status**: aberta

## Objetivo
Trocar o placeholder da aba Buscar por uma busca de filmes (`/search/movie` com `include_adult=false`) com debounce de 400 ms, termo de 2 a 100 caracteres validado no domínio e paginação infinita. A tela tem os estados inicial, carregando, vazio, erro (com a espera do 429) e sucesso, e o app não guarda histórico de busca.

## Checklist
- [x] Contrato: conferir `/search/movie` na documentação oficial (Context7/web): query (`query`, `page`, `include_adult`, `language`, `region`, `year`) e campos da resposta
- [x] Design: consultar a `ui-ux-pro-max` (stack Flutter) para campo de busca, estado inicial e vazio; criar o override `pages/buscar.md`
- [x] Domínio: `SearchQuery` (trim, mínimo 2, máximo 100, falha tipada fora disso) — RED / GREEN / REFACTOR
- [x] Domínio: `MovieRepository.search(query, page:)` com a mesma guarda de página < 1 — RED / GREEN
- [x] Fixtures `search_movie_page1.json` e `search_movie_empty.json`
- [x] Datasource: `search/movie` com `query` e `include_adult=false`, e termo com acento/espaço/`&` codificado na URL — RED / GREEN / REFACTOR
- [x] Refactor: `PagedMoviesNotifier` vira base abstrata (`fetchPage`), com `CategoryMoviesNotifier` e `SearchResultsNotifier` (testes atuais verdes, refactor puro)
- [x] Refactor: estados da grade paginada saem da Descobrir para `PagedMoviesView` (`widgets/`), com `moviesLoading`/`moviesLoadMoreFailed` no ARB
- [x] Estado: `SearchNotifier` com debounce de 400 ms (relógio do `fakeAsync`), sem pedido para termo inválido, termo repetido ou vazio, e resposta de termo antigo descartada — RED / GREEN / REFACTOR
- [x] Estado: limpar o campo volta ao estado inicial e cancela o debounce; `dispose` cancela o timer — RED / GREEN
- [x] Tela Buscar: campo com limite de 100, botão de limpar com `Semantics`, estados inicial, carregando (skeleton), vazio com o termo, erro com `RetryButton` e sucesso com grade e paginação — RED / GREEN, com `textScaler` 1.5 numa tela de 320dp
- [x] Strings novas no ARB (dica do campo, inicial, vazio com o termo, limpar)
- [x] Composição: o router monta o `SearchNotifier` na aba Buscar e sai o placeholder dela
- [x] Política: conferir que a seção 3 (termos de busca vão ao TMDB, sem histórico no app) continua verdadeira
- [x] Tríade: `flutter analyze` limpo, `flutter test` verde e emulador (digitação, vazio, paginação e fonte grande)
- [x] `/revisar`: `code-reviewer` + `security-auditor` (a sessão toca rede e entrada do usuário)
- [ ] S2: teste da resposta atrasada confere que o estado continua no termo novo
- [ ] S1: lista descartada não faz pedido (`load` e próxima página) — RED / GREEN
- [ ] I1: trocar o termo não fura a espera do 429; o `SearchNotifier` adia o próximo pedido até o fim do `retryAfter` (teto de 60 s) — RED / GREEN / REFACTOR
- [ ] I2: vazio e "longo demais" da Buscar anunciados ao leitor de tela (`liveRegion`) — RED / GREEN
- [ ] S5: campo limita por code points (`TextInputFormatter`), e o "longo demais" fica de defesa — RED / GREEN
- [ ] S6: comentário do `onDrag` genérico no `PagedMoviesView`
- [ ] S7: override `buscar.md` sem a contradição sobre a rolagem do campo
- [ ] S8: `enableIMEPersonalizedLearning: false` no campo de busca — RED / GREEN
- [ ] S9: teste de injeção pelo termo (`x&include_adult=true` não muda o `include_adult`)

## Decisões
- [007](../decisoes/007-fake-async-nos-testes.md): `fake_async` em `dev_dependencies`, para testar o debounce sem relógio real.

## Commits
- `5873541` docs: abre sessão 010
- `7325c92` docs: override da Buscar
- `a43a4cb` add: termo de busca normalizado e com limites no domínio
- `5fe01a5` add: busca de filmes no datasource e no repositório, sem adultos
- `b73c7b0` refactor: PagedMoviesNotifier vira base abstrata e a categoria vai para CategoryMoviesNotifier
- `d1041b2` chore: fake_async como dependência de desenvolvimento (decisão 007)
- `0d1b5ba` add: SearchNotifier com debounce de 400 ms e uma lista de resultados por termo
- `7bf812f` refactor: estados da grade paginada saem da Descobrir para PagedMoviesView
- `b8fa9dc` add: tela Buscar com campo, debounce e os estados inicial, vazio, erro e longo demais
- `1b22341` add: aba Buscar monta o SearchNotifier no lugar do placeholder

## Notas
- Contrato (developer.themoviedb.org, via Context7): `GET /3/search/movie` com `query` (obrigatório), `include_adult` (padrão `false`), `language`, `page`, `primary_release_year`, `region` e `year`. A resposta tem a mesma forma das listas (`page`, `results`, `total_pages`, `total_results`), então o parse é o mesmo `_parsePage`. O app manda `query`, `page` e `include_adult=false` explícito (seção 11 da política, 13+); `language=pt-BR` já vem do `TmdbClient`.
- `ui-ux-pro-max`: "Input Labels" (rótulo visível), "No Results"/"Empty States" (vazio com sugestão), "Autocomplete" (resultado enquanto digita, com debounce) e, na stack Flutter, controller com `dispose` e slivers sem lista aninhada. "search field clear button" na stack Flutter veio vazio; o botão de limpar é fallback, anotado no override `pages/buscar.md`.
- Decisões de modelagem:
  - **`SearchQuery`:** apara, junta espaços repetidos (inclusive quebra de linha) e conta code points (`runes`), e não unidades UTF-16. Fora de 2–100, lança `InvalidSearchQuery` com o motivo (`tooShort`/`tooLong`). O `toString` não mostra o termo, para a busca não ir a log.
  - **Campo × domínio:** o `maxLength` do `TextField` conta caracteres visíveis, e o domínio conta code points. Um termo com acento combinante (`e` + `\u0301`) pode caber no campo e passar do domínio, e aí a tela mostra "Use até 100 caracteres na busca." (`SearchTooLong`), coberto por teste.
  - **Uma lista por termo:** cada termo novo cria um `SearchResultsNotifier` e descarta o anterior. Resposta atrasada de um termo antigo cai numa lista já descartada e some; a lista nova começa do topo (sem `PageStorageKey`).
  - **Debounce:** cada tecla reinicia os 400 ms; termo curto volta ao inicial na hora e cancela a espera; termo igual ao mostrado não pede de novo; a ação "buscar" do teclado pede na hora.
  - **`_withValid`:** o primeiro GREEN usava `null` como controle de fluxo no parse; o REFACTOR trocou por callback, como pede o `CLAUDE.md`.
- Testes:
  - os testes do `SearchNotifier` usam `fakeAsync` (decisão 007);
  - dois testes do datasource tinham matcher dentro de record (o mesmo defeito da sessão 009) e foram corrigidos antes do GREEN;
  - nos testes da tela, o notifier é criado pelo `ChangeNotifierProvider(create:)`, porque o `tearDown` roda depois da checagem de timers do `flutter_test`, e o debounce pendente reprovava o teste;
  - mutações: tirar o `maxLength` e tirar o `requestFocus` do limpar reprovam testes. O teste do foco foi reescrito, porque tocar no `IconButton` não tira o foco do campo, e o primeiro teste passava sem o `requestFocus`.
- Política: a seção 3.1 continua verdadeira. Os termos vão ao TMDB, e o app não guarda histórico, porque o termo vive só em memória enquanto a aba está montada. Nenhuma mudança na política.
- Emulador (Medium Phone API 36):
  - **Inicial:** lupa e convite; o campo tem o rótulo "Título do filme".
  - **Digitação:** "matrix" traz os pôsteres em pt-BR sem apertar "buscar", e o teclado mostra a ação de buscar.
  - **Paginação e teclado:** arrastar a grade fecha o teclado; a rolagem foi até a última página sem rodapé.
  - **Limpar e vazio:** limpar apaga o termo e volta ao inicial com o foco no campo; "qzxwvkjhq" mostra o vazio com o termo entre aspas e a sugestão.
  - **Fonte 1.5x:** "cidade de deus" carrega o skeleton e depois os pôsteres, sem overflow.
  - **Troca de aba:** Descobrir e volta mantém o termo e a grade.
  - Nenhuma exceção no log do `flutter run`.
  - **Observação visual:** com o campo sem foco e com texto, o rótulo flutuante fica meio para fora do fundo preenchido. É o `inputDecorationTheme` atual; fica para a revisão.
- Tríade antes do `/revisar`: `dart format` sem mudanças (86 arquivos), `flutter analyze` sem issues, `flutter test` com 453 testes passando (eram 371) e `gitleaks` sem vazamentos.

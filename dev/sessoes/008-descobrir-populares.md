# Sessão 008 — Fase 1: Descobrir, filmes populares

**Data**: 2026-10-23 · **Branch**: `feature/008-descobrir-populares` · **Status**: aberta

## Objetivo
Levar a lista de filmes populares (`/movie/popular`) do domínio até a aba Descobrir, com paginação infinita, os quatro estados e um pôster com placeholder. Junto entram a primeira feature em Clean Architecture (`features/movies`), o `provider` e o `cached_network_image`, a composição das dependências no `main.dart` e a política de privacidade passando a declarar o cache de imagens. Em cartaz e melhor avaliados ficam para a sessão 009.

## Checklist
- [x] Contrato: conferir `/movie/popular` na documentação oficial (Context7/web) e listar só os campos usados (`id`, `title`, `poster_path`, `release_date`, `vote_average`, `page`, `total_pages`)
- [x] Design: consultar a `ui-ux-pro-max` (stack Flutter) para a grade de pôsteres, o skeleton e a paginação; gerar override `pages/descobrir.md` se precisar
- [x] Dependências: `provider` e `cached_network_image` no `pubspec.yaml` (estão na stack do `CLAUDE.md`)
- [x] Entidades `Movie` e `MoviePage` (domain) — RED / GREEN / REFACTOR
- [x] Fixtures `movie_popular_page1.json` e uma degradada (`poster_path: null`, `release_date: ""`, `vote_average` int)
- [x] `MovieModel.fromJson` + `toEntity` com parse defensivo — RED / GREEN / REFACTOR
- [x] `MovieRemoteDataSource.popular(page)` sobre `TmdbClient` + `MockClient` (path e query certos, falhas repassadas) — RED / GREEN / REFACTOR
- [x] `MovieRepository` (contrato em domain) e implementação com paginação (`page`, `total_pages`, `hasMore`) — RED / GREEN / REFACTOR
- [x] Estado `PopularMoviesNotifier` (sealed: carregando, vazio, erro, sucesso), com carregar, carregar a próxima página (sem pedido duplicado nem além da última), falha na próxima página sem perder a lista e tentar de novo — RED / GREEN / REFACTOR por transição
- [x] Widget `MoviePoster`: 2:3, `w342`, placeholder desenhado sem `poster_path` e `Semantics` com o título — RED / GREEN
- [x] Tela Descobrir com os 4 estados (skeleton, vazio, erro com "Tentar de novo" e grade), mais o rodapé de carregando ou erro da próxima página — widget tests primeiro, e um teste com `textScaler` 1.5 sem overflow
- [x] Rolagem infinita: chegar perto do fim pede a próxima página — RED / GREEN
- [x] Emulador achou: com a janela ainda sem largura no primeiro layout, a grade estourava a asserção `crossAxisExtent > 0.0` — RED / GREEN
- [x] Strings novas no ARB (decisão 004), com chave de título própria `discoverTitle` (BACKLOG, revisão 006 item 7)
- [x] Composição: `AppConfig`, `http.Client`, `TmdbClient` e repositório montados no `main.dart` e injetados, com `main_test` usando um fake; rota Descobrir sem placeholder
- [x] `docs/PRIVACIDADE.md`: declarar o cache de imagens (prazo e como apagar) e remover o marcador da Fase 1 correspondente
- [x] Tríade: `flutter analyze` limpo, `flutter test` verde e emulador (os 4 estados, rolagem infinita e fonte grande)
- [ ] `/revisar`: `code-reviewer` + `security-auditor` (a sessão toca rede e composição de config)

## Decisões

## Commits

## Notas
- Contrato de `/movie/popular`, conferido em developer.themoviedb.org:
  - query: `page` (padrão 1) e `region` (opcional), além do `language`;
  - resposta: `page`, `results[]`, `total_pages` e `total_results`;
  - a especificação não marca nenhum campo como nulo, mas o parse é defensivo do mesmo jeito.
  - Não achei documentação oficial do limite de 500 páginas que a comunidade cita, então não há limite no código. Uma página recusada aparece como erro no rodapé.
- `ui-ux-pro-max` (stack Flutter):
  - trouxe builder em listas, `cached_network_image`, carregamento sem piscar com status acessível e respeito ao "reduzir movimento";
  - não trouxe nada sobre paginação infinita, então as regras de rodapé são o padrão geral (fallback), anotado no override `pages/descobrir.md`.
- O override define a célula com no máximo 180dp de largura, o que dá 3 colunas num celular de 412dp, e o pulso do skeleton em 1200 ms. No código, isso virou `AppSizes.posterGridMaxExtent` e `AppMotion` (`lib/core/theme/`).
- Dependências: `provider` e `cached_network_image`, as duas na stack do `CLAUDE.md`. O `cached_network_image` traz junto 39 transitivas, entre elas `flutter_cache_manager` 3.4.5, `sqflite` e `path_provider`. O cache padrão guarda no máximo 200 imagens e descarta cada uma depois de 30 dias parada. As imagens ficam no diretório temporário e o índice no diretório de suporte do app. Isso foi declarado na política 0.3, e o marcador `A REVISAR` da Fase 1 saiu.
- Decisões de modelagem:
  - **`MovieModel`:**
    - um item sem `id` lança `FormatException`, e o datasource o descarta sem derrubar a página;
    - sem `title`, usa o `original_title`;
    - data vazia ou impossível (ex.: "2023-13-45") vira nula;
    - nota inteira vira double;
    - um `poster_path` fora do formato vira "sem pôster".
  - **`TmdbImageUrl`:** o host das imagens é fixo no código e o caminho é validado (começa com `/`, sem `//`, `.` nem `..`). Assim um JSON malicioso não leva a imagem para outro servidor.
  - **`MovieRepository`:** começa com `popular(page)` e recusa página menor que 1 com `RangeError`, sem chamar o TMDB. A lista acumulada fica no notifier.
  - **`PopularMoviesNotifier`:**
    - nunca pede em dobro, nem a primeira página nem a seguinte;
    - não pede além da última página;
    - quando a próxima página falha, mantém a lista e marca o rodapé com `NextPageStatus.failed`;
    - descarta filme repetido entre páginas, porque a popularidade muda entre os pedidos;
    - não notifica depois de descartado.
  - **`failureMessage`** (`core/l10n`) lista cada falha explicitamente, sem `_`. Uma falha nova obriga a escolher a mensagem dela.
- Montagem: o `main.dart` monta `AppConfig.fromEnvironment` → `TmdbClient` → `MovieRemoteDataSource` → `TmdbMovieRepository`. O `createAppRouter` recebe o repositório e cria o `PopularMoviesNotifier` na branch Descobrir, que o `StatefulShellRoute` mantém viva entre as trocas de aba. Os testes do app inteiro usam o `StubMovieRepository` (lista vazia na hora), para o skeleton não animar no `pumpAndSettle`.
- Testes de widget com `cached_network_image`: confere-se só a `imageUrl`. O app não faz `pumpAndSettle` com imagem de rede, e por isso não houve erro de plugin.
- Emulador (Medium Phone API 36):
  - **Config:** o `env/dev.json` estava sem `TMDB_READ_ACCESS_TOKEN`, e o app parava na tela de abertura do Flutter sem nenhuma mensagem (`ConfigException` antes do `runApp`). O usuário preencheu o token. A chave entrou no arquivo por script que imprime só os nomes das chaves, sem abrir o conteúdo na conversa.
  - **Bug encontrado:** asserção `crossAxisExtent > 0.0` no `GridView` do skeleton durante o primeiro layout. Ganhou teste (largura de 20dp) e correção (`_GridWidthGuard`).
  - **Sucesso:** grade de 3 colunas com os pôsteres em pt-BR. Seis arrastos longos carregaram várias páginas sem nenhum erro no log.
  - **Erro:** em modo avião, com fonte 1.3x, aparece "Sem conexão com a internet. Confira sua rede." e "Tentar de novo", sem vazar. Ao reconectar e tocar o botão, a grade volta.
  - **Acessibilidade:** a árvore expõe o título de cada pôster ("A Odisseia", "Street Fighter"…) e "Guia N de 4" nas abas.
  - O skeleton e o rodapé da próxima página foram rápidos demais para a captura. Os dois estão cobertos por testes de widget.
- Tríade antes do `/revisar`: `flutter analyze` sem issues e `flutter test` com 300 testes passando (eram 239).
- Para o BACKLOG:
  - tela de "configuração inválida" em debug, para não ficar parado na tela de abertura;
  - transição animada entre os estados (o `MASTER.md` pede que a mudança de estado não seja instantânea);
  - puxar para atualizar a Descobrir.

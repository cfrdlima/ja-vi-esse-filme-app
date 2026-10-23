# Sessão 011 — Fase 1: detalhes do filme

**Data**: 2026-10-23 · **Branch**: `feature/011-detalhes-filme` · **Status**: aberta

## Objetivo
Tocar num pôster da Descobrir ou da Buscar abre os detalhes do filme numa rota dentro da própria aba (`/descobrir/filme/:id` e `/buscar/filme/:id`). A tela mostra sinopse (com o texto original quando a de pt-BR vier vazia), gêneros, duração, nota, data e até 15 pessoas do elenco, e tem os 4 estados. O pedido é um só: `/movie/{id}` com o elenco anexado.

## Checklist
- [x] Contrato: conferir `/movie/{id}` e `append_to_response` (`credits`, e o que trazer para a sinopse original) na documentação oficial (Context7/web): campos nulos, `runtime`, `genres`, `cast` (`order`, `character`, `profile_path`)
- [x] Design: consultar a `ui-ux-pro-max` (stack Flutter) para tela de detalhe, elenco horizontal e textos longos; criar o override `pages/detalhes.md`
- [x] Domínio: `MovieDetails` e `CastMember`, com o teto de 15 pessoas no domínio — RED / GREEN / REFACTOR
- [x] Domínio: `MovieRepository.details(id)`, recusando id < 1 sem chamar o TMDB — RED / GREEN
- [x] Fixtures `movie_details_*.json` (completo, com campos nulos/vazios e com sinopse pt-BR vazia)
- [x] Datasource + model: parse defensivo (`runtime` nulo ou 0, `release_date` vazio, `genres`/`cast` ausentes, item de elenco quebrado), elenco pela `order` e cortado em 15 — RED / GREEN / REFACTOR
- [x] Sinopse: fallback para o texto original quando a de pt-BR vier vazia — RED / GREEN
- [x] Formatação pt-BR (`intl`, decisão 005): duração ("2 h 15 min"), data e nota ("7,8"), na `presentation` — RED / GREEN
- [x] Estado: `MovieDetailsNotifier` (carregando, erro com a falha, sucesso; 404 como estado próprio) — RED / GREEN / REFACTOR
- [x] Tela de detalhes: 4 estados (skeleton, "filme não encontrado", erro com `RetryButton`, sucesso), pôster com placeholder, elenco horizontal com foto ou placeholder e `Semantics` — RED / GREEN, com `textScaler` 1.5 numa tela de 320dp
- [x] Rotas: `filme/:id` como sub-rota (`routes:` do `firstTabBranch`/`tabBranch`, que já existe) dentro de Descobrir e Buscar, id inválido vai para "não encontrado", e o voltar retorna à grade com a rolagem e não cai na regra do voltar da raiz da aba — RED / GREEN
- [x] Pôster tocável na grade (alvo ≥ 48dp, `Semantics` de botão) que abre os detalhes da aba atual — RED / GREEN
- [x] Strings novas no ARB (títulos de seção, duração, nota, "não encontrado", elenco, sem sinopse)
- [x] Tríade: `flutter analyze` limpo, `flutter test` verde e emulador (abrir pelas duas abas, voltar, filme sem pôster/sinopse, fonte grande)
- [x] `/revisar`: `code-reviewer` + `security-auditor` (a sessão toca rede e rota com parâmetro)
- [ ] I1: provider dos detalhes com `key` pelo id, para ir de `filme/1` a `filme/2` trocar o filme (o `pageKey` do go_router é o caminho-padrão) — RED / GREEN
- [ ] I2: testes de fonte 1.5x dos detalhes numa tela de fato de 320dp (`tester.view`) — RED / GREEN
- [ ] S1: id da rota só em base 10 (`0x1F` vai para "não encontrado") — RED / GREEN
- [ ] S2: teste do notifier descartado registra um ouvinte e confere que ele não é chamado
- [ ] S3: teste de dados ausentes procura o texto exato de data e duração
- [ ] S4: título do filme no cabeçalho marcado como cabeçalho para o leitor de tela — RED / GREEN
- [ ] S5: skeleton dos detalhes com a mesma largura máxima do conteúdo (640dp) — RED / GREEN

## Decisões
- [008 — Sinopse original via `append_to_response=translations`](../decisoes/008-sinopse-original-via-translations.md)

## Commits

## Notas
- Contrato (Context7): `/movie/{id}` aceita `append_to_response` com até 20 itens. Com `language=pt-BR`, o `overview` vem vazio quando o filme não tem tradução, e a sinopse original só vem nas traduções. Daí a decisão 008: `append_to_response=credits,translations`.
- Design: override `pages/detalhes.md`. Sem `Hero`, porque as páginas do TMDB podem repetir um filme e duas tags iguais quebram a transição. O elenco é uma `Row` num scroll horizontal (no máximo 15 itens, com altura que acompanha a fonte grande), e não um `ListView.builder`.
- Ordem: o repositório saiu depois do model e do datasource, porque o teste dele monta o datasource real com `MockClient`.
- Refactors, todos com os testes verdes antes e depois:
  - `TmdbJson`: as leituras defensivas saíram do `MovieModel` e servem aos dois models;
  - `SkeletonPulse`: o pulso saiu da grade e serve também ao skeleton dos detalhes;
  - `AppRoutes` foi para `app_routes.dart`, para as telas navegarem sem importar o router, que importa as telas. Esse refactor entrou no mesmo commit do toque no pôster (`d9a1ce0`), em vez de ir num commit próprio.
- Formatação: a nota e a data saem direto do ARB (`decimalPatternDigits` e `yMd`), e só a duração tem função própria (`formatRuntime`). Os wrappers de nota e data, sem regra, saíram no REFACTOR.
- Id da rota: o `int.tryParse` da rota manda `null` para o que não é número, e o notifier trata `null` e id < 1 como "não encontrado", sem pedido ao TMDB. Testado com `abc`, `0`, `-1`, `7.5` e um número maior que 64 bits.
- Testes:
  - o desempate do elenco pelo índice só aparece com mais de 32 pessoas, porque o `sort` do Dart é estável por inserção até 32. Por isso o teste usa 40;
  - um record com listas comparou por identidade (o mesmo defeito das sessões 009 e 010), e o teste foi separado em dois antes do GREEN;
  - mutações pegas: o desempate do elenco, a pessoa sem `order` no fim, as guardas do notifier (pedido em andamento, id < 1, emitir depois do `dispose`), a nota sem guarda e sem rótulo, o card sem `excludeSemantics` e o "tentar de novo" no 404;
  - uma sonda temporária confirmou que o teste da rolagem rola de fato (280 px), abre os detalhes e volta à mesma posição.
- Emulador (Medium Phone API 36):
  - **Descobrir:** tocar num pôster abre os detalhes com a barra das abas visível. O voltar do sistema devolve a grade na mesma rolagem (captura idêntica à de antes de abrir).
  - **Buscar:** "cidade de deus" e depois um pôster abrem os detalhes na aba Buscar. A seta da barra volta à grade com o termo intacto, e o elenco rola na horizontal.
  - **Dados:** a data sai em dd/MM/aaaa, a duração em "2 h 10 min" e "52 min", a nota em "8,4". O título longo leva reticências na barra e quebra linha no cabeçalho.
  - **Fonte 1.5x:** sem overflow, e os gêneros quebram linha. O nome no elenco quebrava no meio da palavra ("Fernand / o Meir…"), porque o card tinha 96dp fixos. Isso foi corrigido em dois passos:
    1. o card passou a crescer com a fonte, mas o `scale(96)` não mudou nada no aparelho, porque o Android 14 escala a fonte de forma não linear e trata 96 como um tamanho grande;
    2. o fator passou a vir do tamanho da fonte do nome (`bodyMedium`), com um teste que usa um `TextScaler` não linear.
  - **Erro:** com o modo avião, aparece "Sem conexão com a internet" e o "Tentar de novo"; com a rede de volta, o toque carrega o filme.
  - **Não conferido no aparelho:** a sinopse do idioma original, porque não achei um filme sem sinopse pt-BR, e o "não encontrado", que só se alcança por URL. Os dois ficam cobertos pelos testes de model, de rota e de tela.
  - Nenhuma exceção nem overflow no log do `flutter run`.
  - **Observação:** o personagem vem do TMDB sem tradução ("Himself", "Herself"). É dado do TMDB, e não do app.
- Tríade antes do `/revisar`: `dart format` sem mudanças (106 arquivos), `flutter analyze` sem issues, `flutter test` com 573 testes passando (eram 473) e `gitleaks` sem vazamentos.

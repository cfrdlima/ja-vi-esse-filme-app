# Sessão 030 — Fase 4: acessibilidade e fonte grande

**Data**: 2026-11-22 · **Branch**: `feature/030-acessibilidade-fonte-grande` (empilhada na `feature/029-listas-personalizadas`) · **Status**: aberta

## Objetivo
Garantir, com testes, que todas as telas do app cumprem o checklist de acessibilidade do `MASTER.md`: alvos de toque ≥ 48dp, rótulos nos clicáveis, contraste AA e fonte grande (escala 1.5 e 2.0, o máximo do Android) sem overflow. As lacunas encontradas são corrigidas em ciclos TDD, e a verificação final é feita no emulador com o TalkBack e a fonte no máximo.

## Checklist
### Preparação
- [x] Auditoria: tabela tela × guideline (`androidTapTargetGuideline`, `labeledTapTargetGuideline`, `textContrastGuideline`) × escala (1.5 e 2.0), marcando o que já tem teste e o que falta. Hoje: guidelines só no roteador, Sobre, Perfil, pôster e botão do Google; escala em 12 arquivos de teste. **Feito:** sonda temporária (apagada) com as três guidelines em 360 e 320dp, escala 1.0 e 2.0: tudo passou, sem overflow. Detalhes em Notas
- [ ] Consultar a `ui-ux-pro-max` (stack Flutter) sobre acessibilidade mobile (leitor de tela, ordem de foco, fonte grande e movimento reduzido); override em `pages/` se precisar
- [x] Decidir se a escala 2.0 entra no `MASTER.md` como piso de teste no lugar da 1.5 (se mudar a regra, `/decisao`). **Feito:** decisão 020, com 2.0 em 320dp e as três guidelines em toda tela, por um ajudante comum
- [x] Ajudante de teste compartilhado para as guidelines e a escala, se a auditoria mostrar repetição (Refactor, sem mudar comportamento). **Feito:** `test/helpers/accessibility.dart` com `useNarrowPhone`, `useLargeFont`, `largeFont` e `expectAccessible`, testado em `accessibility_test.dart`

### Guidelines por tela (RED/GREEN/REFACTOR por tela)
- [x] Descobrir: alvos, rótulos e contraste nos estados de sucesso, vazio e erro. **Feito:** caracterização validada com o chip encolhido (alvo) e o `Wrap` trocado por `Row` (vazamento)
- [x] Buscar: campo, botão de limpar e resultados; estados vazio e erro. **Feito:** inicial, sucesso, vazio com termo longo, erro e termo longo demais; validada sem o `tooltip` do limpar
- [x] Detalhes: cabeçalho, marcas, "Adicionar à lista", elenco e trailers. **Feito:** tela deslogada (carregando, sucesso, fim com elenco e trailers, sem dados, erro e não encontrado), marcas, diário e folha. O calendário do diário não tem 48dp por dia abaixo de cerca de 392dp; o usuário escolheu a exceção registrada na decisão 020. Os hosts dos testes de widget ganharam a margem dos Detalhes, porque a guideline de alvo ignora o que encosta na borda (a quebra dos chips das marcas passava sem a margem)
- [x] Estante: as 4 abas, a barra de marcas e o diário. **Feito:** convite, filmes com cópia vencida, vazio, erro e Listas cheia e vazia; validada sem o rótulo do pôster e com o menu da lista encolhido. Barra de marcas e diário vão com os Detalhes
- [x] Tela da lista: linhas, menu, desfazer e diálogos de renomear e apagar. **Feito, com a primeira falha real:** o aviso com "Desfazer" vazava 0,8px e o de falha com "Tentar de novo" 169px, com a fonte 2x em 320dp. O `SnackBarAction` do Flutter 3.47 mede o rótulo sem a escala e põe a ação numa `Row` sem limite. Correção: `actionSnackBar` (`core/widgets`), com `Wrap`, `persist` e toque único, usado no desfazer e no `runWithNotice`
- [ ] Folhas e diálogos: login, "Adicionar à lista", apagar a conta, sair com escrita pendente, desmarcar

### Fonte grande (RED/GREEN/REFACTOR por tela)
- [ ] Escala 2.0 sem overflow em cada tela e estado que hoje só tem 1.5 ou nada
- [ ] Skeleton dos detalhes com a altura da linha de texto escalada (BACKLOG, revisão da 011, S6)

### Leitor de tela
- [ ] `MoviePoster` com rótulo opcional, sem o cabeçalho dos detalhes montar um `Movie` ou cobrir o `Semantics` (BACKLOG, revisão da 011, S7)
- [ ] Rótulos sem duplicar a leitura (ícone + texto lidos duas vezes) e estados anunciados (marcado, selecionado, carregando)
- [ ] Movimento reduzido (`MediaQuery.disableAnimations`) respeitado nos skeletons e transições

### Fechamento
- [ ] Verificação no emulador: TalkBack nas telas principais e fonte no máximo das configurações, com screenshots via MCP do Flutter
- [ ] `flutter analyze` limpo e `flutter test` verde
- [ ] Atualizar `MASTER.md`/`docs/DESIGN.md` se alguma regra mudar e marcar o item no `PLANO.md`
- [ ] `/revisar`

## Decisões
- [020 — Piso de acessibilidade nos testes: escala 2.0 em 320dp e guidelines em toda tela](../decisoes/020-piso-de-acessibilidade-nos-testes.md)

## Commits

## Notas
### Auditoria (2026-11-22)
Sonda temporária, fora do commit, com `androidTapTargetGuideline`, `labeledTapTargetGuideline` e `textContrastGuideline` e a captura de exceção de layout, em tela de 360 e 320dp, com escala 1.0 e 2.0. Cobertura: Descobrir, Buscar, Detalhes (fixture `movie_details_full.json`), Estante deslogada, Perfil deslogado e logado, Sobre, Estante logada (Assistidos com cópia vencida, vazio, erro, Listas cheia e vazia), tela da lista (com filmes, vazia, menu e os diálogos de renomear e apagar), marcas com nota e o diálogo de desmarcar, a folha "Adicionar à lista" e o diálogo de excluir a conta.

**Resultado: nenhuma falha.** (Corrigido depois: a sonda não abria `SnackBar`, e os avisos com ação vazavam com a fonte 2x; ver o checklist da tela da lista.) O que as sessões anteriores fizeram tela a tela já cumpre as guidelines. O que falta é **teste de regressão**: hoje as guidelines só estão no roteador (Descobrir vazio), no Sobre (contraste), no Perfil, no pôster e no botão do Google, e a escala 2.0 em 320dp não é testada na maioria das telas.

Fora do alcance das guidelines (para o emulador e para os itens do BACKLOG):
- S6: as barras do skeleton dos detalhes têm `tokens.spacing.md` de altura, que não cresce com a fonte (`movie_details_skeleton.dart:107`).
- S7: o cabeçalho dos detalhes monta um `Movie` para usar o `MoviePoster` e cobre o `Semantics` dele com outro (`movie_details_content.dart:99-113`).
- Movimento reduzido: o pôster, o Hero, o skeleton, o elenco e a conta respeitam o `disableAnimations`. Faltam o `FadeTransition` do skeleton dos detalhes e as transições de página do `go_router`, que precisam ser conferidos.
- Regiões vivas: o vazio e o erro usam o `MoviesMessage` (com `liveRegion`) também na Estante e nas Listas. O aviso de escrita (`write_notice.dart`) precisa ser conferido.
- A ordem de leitura e a leitura duplicada só aparecem no TalkBack.
- Ruído: o `cached_network_image` lança `MissingPluginException` (`path_provider`) quando a tela monta pôster com URL nos testes. Não afeta as guidelines, mas um ajudante comum precisa do pôster sem rede ou de um cache fake.

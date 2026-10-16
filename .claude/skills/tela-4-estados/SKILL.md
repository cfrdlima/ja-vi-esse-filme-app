---
name: tela-4-estados
description: Receita para construir ou alterar uma tela Flutter deste app com os quatro estados obrigatórios (carregando, vazio, erro, sucesso), tokens do tema, acessibilidade e widget tests. Use ao criar ou mexer em qualquer tela ou componente visual.
---
# Tela com os 4 estados

1. **Leia `design-system/ja-vi-esse-filme/pages/<tela>.md` se existir; senão, o `MASTER.md`. Siga também as regras de `docs/DESIGN.md`** e use só os tokens de `core/theme/` (`Theme.of(context)`, `ThemeExtension`). Proibido `Color(0x…)`, `TextStyle(fontSize: …)` ou espaçamento mágico no widget.
2. **Widget tests primeiro** (um por estado), injetando o estado/fake:
   - carregando → mostra skeleton (não um `CircularProgressIndicator` solto no meio da tela);
   - vazio → mensagem útil + ação (ex.: "Buscar filmes");
   - erro → mensagem amigável (nunca a exceção crua) + botão "Tentar de novo" que dispara a ação;
   - sucesso → conteúdo renderizado.
3. **Estrutura** — a tela faz `switch` exaustivo no estado selado e delega cada estado a um widget próprio (`_LoadingView`, `_EmptyView`… como classes, não métodos `_buildX`).
4. **Pôsteres** — proporção 2:3, `cached_network_image` com tamanho de imagem do TMDB adequado (`w342` em grade, `w500` em detalhes) e placeholder desenhado quando `posterPath == null`.
5. **Acessibilidade** — `Semantics(label: …)` em pôster e ícone clicável; alvo de toque ≥ 48dp; testar com `textScaler` 1.5 sem overflow (inclua um widget test para isso).
6. **Validação visual** — rode no emulador; se o MCP do Flutter estiver ativo, tire screenshot de cada estado e compare com o `MASTER.md`/override da tela. Para tela nova, consulte a `ui-ux-pro-max` (stack Flutter) antes de codar.
7. `flutter analyze` + `flutter test` verdes.

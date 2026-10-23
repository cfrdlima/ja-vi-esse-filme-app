# Sessão 012 — Fase 1: Hero do pôster

**Data**: 2026-10-23 · **Branch**: `feature/012-hero-poster` · **Status**: aberta

## Objetivo
Tocar num pôster da grade (Descobrir ou Buscar) leva o pôster voando até o lugar dele nos detalhes, com um `Hero` de tag única dentro do navigator da aba. A transição precisa achar o pôster de destino já no primeiro quadro, enquanto os detalhes ainda carregam, e respeitar o movimento reduzido.

## Checklist
- [x] Investigar: o `go_router` 18.1.0 dá um `HeroController` aos navigators do `StatefulShellRoute`? Confirmar no código do pacote antes do RED
- [x] Investigar: as tags podem colidir? Hoje o `PagedMoviesNotifier` já tira ids repetidos da grade, só uma grade da Descobrir fica montada por vez e cada aba tem o seu navigator. Registrar a conclusão no override `pages/detalhes.md`
- [x] Design: consultar a `ui-ux-pro-max` (stack Flutter) sobre a transição de pôster e atualizar a seção "Transição" de `pages/detalhes.md` e o MASTER, se for o caso
- [x] Tag do Hero num lugar só (`PosterHero`, que também cuida do movimento reduzido), sem a string repetida nas duas telas — RED / GREEN
- [x] Pôster da grade dentro de um `Hero` com a tag do filme — RED / GREEN
- [x] Detalhes com o pôster de destino já no estado carregando: levar o `Movie` da grade para a rota (`extra` do go_router) e mostrar o pôster enquanto o resto carrega (o título ficou de fora: só o pôster voa); sem `extra` (URL direta), cai no skeleton atual — RED / GREEN
- [x] Pôster de destino continua o mesmo `Hero` no estado de sucesso (com a mesma `GlobalKey` do skeleton, para o voo não perder o destino quando o filme chega); erro e "não encontrado" ficaram sem pôster (ver Notas) — RED / GREEN
- [x] Teste de transição: tocar no pôster da grade gera um voo de Hero (widget test com `pump` no meio da rota) e o voltar também — RED / GREEN
- [x] Movimento reduzido: com `disableAnimations`, sem voo (troca direta) — RED / GREEN
- [x] Semântica: o Hero não duplica o pôster para o leitor de tela durante o voo
- [x] Tríade: `flutter analyze` limpo, `flutter test` verde e emulador (Descobrir e Buscar, ida e volta, teclado aberto, movimento reduzido; filme sem pôster e fonte grande ficaram nos testes, ver Notas)
- [x] Rota de detalhes como `MaterialPage` explícita: o go_router não reconhecia o `MaterialApp` e montava páginas sem transição — RED / GREEN
- [x] Shell sem `resizeToAvoidBottomInset`, e a aba recebe só a parte do teclado acima da barra — RED / GREEN
- [x] Pôster decodificado no tamanho do arquivo, para o voo usar a imagem do cache — RED / GREEN
- [x] `/revisar`: `code-reviewer` e `security-auditor` (a sessão mexe na rota com parâmetro, no `extra`)
- [ ] C3: preview sem `posterPath` mostra o placeholder no skeleton, dentro do `PosterHero` e sem `PosterSkeleton` — RED / GREEN
- [ ] C4: teste de voo do router com a faixa de tamanhos independente da ordem (`min`/`max`)
- [ ] C6: renomear `poster` para `preview` no `MovieDetailsSkeleton`, o mesmo nome da tela e da rota — REFACTOR

## Decisões

## Commits
- 6bb425b fix: aba recebe só a parte do teclado acima da barra das abas
- 24735a9 fix: shell não encolhe com o teclado, e o pôster voa sem esticar
- 5e67e94 fix: detalhes como MaterialPage, com transição e voo do Hero
- d5bff7e fix: pôster decodificado no tamanho do arquivo, para o Hero voar com a imagem do cache
- 9d917ed test: leitor de tela lê o pôster uma vez só durante o voo
- ca372b1 fix: pôster segue voando quando os detalhes chegam no meio da transição
- 08fdded fix: extra de outro id não vira o pôster dos detalhes
- a01c5fb add: filme tocado na grade vai para os detalhes pelo extra da rota
- c669a68 add: pôster dos detalhes no PosterHero, e no carregando quando a grade manda o filme
- 78e43db add: pôster da grade dentro do PosterHero
- 6b6608c add: PosterHero com a tag do filme e sem voo no movimento reduzido
- d8f8c9c docs: abre sessão 012

## Notas
- **Investigação:**
  - o go_router 18.1.0 dá um `HeroController` a cada navigator (`builder.dart:224`), mas cria um `HeroController()` simples, sem o arco do Material, porque não reconhece o `MaterialApp` (ver abaixo);
  - as tags não colidem: o `PagedMoviesNotifier` tira os ids repetidos, a Descobrir monta uma grade por vez e cada aba tem o seu navigator.
- **Design:** consultei a `ui-ux-pro-max` (stack Flutter "Use Hero for transitions"; `ux` "Excessive Motion" e "Reduced Motion") e atualizei a seção "Transição" do `pages/detalhes.md`. O `MASTER.md` já pedia o `Hero(tag: 'poster-<id>')`.
- **Destino no primeiro quadro:** a grade passa o `Movie` pelo `extra`, e o skeleton mostra o pôster real. Um `extra` com outro id é ignorado; pela URL direta, a tela abre sem voo.
- **Achados do emulador (Medium Phone API 36),** cada um com um teste RED antes da correção:
  1. **Placeholder em voo:** o pôster voava como placeholder, porque grade, voo e cabeçalho decodificavam em larguras diferentes (`memCacheWidth`), cada uma com a sua entrada no cache. O usuário escolheu decodificar no tamanho do arquivo (`w342`). Neste celular a célula já tem ~341 px, então o custo de memória quase não muda; numa tela estreita, cada pôster gasta até ~40% a mais.
  2. **Sem transição nenhuma:** o go_router 18.1.0 procura o `MaterialApp` do pacote `material_ui` (`pages/material.dart`), não acha o do `flutter/material.dart` e monta `NoTransitionPage` com duração zero. Isso vem da sessão 004: nenhuma rota animava, e o widget test com `MaterialPageRoute` direto não pegava. A rota de detalhes passou a usar `pageBuilder` com `MaterialPage` (registrado no BACKLOG).
  3. **Pôster esticado com o teclado:** com o teclado aberto na Buscar, o voo saía alto demais (no teste, a altura ia de 180 para 374). O Hero posiciona o voo em relação ao tamanho do navigator no início, e o `Scaffold` do shell esticava esse navigator quando o teclado fechava. O shell deixou de encolher (`resizeToAvoidBottomInset: false`).
  4. **Vão em cima do teclado:** consequência do item 3. A tela desviava do teclado inteiro, a partir de um corpo que já termina acima da barra das abas. O `_KeyboardAboveNavigationBar` passa à aba só a parte do teclado que cobre o corpo.
- **Fora da sessão:** erro e "não encontrado" não mostram pôster, então o voltar desses estados usa só a transição da rota. Pôr o pôster neles mudaria o layout dos dois estados.
- **Testes que passaram sem código novo**, ficando como guarda de regressão:
  - o voo de volta;
  - a semântica no voo (o Flutter esconde a origem e o destino com `Offstage`, e o leitor de tela lê o pôster uma vez só).
- **Emulador:**
  - **Descobrir:** o pôster sobe da célula até o cabeçalho já com a imagem, e o skeleton dá lugar ao conteúdo sem pular. O voltar devolve o pôster à célula.
  - **Buscar:** com o teclado aberto, a grade vai até o teclado e o voo mantém o 2:3.
  - **Movimento reduzido:** com o `transition_animation_scale` em 0, a troca é direta, sem voo, e o pôster já está no skeleton. O `animator_duration_scale` não conta: o Flutter no Android lê só o `transition_animation_scale`.
  - Nenhuma exceção nem overflow no log do `flutter run`.
- **Tríade antes do `/revisar`:** `dart format` sem mudanças (108 arquivos), `flutter analyze` sem issues, `flutter test` com 603 testes passando (eram 581) e `gitleaks` sem vazamentos.
- **Não conferido no aparelho:**
  - **filme sem pôster:** o placeholder voa como qualquer outro filho de `Hero`, e os testes de `PosterHero` e do skeleton cobrem o caso;
  - **fonte grande:** o pôster do cabeçalho tem largura fixa de 120dp e não muda com a fonte.
- **Revisão (`code-reviewer` e `security-auditor`):** nada bloqueante nem importante, e os dois aprovaram fechar a sessão.
  - O `code-reviewer` confirmou com mutações que três testes novos pegam regressão de fato: o shell que encolhe com o teclado, o conteúdo sem `posterKey` e o `memCacheWidth` de volta.
  - O auditor concluiu que o `extra` não abre nenhum vetor: não há deep link de VIEW, não há restauração nem `extraCodec`, o `posterPath` já foi validado pelo `TmdbJson.imagePath` e o host é fixo. A política de privacidade não muda.
  - O usuário escolheu tratar C3, C4 e C6 nesta sessão; C1, C2, C5, C7 e A1 foram para o BACKLOG.

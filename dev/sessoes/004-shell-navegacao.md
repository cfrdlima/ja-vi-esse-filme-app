# Sessão 004 — Fase 0: shell de navegação com go_router

**Data**: 2026-10-16 · **Branch**: `feature/004-shell-navegacao` · **Status**: aberta

## Objetivo
Montar a navegação do app com `go_router`: um `StatefulShellRoute` com `NavigationBar` de 4 abas (Descobrir · Buscar · Estante · Perfil), cada aba com sua pilha preservada, e `MaterialApp.router` no `main.dart`. As abas mostram um placeholder até as telas reais chegarem na Fase 1.

## Checklist
- [x] Consultar a `ui-ux-pro-max` (stack Flutter) sobre navegação por abas; gerar override em `pages/` só se surgir regra específica
- [x] Confirmar a API atual do `go_router` (Context7): `StatefulShellRoute.indexedStack`, `goBranch`, `errorBuilder`
- [x] Dependência `go_router` no `pubspec.yaml` (já aprovada na stack do `CLAUDE.md`)
- [x] Shell — RED: o app abre em Descobrir com a `NavigationBar` de 4 destinos e rótulos em PT-BR
- [x] Shell — GREEN
- [x] Abas — RED: tocar um destino mostra a tela da aba e marca o destino como selecionado
- [x] Abas — GREEN
- [x] Pilha por aba — RED: trocar de aba e voltar mantém o estado da aba anterior (`indexedStack`)
- [x] Pilha por aba — GREEN
- [x] Aba ativa — RED: tocar o destino já selecionado volta para a raiz da aba
- [x] Aba ativa — GREEN
- [x] Rota desconhecida — RED: mostra "página não encontrada" com ação para voltar a Descobrir
- [x] Rota desconhecida — GREEN
- [x] Voltar — RED: o botão voltar do Android numa aba que não é Descobrir leva a Descobrir em vez de fechar o app
- [x] Voltar — GREEN
- [x] Acessibilidade — RED: destinos com rótulo semântico e `textScaler` 1.5 sem overflow na barra
- [x] Acessibilidade — GREEN
- [x] `main.dart` — RED/GREEN: `MaterialApp.router` com o router montado em um ponto só; testes do `main_test.dart` seguem verdes
- [x] REFACTOR: nomes, rotas como constantes, widgets pequenos
- [x] Voltar — RED/GREEN: o aviso `setFrameworkHandlesBack` ao Android fica `true` fora de Descobrir (predictive back), achado na verificação no emulador
- [x] Tríade: `flutter analyze` limpo, `flutter test` verde, verificação no emulador (screenshot de cada aba)
- [x] `/revisar` com `code-reviewer` (sem auth/rede/storage; `security-auditor` só se entrar deep link)
- [x] Revisão A — RED/GREEN: no router real, o aviso ao Android e o voltar até Descobrir testados em Buscar, Estante e Perfil (itens 2 e 4)
- [x] Revisão A — RED/GREEN: aviso certo ao revisitar uma aba já carregada (item 4)
- [x] Revisão B — REFACTOR: `PopScope` do shell só com `canPop`, sem o `goBranch` que mascarava wrapper esquecido; mutação confirma que os testes de voltar pegam (item 3)
- [x] Revisão C — REFACTOR: o router aplica o `BackToFirstTab` por helpers de branch, e o router de teste usa os mesmos helpers (itens 1 e 7)
- [x] Revisão D — RED/GREEN: semântica de cada aba conferida direto; teste parametrizado de troca de aba sem `if` no Arrange (itens 5 e 6)

## Decisões

## Commits
- `d3e70b2` docs: abre sessão 004
- `990664a` chore: adiciona a dependência go_router
- `5017b31` test: shell abre em Descobrir com as 4 abas
- `3bda1c4` add: shell de navegação com StatefulShellRoute e NavigationBar
- `aba7a4e` test: tocar uma aba mostra a tela dela e marca o destino
- `a7280dd` add: abas mostram tela provisória com título e aviso de em breve
- `d8a7a59` test: aba mantém o estado ao trocar e voltar
- `72ec462` test: tocar a aba ativa volta para a raiz dela
- `04e08a3` add: tocar a aba ativa volta para a raiz dela
- `b18db2a` test: rota desconhecida mostra página não encontrada
- `3b040c7` add: página não encontrada com ação para voltar a Descobrir
- `62b3688` test: voltar na raiz de outra aba leva a Descobrir
- `efb61cd` add: voltar na raiz de outra aba leva a Descobrir
- `d0366e3` test: barra de abas acessível e sem vazar com fonte grande
- `465e767` docs: aba Estante com rótulo curto no MASTER
- `661d28d` fix: aba Estante com rótulo curto para caber com fonte grande
- `c8fac4b` test: o app abre no shell de navegação
- `cba2028` add: MaterialApp.router com o shell de navegação
- `20c62cb` test: página não encontrada chama onGoHome e rola com fonte grande
- `efce19b` test: voltar fora de Descobrir é avisado ao Android com predictive back
- `ffe397f` fix: voltar fora de Descobrir não fecha o app com predictive back
- `60f5d5f` refactor: helper de teste para o aviso de voltar ao Android
- `f4375a8` docs: registra o andamento da sessão 004
- `1ac3714` docs: achados aceitos da revisão viram tarefas da sessão 004
- `9eeffcc` test: voltar e aviso ao Android em todas as abas e ao revisitar aba carregada
- `a4eb7b2` refactor: PopScope do shell só avisa o Android, sem navegar
- `827afb9` refactor: router aplica o BackToFirstTab por helpers de branch
- `b2eaac3` test: semântica de cada aba e troca de aba sem if no Arrange

## Notas
- `ui-ux-pro-max` (stack Flutter): as regras de navegação (`bottom-nav-limit`, `nav-label-icon`, `back-behavior`, `state-preservation`, `gesture-nav-support`) já estão cobertas pela seção 6 do `MASTER.md`. Não foi preciso override em `pages/`. A sugestão de Riverpod foi ignorada, porque a stack é `provider`.
- `go_router` 18.1.0: exige Flutter 3.44 e traz `material_ui` como dependência transitiva. Context7 veio raso, então a API (`goBranch(initialLocation:)`, `errorBuilder`, `popRoute` do delegate) foi conferida no código do pacote.
- Diferente do planejado, a aba virou **"Estante"** (decisão do usuário). O `NavigationBar` limita os rótulos a 1.3x, mas "Minha estante" quebrava em duas linhas e vazava da barra em qualquer largura com 1.3x, e em 320dp até com 1.0x. Isso não gera erro de overflow, então o teste confere a posição de cada rótulo e ícone. O título da tela continua "Minha estante", e o `MASTER.md` foi atualizado antes do código.
- **Achado no emulador** (Android 16, API 36): o voltar na aba Estante fechava o app, apesar dos testes de `popRoute` verdes.
  - Causa: com predictive back, o Android só repassa o voltar ao Flutter se o último `NavigationNotification` disser `canHandlePop: true`. O navigator da aba, criado na primeira visita, avisava `false` depois do `PopScope` do shell.
  - Correção: `BackToFirstTab` põe o `PopScope` dentro do navigator de cada aba que não é a primeira. O `PopScope` do shell ficou só para o aviso na troca de aba, que não mexe em nenhuma pilha.
  - Os testes gravam a chamada `SystemNavigator.setFrameworkHandlesBack`. Para o Flutter avisar algo, o app precisa estar em `resumed`.
- Testes que passaram de primeira, mantidos como guarda:
  - Troca de aba por toque: o `goBranch` já vinha do ciclo 1.
  - Estado preservado por aba: a checagem de mutação (trocar o `indexedStack` por um container sem `IndexedStack`) confirma que o teste pega a regressão.
  - Guidelines de alvo de toque, rótulo e contraste: já com `ensureSemantics`.
  - Página não encontrada que rola com fonte 2x: a mutação (tirar o `SingleChildScrollView`) gera overflow.
- Os testes de troca de aba e de voltar usam um router de teste com sub-rota (`app_shell_test`), porque o router real ainda não tem rota aninhada.
- O placeholder não tem os 4 estados porque não carrega nada; sai na Fase 1.
- Verificação no emulador (Medium Phone API 36):
  - As 4 abas, com indicador dourado na ativa.
  - Fonte 1.3x sem vazar.
  - Voltar em Estante e em Perfil leva a Descobrir; em Descobrir, fecha o app.
- Tríade: `dart format` sem mudanças, `flutter analyze` sem issues, `flutter test` com 222 testes passando e `gitleaks` sem vazamentos.
- Revisão (`code-reviewer`; o `security-auditor` não rodou porque o diff não toca auth, storage, rede, config, `env/`, manifest nem URLs): nada bloqueante. O mecanismo do voltar foi confirmado por sondagem (abas já carregadas, sub-rota, rota no navigator raiz). Aceitos os itens 1–7; o 8 (`selectedIcon` de Buscar) e o 9 (posição do `firstTab`) ficaram de fora.
- Tratamento da revisão:
  - A: no router real, o aviso ao Android e o voltar até Descobrir agora são testados em Buscar, Estante e Perfil. Somado o teste de revisitar uma aba já carregada. Os testes passaram de primeira, como guarda. As mutações confirmam: sem o wrapper em Perfil, o teste do aviso falha; sem o `canPop` do shell, falha o teste de revisitar.
  - B: o `PopScope` do shell ficou só com `canPop`. O `goBranch` dele mascarava um wrapper esquecido (o teste de voltar seguia verde); depois da mudança, a mutação sem wrapper derruba também o teste de voltar.
  - C: `appShellRoute`, `firstTabBranch` e `tabBranch` (em `app_shell.dart`) montam as abas. O `tabBranch` aplica o wrapper, que virou `_BackToFirstTab`, privado. O router de teste usa os mesmos helpers.
  - D: a semântica de cada aba é conferida com `bySemanticsLabel`, e a mutação com rótulo vazio agora é pega. O teste parametrizado de troca de aba leva a rota de partida na tupla.
  - Emulador depois da revisão: o voltar em Buscar, Estante e Perfil, e ao revisitar Estante, leva a Descobrir; em Descobrir, fecha o app.
  - Tríade depois da revisão: `dart format` sem mudanças, `flutter analyze` sem issues, `flutter test` com 232 testes passando e `gitleaks` sem vazamentos.

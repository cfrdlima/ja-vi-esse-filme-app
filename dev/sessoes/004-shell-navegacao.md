# Sessão 004 — Fase 0: shell de navegação com go_router

**Data**: 2026-10-16 · **Branch**: `feature/004-shell-navegacao` · **Status**: aberta

## Objetivo
Montar a navegação do app com `go_router`: um `StatefulShellRoute` com `NavigationBar` de 4 abas (Descobrir · Buscar · Minha estante · Perfil), cada aba com sua pilha preservada, e `MaterialApp.router` no `main.dart`. As abas mostram um placeholder até as telas reais chegarem na Fase 1.

## Checklist
- [ ] Consultar a `ui-ux-pro-max` (stack Flutter) sobre navegação por abas; gerar override em `pages/` só se surgir regra específica
- [ ] Confirmar a API atual do `go_router` (Context7): `StatefulShellRoute.indexedStack`, `goBranch`, `errorBuilder`
- [ ] Dependência `go_router` no `pubspec.yaml` (já aprovada na stack do `CLAUDE.md`)
- [ ] Shell — RED: o app abre em Descobrir com a `NavigationBar` de 4 destinos e rótulos em PT-BR
- [ ] Shell — GREEN
- [ ] Abas — RED: tocar um destino mostra a tela da aba e marca o destino como selecionado
- [ ] Abas — GREEN
- [ ] Pilha por aba — RED: trocar de aba e voltar mantém o estado da aba anterior (`indexedStack`)
- [ ] Pilha por aba — GREEN
- [ ] Aba ativa — RED: tocar o destino já selecionado volta para a raiz da aba
- [ ] Aba ativa — GREEN
- [ ] Rota desconhecida — RED: mostra "página não encontrada" com ação para voltar a Descobrir
- [ ] Rota desconhecida — GREEN
- [ ] Acessibilidade — RED: destinos com rótulo semântico e `textScaler` 1.5 sem overflow na barra
- [ ] Acessibilidade — GREEN
- [ ] `main.dart` — RED/GREEN: `MaterialApp.router` com o router montado em um ponto só; testes do `main_test.dart` seguem verdes
- [ ] REFACTOR: nomes, rotas como constantes, widgets pequenos
- [ ] Tríade: `flutter analyze` limpo, `flutter test` verde, verificação no emulador (screenshot de cada aba)
- [ ] `/revisar` com `code-reviewer` (sem auth/rede/storage; `security-auditor` só se entrar deep link)

## Decisões

## Commits

## Notas

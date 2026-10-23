# Sessão 012 — Fase 1: Hero do pôster

**Data**: 2026-10-23 · **Branch**: `feature/012-hero-poster` · **Status**: aberta

## Objetivo
Tocar num pôster da grade (Descobrir ou Buscar) leva o pôster voando até o lugar dele nos detalhes, com um `Hero` de tag única dentro do navigator da aba. A transição precisa achar o pôster de destino já no primeiro quadro, enquanto os detalhes ainda carregam, e respeitar o movimento reduzido.

## Checklist
- [ ] Investigar: o `go_router` 18.1.0 dá um `HeroController` aos navigators do `StatefulShellRoute`? Confirmar no código do pacote antes do RED
- [ ] Investigar: as tags podem colidir? Hoje o `PagedMoviesNotifier` já tira ids repetidos da grade, só uma grade da Descobrir fica montada por vez e cada aba tem o seu navigator. Registrar a conclusão no override `pages/detalhes.md`
- [ ] Design: consultar a `ui-ux-pro-max` (stack Flutter) sobre a transição de pôster e atualizar a seção "Transição" de `pages/detalhes.md` e o MASTER, se for o caso
- [ ] Tag do Hero num lugar só (`MovieHeroTag` ou função em `presentation`), sem a string repetida nas duas telas — RED / GREEN
- [ ] Pôster da grade dentro de um `Hero` com a tag do filme — RED / GREEN
- [ ] Detalhes com o pôster de destino já no estado carregando: levar o `Movie` da grade para a rota (`extra` do go_router) e mostrar pôster e título enquanto o resto carrega; sem `extra` (URL direta), cai no skeleton atual — RED / GREEN / REFACTOR
- [ ] Pôster de destino continua o mesmo `Hero` no estado de sucesso, e também no erro e no "não encontrado", ou o voltar não anima — RED / GREEN
- [ ] Teste de transição: tocar no pôster da grade gera um voo de Hero (widget test com `pump` no meio da rota) e o voltar também — RED / GREEN
- [ ] Movimento reduzido: com `disableAnimations`, sem voo (troca direta) — RED / GREEN
- [ ] Semântica: o Hero não duplica o pôster para o leitor de tela durante o voo
- [ ] Tríade: `flutter analyze` limpo, `flutter test` verde e emulador (Descobrir e Buscar, ida e volta, filme sem pôster, troca de categoria, fonte grande)
- [ ] `/revisar`: `code-reviewer` (a sessão não toca auth, storage nem rede; o `security-auditor` só se o `extra` mexer na rota com parâmetro)

## Decisões

## Commits

## Notas

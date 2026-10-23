# Sessão 011 — Fase 1: detalhes do filme

**Data**: 2026-10-23 · **Branch**: `feature/011-detalhes-filme` · **Status**: aberta

## Objetivo
Tocar num pôster da Descobrir ou da Buscar abre os detalhes do filme numa rota dentro da própria aba (`/descobrir/filme/:id` e `/buscar/filme/:id`). A tela mostra sinopse (com o texto original quando a de pt-BR vier vazia), gêneros, duração, nota, data e até 15 pessoas do elenco, e tem os 4 estados. O pedido é um só: `/movie/{id}` com o elenco anexado.

## Checklist
- [ ] Contrato: conferir `/movie/{id}` e `append_to_response` (`credits`, e o que trazer para a sinopse original) na documentação oficial (Context7/web): campos nulos, `runtime`, `genres`, `cast` (`order`, `character`, `profile_path`)
- [ ] Design: consultar a `ui-ux-pro-max` (stack Flutter) para tela de detalhe, elenco horizontal e textos longos; criar o override `pages/detalhes.md`
- [ ] Domínio: `MovieDetails` e `CastMember`, com o teto de 15 pessoas no domínio — RED / GREEN / REFACTOR
- [ ] Domínio: `MovieRepository.details(id)`, recusando id < 1 sem chamar o TMDB — RED / GREEN
- [ ] Fixtures `movie_details_*.json` (completo, com campos nulos/vazios e com sinopse pt-BR vazia)
- [ ] Datasource + model: parse defensivo (`runtime` nulo ou 0, `release_date` vazio, `genres`/`cast` ausentes, item de elenco quebrado), elenco pela `order` e cortado em 15 — RED / GREEN / REFACTOR
- [ ] Sinopse: fallback para o texto original quando a de pt-BR vier vazia — RED / GREEN
- [ ] Formatação pt-BR (`intl`, decisão 005): duração ("2 h 15 min"), data e nota ("7,8"), na `presentation` — RED / GREEN
- [ ] Estado: `MovieDetailsNotifier` (carregando, erro com a falha, sucesso; 404 como estado próprio) — RED / GREEN / REFACTOR
- [ ] Tela de detalhes: 4 estados (skeleton, "filme não encontrado", erro com `RetryButton`, sucesso), pôster com placeholder, elenco horizontal com foto ou placeholder e `Semantics` — RED / GREEN, com `textScaler` 1.5 numa tela de 320dp
- [ ] Rotas: `filme/:id` como sub-rota (`routes:` do `firstTabBranch`/`tabBranch`, que já existe) dentro de Descobrir e Buscar, id inválido vai para "não encontrado", e o voltar retorna à grade com a rolagem e não cai na regra do voltar da raiz da aba — RED / GREEN
- [ ] Pôster tocável na grade (alvo ≥ 48dp, `Semantics` de botão) que abre os detalhes da aba atual — RED / GREEN
- [ ] Strings novas no ARB (títulos de seção, duração, nota, "não encontrado", elenco, sem sinopse)
- [ ] Tríade: `flutter analyze` limpo, `flutter test` verde e emulador (abrir pelas duas abas, voltar, filme sem pôster/sinopse, fonte grande)
- [ ] `/revisar`: `code-reviewer` + `security-auditor` (a sessão toca rede e rota com parâmetro)

## Decisões

## Commits

## Notas

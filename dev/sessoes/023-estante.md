# Sessão 023 — Fase 2: Estante com Assistidos, Quero assistir e Favoritos

**Data**: 2026-11-17 · **Branch**: `feature/023-estante` · **Status**: aberta

## Objetivo
Trocar o placeholder da aba Estante por três abas (**Assistidos**, **Quero assistir**, **Favoritos**) lidas do Firestore, com a mais recente primeiro, paginação e os 4 estados. A cópia do TMDB vencida (mais de 6 meses desde o `cachedAt`, decisão 013) não aparece como atual e é renovada com o TMDB pelo `renewCopy`. Sem conta, a aba convida a entrar.

## Checklist
### Preparação
- [x] Conferir no Context7 o `cloud_firestore` 7.1.0: `where(isNotEqualTo: null)` + `orderBy` no mesmo campo (descendente), `limit`, `startAfterDocument` e `snapshots()` com `hasPendingWrites`. **Feito:** o `isNotEqualTo: null` é ignorado em silêncio (ver "Notas"); a consulta usa só o `orderBy`
- [x] Decidir com o usuário: paginação (stream com `limit` crescente ou páginas com cursor), ordem, o que a aba mostra sem conta e onde a renovação da cópia acontece. **Decidido:** stream com `limit` crescente de 20 em 20; mais recente primeiro; sem conta, convite com "Entrar com Google"; renovação da cópia vencida nesta sessão
- [x] Consultar a `ui-ux-pro-max` (stack Flutter) para a Estante e gerar o override `pages/estante.md`. **Feito:** nada de `TabBar` na stack Flutter (fallback declarado)

### Domínio (RED/GREEN/REFACTOR)
- [ ] `MovieCopy`/`ShelfMovie` dizem se a cópia está vencida (6 meses desde o `cachedAt`, com relógio injetado)
- [ ] Contrato da página da Estante: `watchShelf(mark, ...)` com os filmes da marca, mais recentes primeiro, e se há mais
- [ ] `renewCopy(MovieCopy)` no contrato: regrava só `title`, `posterPath` e `cachedAt`

### Data (RED/GREEN/REFACTOR)
- [ ] Gateway: consulta por marca com `where`/`orderBy`/`limit` e cursor; datas pendentes estimadas, como no `watchMovie`
- [ ] Repositório: traduz a página para entidades, falhas tipadas, `SignInRequiredFailure` sem conta; `closeStreams()` encerra também os streams da Estante
- [ ] `renewCopy` no repositório e no gateway (`update` só da cópia)
- [ ] Regras: testes no emulador da consulta por marca do dono (lista permitida), de outro `uid` negada e do `renewCopy` mantendo as marcas. Se `firestore.rules` mudar, publicar antes de fechar

### Estado (RED/GREEN/REFACTOR)
- [ ] Notifier por aba: carregando, vazio, erro com "tentar de novo", sucesso; próxima página ao chegar ao fim
- [ ] Reassina quando a conta muda; deslogado; para no fim do stream (logout)
- [ ] Cópia vencida: não mostra o título/pôster como atuais e pede a renovação ao TMDB (falha da renovação não derruba a aba)

### UI (RED/GREEN/REFACTOR, widget tests)
- [ ] Tela da Estante com `TabBar` das três abas, grade de pôsteres (placeholder sem `posterPath`), skeleton, vazio por aba, erro com "tentar de novo", strings no ARB, `Semantics`, alvo ≥ 48dp, fonte grande
- [ ] Toque no pôster abre os Detalhes (Hero com tag única da aba)
- [ ] Sem conta: convite para entrar com o Google

### Composição
- [ ] Rota `/estante` com a tela real no `app_router.dart`, dependências montadas no `main.dart`; fakes em `test/helpers/` atualizados

### Entrega
- [ ] Tríade: format, analyze limpo, `flutter test` verde, `npm test` das regras se mudarem
- [ ] Emulador: abas, paginação, marcar nos Detalhes e ver na aba, offline, logout
- [ ] `PLANO.md` e `docs/PRIVACIDADE.md` se o texto mudar
- [ ] `/revisar` (`code-reviewer` e `security-auditor`: storage, rede)
- [ ] `/fechar-sessao`

## Decisões

## Commits

## Notas
- **`where(isNotEqualTo: null)` no `cloud_firestore` 7.1.0** (código do pacote no pub-cache, `query.dart`): o `where` só põe a condição `!=` quando `isNotEqualTo != null`, então passar `null` **não filtra nada** e a consulta traz todos os documentos. O `!= null` sai com `isNull: false`. A decisão 013 cita `where('<marca>At', '!=', null)`; o `orderBy('<marca>At', descending: true)` sozinho já basta, porque o Firestore deixa fora do resultado o documento sem o campo ordenado, e evita o `!=`. **A conferir no emulador:** se uma marca offline (`serverTimestamp()` pendente) aparece na consulta local e em que posição.

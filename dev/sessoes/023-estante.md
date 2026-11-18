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
- [x] `MovieCopy`/`ShelfMovie` dizem se a cópia está vencida (6 meses desde o `cachedAt`, com relógio injetado). **Já existia:** `ShelfMovie.isCopyExpired` (sessão 021). **Também:** `ExpiredCopyRenewer` (uma por vez, uma vez por filme, para no 429 e sem rede, não espera a escrita) e `MovieCopySource`
- [x] Contrato da página da Estante: `watchShelf(mark, ...)` com os filmes da marca, mais recentes primeiro, e se há mais. **Feito:** `ShelfPage` e `watchShelf(mark, limit:)`
- [x] `renewCopy(MovieCopy)` no contrato: regrava só `title`, `posterPath` e `cachedAt`

### Data (RED/GREEN/REFACTOR)
- [x] Gateway: consulta por marca com `where`/`orderBy`/`limit` e cursor; datas pendentes estimadas, como no `watchMovie`. **Mudou:** só `orderBy` + `limit`, sem `where` nem cursor
- [x] Repositório: traduz a página para entidades, falhas tipadas, `SignInRequiredFailure` sem conta; `closeStreams()` encerra também os streams da Estante. **Também:** o documento ilegível é pulado e conta para o `hasMore`
- [x] `renewCopy` no repositório e no gateway (`update` só da cópia). **Também:** `TmdbMovieCopySource` sobre o `MovieRepository.details`
- [x] Regras: testes no emulador da consulta por marca do dono (lista permitida), de outro `uid` negada e do `renewCopy` mantendo as marcas. Se `firestore.rules` mudar, publicar antes de fechar. **Feito:** 3 testes novos (80 verdes); o emulador confirma que o `orderBy` deixa fora o filme sem a marca; o `renewCopy` já tinha teste; as regras não mudaram

### Estado (RED/GREEN/REFACTOR)
- [x] Notifier por aba: carregando, vazio, erro com "tentar de novo", sucesso; próxima página ao chegar ao fim. **Feito:** `ShelfTabNotifier`; o erro com filmes na tela vai para o rodapé
- [x] Reassina quando a conta muda; deslogado; para no fim do stream (logout)
- [x] Cópia vencida: não mostra o título/pôster como atuais e pede a renovação ao TMDB (falha da renovação não derruba a aba). **Feito:** um `ExpiredCopyRenewer` por conta; o "não mostrar como atual" fica na UI

### UI (RED/GREEN/REFACTOR, widget tests)
- [x] Tela da Estante com `TabBar` das três abas, grade de pôsteres (placeholder sem `posterPath`), skeleton, vazio por aba, erro com "tentar de novo", strings no ARB, `Semantics`, alvo ≥ 48dp, fonte grande. **Feito:** `ShelfScreen` e `ShelfTab`; grade e skeleton extraídos do `PagedMoviesView` (`PosterGrid`)
- [x] Toque no pôster abre os Detalhes (Hero com tag única da aba). **Mudou:** o Hero fica só na aba visível, porque os Detalhes esperam `poster-<id>`; teste com o filme em duas abas, conferido por mutação
- [x] Sem conta: convite para entrar com o Google. **Feito:** pelo `SessionNotifier`; as abas nascem com a conta e morrem no logout

### Composição
- [x] Rota `/estante` com a tela real no `app_router.dart`, dependências montadas no `main.dart`; fakes em `test/helpers/` atualizados. **Feito:** o `MovieCopySource` nasce no router, sobre o `MovieRepository`; o `main.dart` não mudou (a Estante e a conta já vinham por `Provider`); sai o `PlaceholderScreen`, a última aba provisória, com a string `comingSoon`

### Achados aceitos do `/revisar` (o usuário seguiu a recomendação)
- [ ] (1, bloqueante) `loadMore` não fura o erro do rodapé (laço de reassinatura com limite crescente)
- [ ] (2) Nada da Estante grava ou assina depois do `closeStreams()`: abas só em `SessionSignedIn`, mortas no `SigningOut`; o `_onDone` descarta o renovador
- [ ] (3) Sem skeleton eterno depois de um logout que falhou: aviso com "Ir para o Perfil" no `SessionSignOutFailed`
- [ ] (4) Teto de 200 filmes por aba no limite crescente, com aviso no rodapé, e o custo de leitura registrado em decisão
- [ ] (5) Aba vazia que recebe erro mostra o erro com "tentar de novo", e não uma grade em branco
- [ ] (6) Política 2.0 no `PLANO.md`: consulta automática ao TMDB (ids e IP), base legal e "renovada quando o filme aparece na Estante"
- [ ] (8) `try`/`finally` no `_drain` do renovador
- [ ] (10) Rodapé com estado selado (`NextPageStatus`) no lugar de `bool` + `Failure?`
- [ ] (14) Comentário do `_SilentCopySource` no teste
- [ ] (15) Widget tests do spinner e do "Tentar de novo" do rodapé e da mensagem do erro da primeira página
- [ ] (16) Decisão nova (só `orderBy`, limite crescente com teto) e comentários com mais de 80 colunas
- [ ] (7, 9, 11, 12, 13) Para o `BACKLOG.md`: renovador por conta compartilhado, `retryAfter` no renovador, relógio único da cópia vencida, `index` redundante do `ShelfTab`, `PosterGrid`/`MoviesMessage` em `core/widgets`

### Entrega
- [ ] Tríade: format, analyze limpo, `flutter test` verde, `npm test` das regras se mudarem
- [x] Emulador: abas, paginação, marcar nos Detalhes e ver na aba, offline, logout. **Feito com o Maestro** (fluxos fora do repositório), no `Pixel_9_Pro` (Android 16, API 36), contra o projeto real: as três abas leem do Firestore; o vazio com "Descobrir filmes"; o mesmo filme vivo nas três abas abre os Detalhes sem quebrar o Hero; marcar nos Detalhes aparece ao vivo na aba, com o mais recente primeiro; a marca feita em modo avião entra no topo e fica lá quando a rede volta; o logout volta ao convite; o login pelo convite abre em Assistidos com as marcas do servidor; com `font_scale` 1.5, o `TabBar` rola; desmarcar esvazia a aba ao vivo. As marcas de teste foram desfeitas. **Não deu para ver no aparelho:** a paginação (precisa de mais de 20 filmes numa marca) e a cópia vencida (as regras não deixam o cliente escolher o `cachedAt`); as duas ficaram nos widget tests
- [ ] `PLANO.md` e `docs/PRIVACIDADE.md` se o texto mudar
- [ ] `/revisar` (`code-reviewer` e `security-auditor`: storage, rede)
- [ ] `/fechar-sessao`

## Decisões

## Commits

## Notas
- **`where(isNotEqualTo: null)` no `cloud_firestore` 7.1.0** (código do pacote no pub-cache, `query.dart`): o `where` só põe a condição `!=` quando `isNotEqualTo != null`, então passar `null` **não filtra nada** e a consulta traz todos os documentos. O `!= null` sai com `isNull: false`. A decisão 013 cita `where('<marca>At', '!=', null)`; o `orderBy('<marca>At', descending: true)` sozinho já basta, porque o Firestore deixa fora do resultado o documento sem o campo ordenado, e evita o `!=`. **A conferir no emulador:** se uma marca offline (`serverTimestamp()` pendente) aparece na consulta local e em que posição.
- **Erro no stream da consulta (`cloud_firestore_platform_interface` 8.1.0, `method_channel_query.dart`):** no Android, o nativo manda o erro e o `endOfStream`, mas o `Query.snapshots()` do Dart ouve o canal sem `onDone`, e o stream público não acaba. Depois de um erro, o listener nativo morreu, e o "tentar de novo" assina outra vez. O `onDone` da aba só chega pelo `closeStreams()` do logout.
- **Marca offline na consulta (Android, `cloud_firestore` 7.1.0):** o `serverTimestamp()` pendente entra na consulta local com `orderBy(<marca>At, descending: true)` e fica **no topo** (o SDK ordena a data pendente depois de todas as datas). Quando o servidor confirma, a posição não muda. Respondido o "a conferir no emulador" da preparação.
- **Emulador:** o `Pixel_9` ficou sem espaço (96% do `/data`, com apps de outros projetos, que não foram mexidos); a verificação foi no `Pixel_9_Pro` (10 GB), que já tinha o app e a conta da 022.

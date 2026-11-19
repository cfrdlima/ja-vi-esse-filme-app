# Sessão 029 — Fase 3: listas personalizadas

**Data**: 2026-11-18 · **Branch**: `feature/029-listas-personalizadas` (empilhada na `feature/028-nota-e-data`) · **Status**: aberta

## Objetivo
Permitir que o usuário logado crie, renomeie e apague listas próprias e adicione e remova filmes delas, com o nome validado e o tamanho máximo no domínio. O vínculo fica num mapa `lists` no documento do filme e as listas em `users/{uid}/lists/{listId}` (decisão 019), com regras testadas no emulador e a exclusão da conta cobrindo a coleção nova.

## Checklist
### Preparação
- [x] Decisão (`/decisao`): modelo das listas, campos, tetos, ordem e onde a UI mora. **Feito:** decisão 019, com o mapa `lists` no documento do filme no lugar da subcoleção `items`, nome de 1 a 50, tetos de 50 listas e 200 filmes, e a 4ª aba da Estante
- [x] Consultar a `ui-ux-pro-max` (stack Flutter) para a tela das listas, a da lista e a folha "Adicionar à lista" nos Detalhes; override em `pages/` se precisar. **Feito:** seções "Aba Listas" e "Tela da lista" no `estante.md` e "Adicionar à lista" no `detalhes.md`; para a folha com caixas de seleção e o contador de caracteres, a busca não achou regra (fallback). Ponto aberto: como saber que a lista está cheia (200) para desabilitar a caixa
- [ ] Conferir a limpeza mensal (`firestore/cleanup`): filme só em lista (sem marca) é renovado e, se sumiu do TMDB, apagado; órfãos com `lists`

### Regras do Firestore (RED/GREEN/REFACTOR, no emulador)
- [x] `lists/{listId}`: só o dono; id automático (20 `[A-Za-z0-9]`); só `name`, de 1 a 50, não só espaços, sem caractere de controle
- [x] `movies.lists`: mapa de até 50 chaves no formato do id, nunca vazio, uma chave mudada por escrita, a nova com `request.time` e as antigas intactas
- [x] `movies` sem marca com `lists` é aceito; sem marca e sem `lists`, recusado; nota e dia ainda exigem o `watchedAt`
- [x] Negados: outro `uid`, sem login, outro provedor, `collectionGroup('lists')`, chave extra
- [x] `rules-file.test.js` confere `lists` na lista fixa; exclusão: o dono apaga listas e filmes, e não sobra nada em `users/{uid}`. **Feito:** o `rules-file.test.js` não mudou (a comparação com o app pegou a falta de `lists`, que entrou no `UserCollections`); o teste da exclusão ganhou listas e um filme só numa lista, e passou de primeira depois das regras

### Domínio (RED/GREEN/REFACTOR)
- [x] `ListName`: recusa vazio, só espaços e acima do máximo; tira espaços das pontas
- [x] Entidade `MovieList` (id, nome) e `ShelfMovie` com os ids das listas, sem conhecer o JSON
- [x] Contrato: listas em stream (ordem alfabética sem acento/caixa), criar (teto de 50), renomear, apagar, adicionar filme (teto de 200 por lista) e tirar, filmes de uma lista com limite crescente; falhas tipadas (sem conta, sem rede, teto atingido). **Feito:** `MovieListsRepository` com `newList` (id local, sem gravar) e as contagens; `CreateMovieList` e `AddMovieToList` com os tetos e `ListLimitFailure`/`ListFullFailure` no `core`. A lista cheia é descoberta ao tocar, e não antes (contar cada lista ao abrir a folha custaria uma leitura por lista): o override do `detalhes.md` muda junto com a UI

### Data (RED/GREEN/REFACTOR, com fakes do gateway)
- [ ] Model da lista e `lists` do filme com parse defensivo (nome inválido, chave fora do formato, valor que não é data)
- [ ] Gateway fino sobre o `cloud_firestore` e repositório, com o `UserDataWriteLock` da exclusão
- [ ] Adicionar grava a cópia do TMDB e a chave; tirar da última lista sem marca apaga o documento; `removeMark` da última marca com `lists` vira `update`
- [ ] Apagar a lista tira a chave dos filmes (do servidor, lotes de 500, 15 s por passo) e só depois apaga a lista
- [ ] Aba da lista renova a cópia vencida pelo `ExpiredCopyRenewer`

### Exclusão da conta (RED/GREEN/REFACTOR)
- [ ] `UserCollections.all` com `lists` (o comentário da exclusão aninhada sai) e teste de que a exclusão apaga as listas
- [ ] Limpeza mensal: teste no emulador do filme só em lista

### Estado e UI (RED/GREEN/REFACTOR, widget tests)
- [ ] Notifier das listas (4 estados, criar/renomear/apagar otimistas com erro e "tentar de novo")
- [ ] Tela das listas: vazio com chamada para criar, erro, skeleton, sucesso; diálogo de nome com o limite visível
- [ ] 4ª aba da Estante "Listas" e tela da lista: filmes com limite crescente, tirar filme, os 4 estados
- [ ] Detalhes: "Adicionar à lista" com as listas marcadas, login opcional (`SignInRequiredFailure`) e volta para onde estava
- [ ] Confirmação antes de apagar uma lista com filmes
- [ ] Strings no ARB, `Semantics`, alvo ≥ 48dp e fonte grande sem overflow

### Fechamento
- [ ] Política 2.0 (`docs/PRIVACIDADE.md`), página de exclusão (`docs/EXCLUSAO-DA-CONTA.md`) e diálogo da exclusão da conta citando as listas
- [ ] Rotas novas no `go_router` e montagem no `main.dart`
- [ ] `PLANO.md`: o item das listas sem a exclusão aninhada dos `items` (decisão 019)
- [ ] Verificação no emulador (screenshot via MCP do Flutter) e deploy das regras no projeto real, com confirmação
- [ ] `/revisar` (`code-reviewer` e `security-auditor`)

## Decisões
- [019 — Listas personalizadas: mapa de listas no documento do filme](../decisoes/019-listas-personalizadas.md) (emenda na 013)

## Commits

## Notas
- **Regras (sessão 029):** o `keys().join(',')` existe e serve para validar as chaves do mapa; a junção também confere o tamanho exato, para uma chave com vírgula não se passar por duas. O `size()` de string conta unidades UTF-16 (25 emojis cabem em 50, 26 não), o mesmo que o `length` do Dart.
- **Empilhada:** base na `feature/028-nota-e-data`; o PR vai com essa base, como a 026 a 028 (PRs #21 a #24 esperam o CI destravar).
- **Tamanho:** se a sessão crescer demais, a UI (Estado e UI) pode ir para a 030, com domínio, regras, data e exclusão fechados aqui.

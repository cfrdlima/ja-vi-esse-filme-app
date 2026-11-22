# Sessão 029 — Fase 3: listas personalizadas

**Data**: 2026-11-18 a 2026-11-22 · **Branch**: `feature/029-listas-personalizadas` (empilhada na `feature/028-nota-e-data`) · **Status**: fechada

## Objetivo
Permitir que o usuário logado crie, renomeie e apague listas próprias e adicione e remova filmes delas, com o nome validado e o tamanho máximo no domínio. O vínculo fica num mapa `lists` no documento do filme e as listas em `users/{uid}/lists/{listId}` (decisão 019), com regras testadas no emulador e a exclusão da conta cobrindo a coleção nova.

## Checklist
### Preparação
- [x] Decisão (`/decisao`): modelo das listas, campos, tetos, ordem e onde a UI mora. **Feito:** decisão 019, com o mapa `lists` no documento do filme no lugar da subcoleção `items`, nome de 1 a 50, tetos de 50 listas e 200 filmes, e a 4ª aba da Estante
- [x] Consultar a `ui-ux-pro-max` (stack Flutter) para a tela das listas, a da lista e a folha "Adicionar à lista" nos Detalhes; override em `pages/` se precisar. **Feito:** seções "Aba Listas" e "Tela da lista" no `estante.md` e "Adicionar à lista" no `detalhes.md`; para a folha com caixas de seleção e o contador de caracteres, a busca não achou regra (fallback). Ponto aberto: como saber que a lista está cheia (200) para desabilitar a caixa
- [x] Conferir a limpeza mensal (`firestore/cleanup`): filme só em lista (sem marca) é renovado e, se sumiu do TMDB, apagado; órfãos com `lists`

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
- [x] Model da lista e `lists` do filme com parse defensivo (nome inválido, chave fora do formato, valor que não é data)
- [x] Gateway fino sobre o `cloud_firestore` e repositório, com o `UserDataWriteLock` da exclusão. **Feito:** `MovieListsGateway` e `FirestoreMovieListsRepository` (escritas no filme pelo `ShelfGateway`), `UnavailableMovieListsRepository`, e a tradução de erro e os streams abertos num `firestore_support.dart` comum; as contagens usam o `count()` do servidor e caem no cache do aparelho sem rede ou depois de 5 s
- [x] Adicionar grava a cópia do TMDB e a chave; tirar da última lista sem marca apaga o documento; `removeMark` da última marca com `lists` vira `update`
- [x] Apagar a lista tira a chave dos filmes (do servidor, lotes de 500, 15 s por passo) e só depois apaga a lista
- [x] Aba da lista renova a cópia vencida pelo `ExpiredCopyRenewer`. **Feito:** o `ShelfTabNotifier` recebe a fonte da página (refactor) e serve à tela da lista com o mesmo renovador

### Exclusão da conta (RED/GREEN/REFACTOR)
- [x] `UserCollections.all` com `lists` (o comentário da exclusão aninhada sai) e teste de que a exclusão apaga as listas
- [x] Limpeza mensal: teste no emulador do filme só em lista. **Feito:** renovação e 404 do filme só numa lista, e órfão só com listas; passaram de primeira (a limpeza não olha as marcas, e os órfãos saem pelo `recursiveDelete`)

### Estado e UI (RED/GREEN/REFACTOR, widget tests)
- [x] Notifier das listas (4 estados, criar/renomear otimistas, apagar com espera, com erro e "tentar de novo"). **Feito:** `MovieListsNotifier` (aba), `MovieListNotifier` (tela da lista) e `AddToListNotifier` (folha); o `CreateMovieList` devolve a escrita pendente num record, para pôr o filme na lista nova sem esperar o servidor
- [x] Tela das listas: vazio com chamada para criar, erro, skeleton, sucesso; diálogo de nome com o limite visível. **Feito:** o contador conta unidades UTF-16, como as regras; o campo de uma linha já troca a quebra de linha por espaço, e o tab é recusado
- [x] 4ª aba da Estante "Listas" e tela da lista: filmes com limite crescente, tirar filme, os 4 estados. **Feito:** grade num `ShelfMoviesView` comum (refactor); tirar pelo toque longo e pela ação do leitor de tela, com "Desfazer"
- [x] Detalhes: "Adicionar à lista" com as listas marcadas, login opcional (`SignInRequiredFailure`) e volta para onde estava
- [x] Confirmação antes de apagar uma lista com filmes. **Mudou:** sempre pergunta, porque saber se a lista tem filmes custaria uma leitura
- [x] Strings no ARB, `Semantics`, alvo ≥ 48dp e fonte grande sem overflow

### Achados do /revisar (aceitos)
- [x] I1: tirar o filme da lista com `permission-denied` relê o filme do servidor e refaz a escrita, sem apagar marcas, nota e dia
- [x] I2: chave de lista órfã: o "Nova lista" recusado tira o filme da lista nova, a limpeza mensal tira as chaves sem lista e apaga o filme que fica sem motivo, e a política e a 019 contam o caso
- [x] I3: "Nova lista" com a folha fechada no meio ainda põe o filme e trata a recusa
- [x] I4: o "tentar de novo" da folha só aparece para a caixa recusada, e nunca no teto
- [x] I5: o "Desfazer" aparece na hora, sem esperar o servidor
- [x] I6: o desfazer com a cópia vencida busca uma cópia nova no TMDB antes de pôr de volta
- [x] I7: apagar pela tela da lista mostra andamento e ignora o toque repetido
- [x] I9: testes das regras com a escrita exata do `addToListFields` (merge), o mapa vazio recusado, update/delete de outro `uid`, escrita sem login e nomes com C1 e DEL
- [x] S1: `closeUserDataStreams` fecha as listas mesmo se a Estante falhar
- [x] S2: a tela da lista esquece a lista no logout
- [x] S3: texto próprio da tela da lista no logout
- [x] S8: política (tabela da cópia local, emojis que contam 2) e página de exclusão ("marca ou lista")

### Fechamento
- [x] Política 2.0 (`docs/PRIVACIDADE.md`), página de exclusão (`docs/EXCLUSAO-DA-CONTA.md`) e diálogo da exclusão da conta citando as listas
- [x] Rotas novas no `go_router` e montagem no `main.dart`. **Feito:** `/estante/listas/:listId` com os Detalhes empilhados; o logout fecha os streams da Estante e das listas (`closeUserDataStreams`)
- [x] `PLANO.md`: o item das listas sem a exclusão aninhada dos `items` (decisão 019)
- [x] Verificação no emulador (screenshot via MCP do Flutter) e deploy das regras no projeto real, com confirmação. **Feito:** regras publicadas com a conta dona do projeto; verificação por `adb` (o MCP do Flutter não estava disponível) com a conta de teste escolhida pelo usuário
- [x] `/revisar` (`code-reviewer` e `security-auditor`). **Feito:** sem bloqueante; 12 achados tratados nesta sessão, 5 no backlog

## Decisões
- [019 — Listas personalizadas: mapa de listas no documento do filme](../decisoes/019-listas-personalizadas.md) (emenda na 013)

## Commits
Desde a base empilhada (`git log feature/028-nota-e-data..HEAD`):

- `8db6f29` docs: abre sessão 029 e decisão 019 das listas personalizadas
- `af03b81` docs: overrides da aba Listas, da tela da lista e da folha Adicionar à lista
- `d5023c0` test: regras das listas e do mapa lists no documento do filme
- `5344d23` add: regras das listas e do mapa lists, e lists na lista fixa das subcoleções
- `009a115` test: exclusão da conta apaga as listas e o filme só numa lista
- `9c764fe` test: nome da lista tira os espaços e recusa vazio, longo e controle
- `20e37fc` add: ListName tira os espaços e recusa vazio, acima de 50 e caractere de controle
- `6c722f2` test: lista personalizada com id e nome e ordem alfabética sem acento nem caixa
- `c324c13` add: MovieList com os tetos e a ordem alfabética sem acento nem caixa
- `1fde387` test: filme da Estante nas listas, só numa lista e o que sobra ao tirar
- `84d9dda` add: ShelfMovie nas listas, só numa lista e o que continua ao tirar marca ou lista
- `fb5f331` test: mensagens do teto de listas e da lista cheia
- `b975e14` add: falhas do teto de listas e da lista cheia, com as mensagens
- `adcae07` test: criar lista respeita o teto de 50 e pôr filme o de 200
- `bfd1760` add: CreateMovieList e AddMovieToList com os tetos de 50 listas e 200 filmes
- `34185c5` test: campos do Firestore com as datas e as escritas dentro de um mapa
- `55be360` add: leitura das datas e escrita de campos dentro de um mapa do Firestore
- `9f11a9c` test: model do filme lê, põe e tira as listas do mapa lists
- `6633e0a` add: model do filme lê, põe e tira as listas do mapa lists
- `4aa0f30` test: model da lista lê o nome em ordem alfabética e pula o ilegível
- `0296c4d` add: MovieListModel lê as listas em ordem alfabética e grava o nome
- `8306e4e` test: tirar a última marca do filme numa lista atualiza, e não apaga
- `c640bf2` add: removeMark mantém o documento do filme que está numa lista
- `4cac6c1` refactor: tradução de erro e streams abertos do Firestore num arquivo comum da Estante
- `3dce341` test: repositório das listas no Firestore com contagem offline, prazo e lotes
- `40a2e08` add: FirestoreMovieListsRepository com contagem do aparelho offline, prazo por passo e lotes ao apagar
- `906d28c` test: const nos testes do repositório das listas
- `f6e906b` refactor: parâmetros privados nomeados e close dos fakes no repositório das listas
- `3d145fe` add: gateway das listas sobre o cloud_firestore
- `8864efc` test: listas sem Firebase falham com SignInRequiredFailure
- `4bca231` add: UnavailableMovieListsRepository sempre deslogado
- `79e6a8e` test: limpeza mensal renova e apaga o filme só numa lista, e apaga as listas de órfãos
- `37288a9` refactor: ShelfTabNotifier recebe a fonte da página, para servir também à lista
- `f0ce496` test: criar lista devolve a escrita pendente depois de passar pelo teto
- `632a57b` add: CreateMovieList devolve a escrita pendente depois de passar pelo teto
- `aba9365` test: estado da aba Listas com criar e renomear otimistas e apagar com espera
- `2418456` add: MovieListsNotifier com criar e renomear otimistas e apagar com espera
- `af13df7` test: diálogos do nome da lista e de apagar a lista
- `3664b4e` add: diálogos do nome da lista, com o contador das regras, e de apagar a lista
- `3757d72` test: aba Listas com os 4 estados, criar, renomear, apagar e fonte grande
- `6f41fb2` add: aba Listas com Nova lista, menu de renomear e apagar, avisos e skeleton de linhas
- `3356c0a` test: Estante com a aba Listas por último, abrindo a lista e fechando na saída
- `bad11f5` add: aba Listas como a 4ª da Estante
- `f2bd97f` refactor: grade da Estante num ShelfMoviesView com Hero, Detalhes e toque longo configuráveis
- `720c064` test: estado da tela de uma lista com o nome, a lista apagada e as ações
- `af260df` add: MovieListNotifier acha a lista pelo id, segue o nome e avisa quando ela some
- `aadfade` test: tela de uma lista com a grade, tirar e desfazer, renomear, apagar e a lista que sumiu
- `208669c` add: tela de uma lista com a grade, tirar com desfazer, renomear e apagar
- `9ee6e7d` test: rota de uma lista e dos Detalhes dentro dela na aba Estante
- `03c1134` add: rota da lista personalizada na aba Estante, com os Detalhes empilhados
- `20d293d` test: marcas dão o filme confirmado pela Estante para as listas
- `1be30f6` add: ShelfMarksNotifier expõe o filme confirmado pela Estante
- `e940617` test: folha Adicionar à lista com caixas otimistas, tetos e criar lista com o filme
- `fe18541` add: AddToListNotifier com caixas otimistas, tetos e criar lista com o filme
- `c39e74b` test: Adicionar à lista nos Detalhes, com login, caixas, nova lista e lista cheia
- `5e920e4` add: Adicionar à lista nos Detalhes, com login opcional, caixas e nova lista
- `02d1ed9` test: main monta as listas, sem Firebase indisponíveis, e o logout fecha os streams delas
- `d0c2289` add: main monta as listas e o logout fecha os streams delas junto com os da Estante
- `a72f707` docs: política 2.0, página e diálogo da exclusão com as listas, override dos Detalhes e PLANO
- `dbf7f2e` docs: checklist da 029 com a UI das listas
- `aba3012` docs: achados aceitos do /revisar da 029 no checklist e o resto no backlog
- `45af7f8` test: regras com a escrita exata do addToListFields, o mapa vazio e acessos de outro uid e sem login
- `2112bc8` test: tirar da lista com a recusa das regras relê o filme do servidor e não apaga as marcas
- `9a12af2` fix: tirar da lista com a recusa das regras relê o filme do servidor em vez de apagá-lo
- `b343b46` test: limpeza mensal tira as chaves de lista sem lista e apaga o filme sem motivo
- `667fe8d` test: limpeza mensal roda as chaves sem lista antes das cópias e as conta no relatório
- `195e9d2` add: limpeza mensal tira as chaves de lista sem lista antes de renovar as cópias
- `69af06b` test: folha tira o filme da lista recusada, segue com a folha fechada e só oferece tentar de novo na caixa
- `f59b184` fix: folha tira o filme da lista recusada, segue com a folha fechada e só oferece tentar de novo na caixa
- `0929345` test: tela da lista busca cópia nova no desfazer, marca o apagar e esquece a lista no logout
- `7d2eb06` fix: desfazer busca cópia nova se a velha venceu, apagar ignora o toque repetido e o logout esquece a lista
- `e1b9dd5` test: tela da lista com o desfazer na hora, o andamento do apagar e o aviso do logout
- `d3ca06d` fix: desfazer aparece na hora, apagar mostra andamento sem o menu e o logout tem aviso próprio na tela da lista
- `d1623f7` test: logout fecha as listas mesmo se fechar a Estante falhar
- `46f5ca5` fix: logout fecha as listas mesmo se fechar a Estante falhar
- `bc4276b` docs: política e exclusão com a chave de lista órfã, os emojis e a cópia local das listas; emendas na 019
- `dc7698a` test: abas da Estante rolam mesmo com a fonte normal
- `b722eee` fix: abas da Estante rolam sempre, sem cortar o rótulo com quatro abas
- `365ba94` docs: verificação no emulador das listas e o deploy das regras
- `eacd183` chore: formata o teste das abas roláveis
- (este) docs: fecha sessão 029

## Notas
- **Pendências:** a primeira execução da limpeza mensal (desde a 027) já roda a etapa nova das chaves sem lista; ao publicar a 2.0, levar o `docs/EXCLUSAO-DA-CONTA.md` atualizado para o repositório do suporte. As regras publicadas no projeto real são as desta branch, antes da integração na `main`.
- **Empilhada:** a 029 tem base na `feature/028-nota-e-data`; o PR vai com essa base, como a 026 a 028. Os PRs #21 a #24 esperam o CI destravar.
- **Backlog:** I8 do `security-auditor` (geração no `closeStreams()`) e as sugestões S4 a S7 do `/revisar`.
- **Suítes no fechamento:** `flutter test` com 1868, `firestore/` com 290 no emulador, `gitleaks` 8.21.2 em container sem vazamento.
- **Emulador (`Pixel_9_Pro`, projeto real, conta de teste descartável escolhida pelo usuário, sessão de 2026-11-22):**
  - Regras publicadas antes (`firebase deploy --only firestore:rules --project ja-vi-esse-filme --account` da conta dona; a padrão da CLI deu 403 na 028). Nenhum `PERMISSION_DENIED` no log durante o teste.
  - Aba Listas vazia com "Criar lista"; o diálogo mostra o rótulo e o contador (14/50), e o ✓ do teclado cria. A lista aparece na hora.
  - Detalhes: "Adicionar à lista" abre a folha com a lista; marcar a caixa grava, e o botão vira "Nas suas listas".
  - Tela da lista: o filme aparece pela consulta `orderBy('lists.<id>')` no Firestore real, sem índice manual. Toque longo abre a folha "Tirar da lista"; o filme só da lista sai (documento apagado) e o "Desfazer" aparece na hora e o põe de volta. Renomear pelo menu muda o título. Apagar com o filme dentro passa pelo laço de lotes e volta à aba com "Lista apagada.".
  - **Achado:** com quatro abas, "Quero assistir" saía cortado com a fonte normal. Corrigido com o `TabBar` sempre rolável (teste e override do `estante.md`).
  - Fonte do sistema em 2.0: abas rolam com os rótulos inteiros; diálogo com nome longo (46/50) e linha com reticências, sem overflow; diálogo de apagar com o nome inteiro.
  - Dados de teste apagados pela própria tela (a lista; o filme saiu junto, porque só estava nela). A fonte do emulador voltou a 1.0.
- **Regras (sessão 029):** o `keys().join(',')` existe e serve para validar as chaves do mapa; a junção também confere o tamanho exato, para uma chave com vírgula não se passar por duas. O `size()` de string conta unidades UTF-16 (25 emojis cabem em 50, 26 não), o mesmo que o `length` do Dart.
- **Empilhada:** base na `feature/028-nota-e-data`; o PR vai com essa base, como a 026 a 028 (PRs #21 a #24 esperam o CI destravar).
- **Tamanho:** se a sessão crescer demais, a UI (Estado e UI) pode ir para a 030, com domínio, regras, data e exclusão fechados aqui.

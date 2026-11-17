# Sessão 021 — Fase 2: Modelo dos dados do filme

**Data**: 2026-11-17 · **Branch**: `feature/021-modelo-dados-filme` · **Status**: fechada

## Objetivo
Definir e implementar o documento do filme do usuário em `users/{uid}/movies/{movieId}` (assistido, quero ver, favorito e datas), decidindo se ele guarda cópia do título e do `poster_path` com `cached_at` e renovação no limite de 6 meses dos termos do TMDB. Entrega o domínio, a camada `data` sobre o `cloud_firestore` (fina, atrás de um gateway) e as regras com os testes no emulador. Sem UI: marcar nos detalhes e o login opcional vêm na sessão seguinte.

## Checklist
### Preparação
- [x] Conferir nos termos do TMDB o limite de cache (6 meses) e o que pode ser guardado. **Feito:** §1.C proíbe cache por mais de 6 meses e não proíbe texto nem caminho
- [x] Conferir a versão do `cloud_firestore` no pub.dev. **Feito:** 7.1.0 (2026-10-23, `firebase_core` ^5.1.0); a 7.2.0 tem 1 dia
- [x] Decidir com o usuário cópia, datas e documento sem marcas. **Feito:** decisão 013
- [x] Nome da feature: `lib/features/shelf`

### Regras do Firestore (RED/GREEN/REFACTOR, `firestore/test`)
- [x] Documento válido com o formato novo é aceito
- [x] Chave fora da lista e chave obrigatória ausente negadas (formato novo)
- [x] Tipos errados negados (bool, timestamp, string)
- [x] Cada `<marca>At` ausente, igual ao salvo ou igual a `request.time`; nenhuma marca é negado
- [x] `title` com tamanho máximo, `posterPath` opcional só no formato `/xxx.jpg`
- [x] `cachedAt` só igual a `request.time`, e mudar `title` ou `posterPath` exige renovar

### Domínio (RED/GREEN/REFACTOR)
- [x] Entidade do filme do usuário. **Feito:** `MovieCopy` (id ≥ 1, título cortado em 300 unidades UTF-16 sem partir emoji, pôster fora do formato descartado), `ShelfMark`, `ShelfMovie` (pelo menos uma marca, `marksWithout`) e `ShelfEntry` (`NotOnShelf`/`OnShelf`)
- [x] Regra de "cópia vencida". **Feito:** 180 dias, sempre abaixo dos 6 meses e sem conta de calendário
- [x] Contrato do repositório: `watchMovie`, `addMark` e `removeMark`. **Mudou:** sem falha de "permissão negada", porque `permission-denied` com o dono logado é bug e vira `UnexpectedFailure`. Entrou a `SignInRequiredFailure`, que o login opcional vai usar

### Data (RED/GREEN/REFACTOR)
- [x] Model: documento para `ShelfEntry` com parse defensivo (marca que não é data ignorada, `cachedAt` ilegível conta como vencido, sem `title` dá `FormatException`)
- [x] Model: `markFields` e `unmarkFields` com `FieldWrite` (`SetField`, `ServerTime`, `DeleteField`), sem o `FieldValue` do SDK
- [x] Gateway fino sobre o `cloud_firestore` e o caminho `collection('users').doc(uid).collection('movies').doc('$id')`. **Feito:** sem teste de unidade, porque é só fachada do SDK
- [x] Repositório: tradução das `FirebaseException` só pelo `code`, `not-found` ao desmarcar conta como sucesso, e o `uid` lido na hora da chamada
- [ ] ~~Fake do repositório em `test/helpers/`~~ **Adiado** para o "Marcar", com o formato que os testes do estado pedirem (como o do auth na 019)

### Achados aceitos do `/revisar`
- [x] (1) Corrida do `removeMark` aceita na 013; `permission-denied` no `update` (a marca era a última no servidor) cai para o `delete`. **Mudou:** na consolidação eu tinha proposto tratar o `permission-denied` como "o filme já está fora", mas isso deixaria a marca no servidor. O certo é cair para o `delete`
- [x] (2) Contrato: offline o future fica pendente; a UI segue o `watchMovie` e não espera a escrita; lista de falhas corrigida
- [x] (3) Regras: merge real do `markFields` na criação e sobre documento com pôster; `posterPath: deleteField()` sem renovar o `cachedAt` negado. **Feito:** os 4 testes passaram de primeira (guardas, sem RED)
- [x] (4) Gateway: conversões em `FirestoreFields.read`/`write`, com a hora da data pendente injetada (`pendingAt`) e 8 testes. Só a chamada ao SDK fica sem teste
- [x] (6) Política: texto do prazo de 6 meses fiel ao que o app garante, e limpeza das cópias paradas pelo Admin SDK registrada
- [x] (S1) `not-found` como sucesso só no `removeMark`
- [x] (S2) `on Exception` no lugar do `on Object`, sem engolir `Error`
- [x] (S3) `watchMovie` com `movieId` inválido emite `UnexpectedFailure`, e não `ArgumentError` cru
- [x] (S4) `MovieCopy` recusa id com mais de 10 dígitos
- [x] (S5) Regra recusa `title` só com espaços
- [x] (S6) Registrar na 013 que remarcar renova a data, e o `renewCopy` futuro
- [x] (S8) Teste do `cachedAt` que não é data sem a string gigante
- [x] (S9) Uma asserção por teste no repositório
- [x] (S10) Registrar na 013 que o lock segura as transitivas
- [x] (5, 7, S11) `PLANO.md`: App Check antes de qualquer APK com login, `localhost` fora do Auth e alerta de uso; logout na mesma sessão do "Marcar"; conteúdo da política 2.0
- [x] (S7) Backlog: mensagem própria para a cota do Spark esgotada

### Entrega
- [x] `PLANO.md`: nova ordem (login opcional junto com "Marcar"; logout completo depois do Firestore entrar), e a cópia do TMDB no conteúdo da política 2.0
- [x] Tríade: format, analyze limpo, `flutter test` verde, `npm test` das regras verde. **Feito:** format sem mudança (184 arquivos), analyze limpo, 1000 testes verdes, 72 testes das regras verdes, `flutter build apk --debug` compilando com o plugin nativo
- [x] `/revisar` (`code-reviewer` e `security-auditor`: regras e storage). **Feito:** os achados aceitos estão em "Achados aceitos do `/revisar`"
- [x] `/fechar-sessao`. **Feito:** format sem mudança (186 arquivos), analyze limpo, 1016 testes verdes, 77 testes das regras verdes. O `gitleaks` não está instalado aqui e fica para o CI do PR

## Decisões
- [013 — Documento do filme do usuário no Firestore](../decisoes/013-documento-do-filme-no-firestore.md): cópia de `title` e `posterPath` com `cachedAt` (6 meses); marcas como timestamps `watchedAt`/`watchlistAt`/`favoriteAt`; sem marcas, o documento é apagado; feature `shelf`; `cloud_firestore` 7.1.0; gateway fino, sem `fake_cloud_firestore`.

## Commits
- `96867c9` docs: abre a sessão 021
- `1b2716d` docs: decisão 013, documento do filme no Firestore
- `534bdc5` add: regras do Firestore com o formato do filme da decisão 013
- `c368d85` add: regras do Firestore só aceitam datas do servidor no filme
- `e36d623` add: regras do Firestore limitam o title e o formato do posterPath
- `dbe766c` test: regras contam o title em unidades UTF-16
- `965e06d` add: MovieCopy com o título e o pôster no formato das regras
- `036973f` add: ShelfMovie com as marcas, o que sobra ao tirar uma e a cópia vencida
- `c4b0dd6` add: SignInRequiredFailure para ação que precisa de conta
- `301240c` add: ShelfEntry diz se o filme está na Estante
- `6ca6d8b` chore: cloud_firestore 7.1.0 com as transitivas de 23/10
- `d3c808e` add: contrato do ShelfRepository
- `53e34ed` add: ShelfMovieModel lê o documento do filme com parse defensivo
- `ba89c8e` add: ShelfMovieModel monta a escrita de marcar e desmarcar
- `35a9d72` add: FirestoreShelfRepository com o uid de quem está logado e falhas tipadas
- `e00dc4f` add: CloudFirestoreShelfGateway fino sobre o cloud_firestore
- `74014cd` docs: decisão 013 com a data pendente estimada no gateway
- `0ceca64` docs: plano reordenado, progresso da sessão 021 e backlog do gateway
- `39c5053` test: regras aceitam a escrita real do markFields e negam apagar o pôster sem renovar
- `a4f4207` fix: regras recusam title só com espaços
- `63cc0b1` fix: MovieCopy recusa id com mais de 10 dígitos, como as regras
- `473d23f` fix: removeMark cai para o delete quando a marca já era a última, e Error sobe sem virar falha
- `e22535e` refactor: conversões do gateway da Estante em FirestoreFields, com testes
- `d586f2b` docs: contrato da Estante diz que offline a escrita não falha
- `0ee1907` docs: achados do /revisar na decisão 013, no plano e no log da sessão 021
- `docs: fecha sessão 021` (este fechamento)

## Notas
- Na abertura, com o usuário: o "Login opcional" e o "Logout" do plano dependem de coisas que ainda não existem (nenhuma ação pede conta, e o `cloud_firestore` não está no app). O modelo de dados vem antes; o login opcional entra com "Marcar", e o logout completo depois.
- **Regras:** o JDK padrão da máquina é o 17; os testes rodam com `JAVA_HOME=/usr/lib/jvm/java-21-openjdk`.
- **`size()` das regras conta unidades UTF-16** (testado: 300 `é` passam, 151 emojis não). O domínio corta o `title` em 300 unidades, como o `String.length` do Dart, sem partir um par substituto.
- **`posterPath` nas regras:** `^/[A-Za-z0-9_-]{1,64}[.](jpg|png)$`. Um caminho fora desse formato vai sem `posterPath` (placeholder), e não bloqueia a marca.
- **Transitivas do `cloud_firestore`:** o `pub add` resolveu a `cloud_firestore_platform_interface` 8.2.0 e a `cloud_firestore_web` 5.9.0, que saíram em 2026-11-16. O `flutter pub downgrade` dos dois voltou para a 8.1.0 e a 5.8.0, de 2026-10-23, junto com a 7.1.0. A 7.1.0 fica fixada sem `^` no `pubspec.yaml`.
- **Data pendente offline:** o `snapshots()` público da 7.1.0 não aceita o `ServerTimestampBehavior.estimate`. O gateway troca o `null` pela hora local só com `hasPendingWrites`, e a decisão 013 foi corrigida.
- **Gateway sem teste de unidade:** a conversão `Timestamp` → `DateTime`, o `null` pendente e o `FieldWrite` → `FieldValue` ficam sem cobertura até um teste de integração com o emulador (backlog) ou a verificação no aparelho na sessão do "Marcar".
- **`uid` lido na chamada:** um `watchMovie` aberto continua no `uid` de quando foi assinado. O estado do "Marcar" precisa reassinar quando a conta muda, e o logout precisa cancelar o stream.
- **`/revisar`:** o `code-reviewer` achou 0 bloqueantes, 4 importantes e 10 sugestões; o `security-auditor`, 0 bloqueantes, 3 importantes e 3 sugestões. Todos entraram, como mudança ou como registro (decisão 013, `PLANO.md` e `BACKLOG.md`).
- **Portões novos no `PLANO.md`:** App Check antes de qualquer APK com login, e o logout completo na mesma sessão do "Marcar".
- **Pendências para as próximas sessões:**
  - "Marcar" com o login opcional e o logout completo juntos (portão do `security-auditor`), o `ShelfRepository` montado no `main.dart` e o fake em `test/helpers/`;
  - verificar o `CloudFirestoreShelfGateway` no aparelho (caminho, `merge`, data pendente offline);
  - App Check antes de qualquer APK com login; política 2.0 com a cópia do TMDB e a limpeza pelo Admin SDK decidida;
  - `gitleaks` só no CI.

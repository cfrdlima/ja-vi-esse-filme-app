# Sessão 027 — Fase 2: limpeza mensal do Firestore com o Admin SDK

**Data**: 2026-11-18 · **Branch**: `feature/027-limpeza-mensal` (empilhada na `feature/026-politica-2-0`) · **Status**: fechada

## Objetivo
Criar o script local da decisão 017 em `firestore/`: apagar os dados de `users/{uid}` sem conta no Firebase Authentication e não deixar nenhuma cópia do TMDB com mais de 180 dias, sem perder as marcas. Testado no emulador (Auth e Firestore, projeto `demo-`), com saída só de contagens, e rodado uma vez contra o projeto real pelo usuário. Isso destrava a publicação da política 2.0.

## Checklist
### Preparação
- [x] Conferir no Context7 o `firebase-admin` (versão com pelo menos duas semanas, compatível com Node 22): `auth().listUsers` paginado, `firestore().listDocuments` (documentos pai em itálico), `recursiveDelete` ou `BulkWriter`, `FieldValue.serverTimestamp`, conexão com os emuladores (`FIREBASE_AUTH_EMULATOR_HOST`, `FIRESTORE_EMULATOR_HOST`). **Feito:** 14.5.0 (a 14.5.1 é de 2026-11-12), Node >= 22; `listUsers(max, pageToken)`, `listDocuments` com os pais inexistentes, `recursiveDelete`, `FieldValue.delete`/`serverTimestamp`, `applicationDefault()` com `projectId` explícito
- [x] Decidir com o usuário: o que fazer com a cópia vencida (renovar pelo TMDB no script ou apagar e adaptar regras e app), o que fazer com filme que sumiu do TMDB (404) e a credencial do Admin SDK na máquina dele (ADC do `gcloud` ou chave de conta de serviço fora do repositório). **Decidido:** renovar pelo TMDB, apagar no 404, ADC do `gcloud` (emenda na 017)
- [x] `firebase-admin` no `firestore/package.json` com versão exata e o lock (aprovado pelo usuário); emulador do Auth no `firebase.json` e no `npm test`

### Dados sem conta (RED/GREEN/REFACTOR, no emulador)
- [x] Apaga as subcoleções do `UserCollections` de um `users/{uid}` sem conta no Auth. **Mudou:** `recursiveDelete` do `users/{uid}` inteiro (documento e todas as subcoleções), porque sem conta nada ali vale; 6 testes no emulador
- [x] Não toca em `users/{uid}` com conta
- [x] Acha `users/{uid}` que só existe pelas subcoleções (documento pai inexistente)
- [x] A lista das subcoleções vem do mesmo lugar que o app usa, conferida com as regras (como o `rules-file.test.js`). **Feito:** `cleanup/user-collections.js` compartilhado com os testes das regras; teste de que a subcoleção das cópias está na lista do app

### Cópias vencidas (RED/GREEN/REFACTOR, no emulador)
- [x] Trata a cópia com `cachedAt` de mais de 180 dias conforme a decisão da preparação, mantendo as marcas e um documento válido para as regras e o model do app. **Feito:** renovação pelo TMDB, teste pelas regras de que a próxima marca do app passa; 13 testes no emulador
- [x] Não mexe na cópia dentro do prazo (179 dias não; 180 sim, como o app)
- [x] Falhas tipadas (rede, 429, 404) sem parar a varredura inteira, se a escolha for renovar pelo TMDB. **Feito:** `tmdb-copy.js` com `fetch` falso (13 testes, sem o TMDB real, token fora das mensagens); 404 apaga, 429 para, outras falhas contam e seguem

### Execução
- [x] Entrada única (`npm run cleanup`), que recusa rodar sem projeto explícito e imprime só contagens, nunca `uid`, e-mail, título ou token. **Feito:** `cleanup.js` (argumentos, ordem, relatório; 12 testes) e `run.js`; erro inesperado mostra só o tipo e o código, porque a mensagem do Firestore pode ter o caminho com o `uid`
- [x] Modo de simulação (`--dry-run`) que só conta (fumaça no emulador)
- [x] Instruções curtas (no `firestore/` ou em `dev/`) de como rodar todo mês e onde anotar a execução. **Feito:** `dev/LIMPEZA-MENSAL.md`
- [ ] Primeira execução contra o projeto real, pelo usuário, com a saída (só contagens) no log. **Adiada pelo usuário:** fica para depois do fechamento, registrada em `dev/LIMPEZA-MENSAL.md`

### Entrega
- [x] CI: o job das regras roda os testes novos (emulador do Auth junto). **Feito:** o job já roda `npm test`; o nome `Regras do Firestore` fica, porque o ruleset exige esse check
- [x] `PLANO.md`: item do script marcado; política 2.0 com a limpeza feita. **Mudou:** script pronto, primeira execução pendente no item
- [x] Tríade (format, analyze, `flutter test`), `npm test` em `firestore/` e `gitleaks`. **Feito:** format 0 de 222, analyze limpo, 1398 verdes; 133 verdes no `firestore/`; `gitleaks` em container sem vazamento
- [x] `/revisar` (Admin SDK, credencial, exclusão de dados). **Feito:** `code-reviewer` (1 bloqueante, 6 importantes, 11 sugestões) e `security-auditor` (1 bloqueante, 4 importantes, 7 sugestões)

### Achados aceitos do `/revisar` (o usuário escolheu 404 com o código 34 e parada no quinto, limite de 5 ou 20% e escala no backlog)
- [x] (B1) Recusar variável de emulador e projeto `demo-`; com teste no `parseArgs`
- [x] (B2) Título cortado em 300 unidades UTF-16, sem partir emoji; testes com emojis
- [x] (I1) Travas: Auth vazio não apaga; acima do limite só com `--confirm-orphans <n>`; a simulação avisa
- [x] (I2) Conta criada durante a limpeza: `getUsers` antes de apagar; teste com o Auth que cria a conta no meio
- [x] (I3) 404 só com `status_code: 34`, parada no quinto seguido sem apagar, política e 017 dizem que o filme sai da Estante
- [x] (I4) `NOT_FOUND` pulado, cota e 401 param, JSON ruim vira `TmdbError`, `fetch` com prazo de 10 s, contagens parciais no erro, teto de 5 mil escritas
- [x] (I5) Instruções da credencial: login e `revoke` a cada execução, `unset` das variáveis, `set-quota-project`, `npm ci --omit=dev --ignore-scripts`, token com `read -rs`
- [x] (I6) Teste do `cachedAt` com o `NOW` em 2040 e a hora do servidor perto do `Date.now()`
- [x] Sugestões: simulação sem as cópias dos órfãos, "sem título" fora do código de saída, `deleteApp` no `finally`, lista do app só nos testes, `MOVIES` nos helpers, aviso do `--test-concurrency=1`, ids ao TMDB na política, diferença do título em branco na 017 e no backlog, erro de digitação. **Não entrou:** a credencial falsa nos testes (o Firestore do Admin SDK recusa; os avisos de rede ficam, com comentário)
- [x] (escala) `collectionGroup` com índice no backlog
- [x] `/fechar-sessao`: PR com base na `feature/026-politica-2-0`. **Feito:** format 0 de 222, analyze limpo, 1398 verdes; 168 verdes no `firestore/`; `gitleaks` sem vazamento; `npm audit --omit=dev` com 0

## Decisões
- Emenda na [017](../decisoes/017-limpeza-mensal-com-admin-sdk.md): renovar pelo TMDB, apagar no 404, parar no 429, ADC do `gcloud`, `firebase-admin` 14.5.0.

## Commits
- `8f779e6` docs: abre a sessão 027
- `7ae28fe` chore: firebase-admin 14.5.0, emulador do Auth e lista de subcoleções compartilhada para a limpeza mensal
- `ef7b555` test: cópia do filme pelo TMDB para a limpeza mensal
- `4f1d587` add: cópia do filme pelo TMDB para a limpeza mensal, como o app faz
- `ee524df` test: limpeza mensal apaga os dados de users/{uid} sem conta no Auth
- `acda3ec` add: limpeza mensal apaga os dados de users/{uid} sem conta no Auth
- `50f1b63` test: limpeza mensal renova as cópias vencidas do TMDB e apaga os filmes que sumiram
- `33d5a72` add: limpeza mensal renova as cópias vencidas do TMDB e apaga os filmes que sumiram
- `2571c2b` test: argumentos, relatório e ordem da limpeza mensal
- `b5a4e2b` add: argumentos, relatório só com contagens e ordem da limpeza mensal
- `a536a2d` add: entrada npm run cleanup da limpeza mensal e instruções do mês
- `a6cb503` test: simulação diz encontrados e as cópias ficam numa subcoleção que o app conhece
- `e20654d` refactor: simulação diz encontrados e a subcoleção dos filmes amarrada à lista do app
- `c924c51` docs: emenda na decisão 017 com as escolhas da implementação e andamento da sessão 027
- `3aab68c` test: título em UTF-16, 404 só com o código 34, 401 e resposta que não é JSON na cópia do TMDB
- `74a442b` fix: cópia do TMDB corta o título em UTF-16, só trata como sumido o 404 com o código 34 e tem prazo
- `8e582ed` test: renovação das cópias para no 401, na sequência de 404, na cota e no teto de escritas, e pula o filme desmarcado
- `c1dae3b` fix: renovação das cópias para no 401, na sequência de 404, na cota e no teto de escritas, e pula o filme desmarcado
- `e5d5544` test: travas da limpeza dos dados sem conta (Auth vazio, limite com confirmação, conta criada durante a limpeza)
- `dc7f426` fix: limpeza dos dados sem conta recusa Auth vazio, pede confirmação acima do limite e confere a conta antes de apagar
- `41af7c3` test: limpeza recusa emulador e projeto demo-, lê a confirmação, explica as paradas e leva o relatório parcial no erro
- `2d5588e` fix: limpeza recusa emulador e projeto demo-, pede a confirmação dos dados sem conta, explica as paradas e leva o relatório parcial no erro
- `c6aa474` fix: entrada da limpeza com a confirmação, o relatório parcial no erro e o deleteApp no fim
- `c199011` refactor: lista do app só nos testes, MOVIES nos helpers e aviso do --test-concurrency=1
- `c597ec6` docs: instruções seguras da limpeza mensal, emenda na 017 e política com o filme que sumiu do TMDB
- (este) docs: fecha sessão 027

## Notas
- **Empilhada:** 025 (PR #21) e 026 (PR #22) esperam o CI destravar (cobrança da conta no GitHub).
- **JDK:** o padrão da máquina é o 17; os testes do `firestore/` rodam com `JAVA_HOME=/usr/lib/jvm/java-21-openjdk`.
- **Suíte do `firestore/`:** 133 verdes (89 das regras e 44 da limpeza).
- **Suíte do `firestore/` depois dos achados:** 168 verdes (89 das regras e 79 da limpeza).
- **Pendências:** primeira execução da limpeza pelo usuário (`dev/LIMPEZA-MENSAL.md`), que destrava a publicação da 2.0 junto com o S7 e o aceite dos termos de tratamento de dados no console. Integração das 025, 026 e 027 espera o CI destravar.

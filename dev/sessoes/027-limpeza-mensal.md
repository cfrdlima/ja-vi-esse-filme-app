# Sessão 027 — Fase 2: limpeza mensal do Firestore com o Admin SDK

**Data**: 2026-11-18 · **Branch**: `feature/027-limpeza-mensal` (empilhada na `feature/026-politica-2-0`) · **Status**: aberta

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
- [ ] Primeira execução contra o projeto real, pelo usuário, com a saída (só contagens) no log

### Entrega
- [x] CI: o job das regras roda os testes novos (emulador do Auth junto). **Feito:** o job já roda `npm test`; o nome `Regras do Firestore` fica, porque o ruleset exige esse check
- [ ] `PLANO.md`: item do script marcado; política 2.0 com a limpeza feita
- [x] Tríade (format, analyze, `flutter test`), `npm test` em `firestore/` e `gitleaks`. **Feito:** format 0 de 222, analyze limpo, 1398 verdes; 133 verdes no `firestore/`; `gitleaks` em container sem vazamento
- [ ] `/revisar` (Admin SDK, credencial, exclusão de dados)
- [ ] `/fechar-sessao`: PR com base na `feature/026-politica-2-0`

## Decisões
- Emenda na [017](../decisoes/017-limpeza-mensal-com-admin-sdk.md): renovar pelo TMDB, apagar no 404, parar no 429, ADC do `gcloud`, `firebase-admin` 14.5.0.

## Commits

## Notas
- **Empilhada:** 025 (PR #21) e 026 (PR #22) esperam o CI destravar (cobrança da conta no GitHub).
- **JDK:** o padrão da máquina é o 17; os testes do `firestore/` rodam com `JAVA_HOME=/usr/lib/jvm/java-21-openjdk`.
- **Suíte do `firestore/`:** 133 verdes (89 das regras e 44 da limpeza).

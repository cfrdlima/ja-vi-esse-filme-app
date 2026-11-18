# Sessão 027 — Fase 2: limpeza mensal do Firestore com o Admin SDK

**Data**: 2026-11-18 · **Branch**: `feature/027-limpeza-mensal` (empilhada na `feature/026-politica-2-0`) · **Status**: aberta

## Objetivo
Criar o script local da decisão 017 em `firestore/`: apagar os dados de `users/{uid}` sem conta no Firebase Authentication e não deixar nenhuma cópia do TMDB com mais de 180 dias, sem perder as marcas. Testado no emulador (Auth e Firestore, projeto `demo-`), com saída só de contagens, e rodado uma vez contra o projeto real pelo usuário. Isso destrava a publicação da política 2.0.

## Checklist
### Preparação
- [ ] Conferir no Context7 o `firebase-admin` (versão com pelo menos duas semanas, compatível com Node 22): `auth().listUsers` paginado, `firestore().listDocuments` (documentos pai em itálico), `recursiveDelete` ou `BulkWriter`, `FieldValue.serverTimestamp`, conexão com os emuladores (`FIREBASE_AUTH_EMULATOR_HOST`, `FIRESTORE_EMULATOR_HOST`)
- [ ] Decidir com o usuário: o que fazer com a cópia vencida (renovar pelo TMDB no script ou apagar e adaptar regras e app), o que fazer com filme que sumiu do TMDB (404) e a credencial do Admin SDK na máquina dele (ADC do `gcloud` ou chave de conta de serviço fora do repositório)
- [ ] `firebase-admin` no `firestore/package.json` com versão exata e o lock (aprovado pelo usuário); emulador do Auth no `firebase.json` e no `npm test`

### Dados sem conta (RED/GREEN/REFACTOR, no emulador)
- [ ] Apaga as subcoleções do `UserCollections` de um `users/{uid}` sem conta no Auth
- [ ] Não toca em `users/{uid}` com conta
- [ ] Acha `users/{uid}` que só existe pelas subcoleções (documento pai inexistente)
- [ ] A lista das subcoleções vem do mesmo lugar que o app usa, conferida com as regras (como o `rules-file.test.js`)

### Cópias vencidas (RED/GREEN/REFACTOR, no emulador)
- [ ] Trata a cópia com `cachedAt` de mais de 180 dias conforme a decisão da preparação, mantendo as marcas e um documento válido para as regras e o model do app
- [ ] Não mexe na cópia dentro do prazo
- [ ] Falhas tipadas (rede, 429, 404) sem parar a varredura inteira, se a escolha for renovar pelo TMDB

### Execução
- [ ] Entrada única (`npm run cleanup`), que recusa rodar sem projeto explícito e imprime só contagens, nunca `uid`, e-mail, título ou token
- [ ] Modo de simulação (`--dry-run`) que só conta
- [ ] Instruções curtas (no `firestore/` ou em `dev/`) de como rodar todo mês e onde anotar a execução
- [ ] Primeira execução contra o projeto real, pelo usuário, com a saída (só contagens) no log

### Entrega
- [ ] CI: o job das regras roda os testes novos (emulador do Auth junto)
- [ ] `PLANO.md`: item do script marcado; política 2.0 com a limpeza feita
- [ ] Tríade (format, analyze, `flutter test`), `npm test` em `firestore/` e `gitleaks`
- [ ] `/revisar` (Admin SDK, credencial, exclusão de dados)
- [ ] `/fechar-sessao`: PR com base na `feature/026-politica-2-0`

## Decisões

## Commits

## Notas
- **Empilhada:** 025 (PR #21) e 026 (PR #22) esperam o CI destravar (cobrança da conta no GitHub).

# Sessão 017 — Fase 2: regras do Firestore

**Data**: 2026-11-17 · **Branch**: `feature/017-regras-firestore` · **Status**: aberta

## Objetivo
Versionar o `firestore.rules` com tudo negado por padrão e só o dono acessando `users/{uid}/movies/{movieId}`, com validação mínima (id numérico, chaves permitidas, tamanho). As regras são testadas no Emulator Suite com `@firebase/rules-unit-testing` e `node:test`, localmente e num job novo do CI. Vem antes do login e de qualquer escrita.

## Checklist
### Preparação
- [ ] Pré-requisito do usuário: ligar a proteção contra enumeração de e-mail no Auth (pendência da sessão 016)
- [x] Conferir no Context7/npm as versões de `@firebase/rules-unit-testing`, `firebase` e `firebase-tools`, e a versão de Java que o emulador do Firestore exige. **Feito:** `rules-unit-testing` 5.0.2 (a 6.0.0 pede Node ≥ 24.12), `firebase` 12.19.0, `firebase-tools` 15.34.2 e JDK 21
- [x] Decisão 012: ferramenta de teste das regras (npm em `firestore/`, `node:test`, versões fixadas, job no CI)
- [x] `firebase.json` com `firestore.rules` e o emulador; `firestore/package.json` + `package-lock.json`; `node_modules/` no `.gitignore`
- [x] Ciclo de fumaça: emulador sobe e um teste trivial roda com `firebase emulators:exec`

### Regras (RED/GREEN por comportamento)
- [x] RED/GREEN: acesso sem login a `users/{uid}/movies/{id}` negado (leitura e escrita)
- [x] RED/GREEN: dono lê e escreve o próprio `users/{uid}/movies/{id}`
- [x] RED/GREEN: leitura e escrita no `uid` de outro usuário negadas
- [x] RED/GREEN: dono apaga os próprios documentos
- [x] RED/GREEN: `collectionGroup('movies')` negado
- [x] RED/GREEN: caminho fora de `users/{uid}/movies` negado (raiz, `users/{uid}` e subcoleção não listada)
- [x] RED/GREEN: `movieId` não numérico negado
- [x] RED/GREEN: chave fora da lista permitida negada
- [x] RED/GREEN: documento acima do tamanho máximo negado. **Feito** por chaves obrigatórias e tipos booleanos fechados (chave ausente, tipo errado e string de 100 mil caracteres negados). As regras não medem o tamanho em bytes
- [x] RED/GREEN: o arquivo de regras não tem `match /{document=**}` com `allow` (teste estático)
- [x] REFACTOR: funções nomeadas nas regras (`isOwner`, `hasOnlyAllowedKeys`…), mantendo o verde

### Entrega
- [x] CI: job `firestore-rules` com Node, Java e `firebase-tools` fixados, rodando os testes no emulador
- [x] Publicar as regras no projeto (`firebase deploy --only firestore:rules`), com confirmação do usuário. **Feito** com a `firebase-tools` 15.34.2 local, `--project ja-vi-esse-filme` e `--account` da conta do projeto. A leitura sem login via REST no projeto real dá `PERMISSION_DENIED`, tanto em `users/alice/movies/550` quanto fora de `users`
- [x] `CLAUDE.md` (comandos) e `README.md` com como rodar os testes das regras
- [x] Tríade: `flutter analyze`, `flutter test`, testes das regras, `gitleaks`. **Feito:** format ok, analyze limpo, 741 testes Flutter, 25 testes das regras e gitleaks git sem vazamento (336 commits)
- [x] `security-auditor` (a sessão toca as regras de acesso). **Aprovado**, sem achado crítico ou alto. M2, B1 e B2 corrigidos na sessão; M1 e B3 registrados (ver Notas)
- [ ] `/fechar-sessao`

## Decisões
- [012 — Testes das regras do Firestore com rules-unit-testing e node:test](../decisoes/012-testes-das-regras-do-firestore.md)

## Commits

## Notas
- Os testes de negação passaram de primeira, porque a regra que os satisfaz já existia. Para provar que eles pegam o erro, os 10 rodaram contra uma regra mutante (`match /{document=**}` com `if true`) e todos falharam. O teste estático também falhou contra um mutante.
- O primeiro RED falhou pelo motivo errado: um `match` sem nenhum `allow` não compila ("The 'match' body must contain at least one declaration"). A base passou a ser `allow read, write: if false` no caminho dos filmes.
- O `flutter analyze` local acusou 6 erros num template Dart de `firestore/node_modules/firebase-tools/templates/`. A pasta foi excluída no `analysis_options.yaml`. No CI, o job Flutter não instala o npm.
- A instalação usa `--ignore-scripts`. Os testes rodam sem nenhum script de pós-instalação.
- O `gitleaks` 8.30.1 foi baixado de novo no scratchpad, com o checksum do CI.
- Achados do `security-auditor`:
  - (médio, M1) A cota do Spark pode ser esgotada por quem tira a chave do APK e grava em loop no próprio `uid`, e leituras negadas também contam. As regras não resolvem isso. O risco já está aceito nas decisões 010 e 011, e o App Check com enforcement continua obrigatório na Fase 4.
  - (médio, M2) Faltavam testes de negação para listagem, consulta filtrada, exclusão e atualização por terceiro ou sem login, `collectionGroup` sem login, leitura numa subcoleção não listada e, no `update`, remover uma chave obrigatória ou trocar o tipo. **Corrigido** (`b11eb4b`), com prova por mutação.
  - (baixo, B1) O teste estático não pegava `allow` sem `if`. **Corrigido** no mesmo commit.
  - (baixo, B2) As regras não exigiam o provedor Google. **Corrigido** (`798d105`) com `sign_in_provider == 'google.com'` no `isOwner`, em RED/GREEN.
  - (baixo, B3) O jar do emulador vem do cache do CI. Risco aceito e registrado na decisão 012.
  - (info) Deploy sempre com `--project ja-vi-esse-filme` explícito e sem `.firebaserc` (decisão 012).
- A conta padrão da CLI nesta máquina não enxerga o projeto. O usuário rodou o `firebase login:add` num terminal próprio, porque o `!` do Claude Code não é interativo, e o deploy foi feito com `--account`, sem trocar a conta padrão.

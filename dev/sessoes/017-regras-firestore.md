# Sessão 017 — Fase 2: regras do Firestore

**Data**: 2026-11-17 · **Branch**: `feature/017-regras-firestore` · **Status**: aberta

## Objetivo
Versionar o `firestore.rules` com tudo negado por padrão e só o dono acessando `users/{uid}/movies/{movieId}`, com validação mínima (id numérico, chaves permitidas, tamanho). As regras são testadas no Emulator Suite com `@firebase/rules-unit-testing` e `node:test`, localmente e num job novo do CI. Vem antes do login e de qualquer escrita.

## Checklist
### Preparação
- [ ] Pré-requisito do usuário: ligar a proteção contra enumeração de e-mail no Auth (pendência da sessão 016)
- [ ] Conferir no Context7/npm as versões de `@firebase/rules-unit-testing`, `firebase` e `firebase-tools`, e a versão de Java que o emulador do Firestore exige
- [ ] Decisão 012: ferramenta de teste das regras (npm em `firestore/`, `node:test`, versões fixadas, job no CI)
- [ ] `firebase.json` com `firestore.rules` e o emulador; `firestore/package.json` + `package-lock.json`; `node_modules/` no `.gitignore`
- [ ] Ciclo de fumaça: emulador sobe e um teste trivial roda com `firebase emulators:exec`

### Regras (RED/GREEN por comportamento)
- [ ] RED/GREEN: acesso sem login a `users/{uid}/movies/{id}` negado (leitura e escrita)
- [ ] RED/GREEN: dono lê e escreve o próprio `users/{uid}/movies/{id}`
- [ ] RED/GREEN: leitura e escrita no `uid` de outro usuário negadas
- [ ] RED/GREEN: dono apaga os próprios documentos
- [ ] RED/GREEN: `collectionGroup('movies')` negado
- [ ] RED/GREEN: caminho fora de `users/{uid}/movies` negado (raiz, `users/{uid}` e subcoleção não listada)
- [ ] RED/GREEN: `movieId` não numérico negado
- [ ] RED/GREEN: chave fora da lista permitida negada
- [ ] RED/GREEN: documento acima do tamanho máximo negado
- [ ] RED/GREEN: o arquivo de regras não tem `match /{document=**}` com `allow` (teste estático)
- [ ] REFACTOR: funções nomeadas nas regras (`isOwner`, `hasOnlyAllowedKeys`…), mantendo o verde

### Entrega
- [ ] CI: job `firestore-rules` com Node, Java e `firebase-tools` fixados, rodando os testes no emulador
- [ ] Publicar as regras no projeto (`firebase deploy --only firestore:rules`), com confirmação do usuário
- [ ] `CLAUDE.md` (comandos) e `README.md` com como rodar os testes das regras
- [ ] Tríade: `flutter analyze`, `flutter test`, testes das regras, `gitleaks`
- [ ] `security-auditor` (a sessão toca as regras de acesso)
- [ ] `/fechar-sessao`

## Decisões

## Commits

## Notas

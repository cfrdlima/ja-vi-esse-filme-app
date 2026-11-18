# Sessão 024 — Fase 2: excluir a conta pelo app

**Data**: 2026-11-18 · **Branch**: `feature/024-excluir-conta` · **Status**: aberta

## Objetivo
Excluir a conta pelo app, na ordem da decisão 010: login recente, os documentos das subcoleções de uma lista fixa (esperando o servidor confirmar), `user.delete()`, `disconnect()` do Google e a limpeza local. Também fica registrado em decisão o mecanismo da exclusão pela web (página com o Firebase JS ou pedido por formulário/e-mail), que é implementado na sessão 025.

## Checklist
### Preparação
- [ ] Conferir no Context7: `reauthenticateWithCredential` e `user.delete()` (`firebase_auth`), `disconnect()` (`google_sign_in` 7.x), `WriteBatch` (limite de 500) e `get(GetOptions(source: Source.server))` (`cloud_firestore` 7.1.0)
- [ ] Decidir com o usuário: como garantir o login recente (reautenticar sempre antes de apagar?), o prazo da exclusão offline e se o `integration_test` do gateway contra o emulador entra agora
- [ ] Decisão do mecanismo da exclusão pela web (`/decisao`)
- [ ] Consultar a `ui-ux-pro-max` (stack Flutter) para a confirmação destrutiva no Perfil e gerar o override se precisar

### Domínio (RED/GREEN/REFACTOR)
- [ ] Lista fixa das subcoleções de `users/{uid}` (`movies`) num lugar só, usada pela exclusão

### Data (RED/GREEN/REFACTOR)
- [ ] Gateway da exclusão dos documentos: lê `users/{uid}/movies` do servidor e apaga em lotes até não sobrar nada, esperando a confirmação, com prazo
- [ ] `FirebaseAuthGateway`: reautenticar com o `idToken` e `delete()`; `GoogleAccountGateway`: `disconnect()`
- [ ] Repositório: login recente → documentos → `user.delete()` → `disconnect()` → limpeza local; sem login recente, `RecentLoginRequiredFailure` sem apagar nada
- [ ] Repositório: falhas tipadas (seletor cancelado, sem rede ou prazo esgotado, `requires-recent-login`, erro do SDK sem `message`/`email`/`credential`); repetir depois de uma falha no meio termina a exclusão
- [ ] Regras: testes no emulador de que o dono apaga todos os documentos e não sobra nada em `users/{uid}`, de que outro `uid` não apaga, e de que a lista fixa bate com as coleções das regras (`rules-file.test.js`)

### Estado (RED/GREEN/REFACTOR)
- [ ] `SessionNotifier.deleteAccount`: estado "excluindo", sucesso (deslogado), falha com "tentar de novo"; guarda contra chamada dupla e contra login/logout em andamento
- [ ] Estante sai de cena quando a exclusão começa, como no logout

### UI (RED/GREEN/REFACTOR, widget tests)
- [ ] "Excluir conta" no Perfil, com diálogo de confirmação explícita (o que é apagado, sem volta), progresso, erro com "tentar de novo", strings no ARB, `Semantics`, alvo ≥ 48dp, fonte grande

### Composição
- [ ] Gateways novos montados no `main.dart`; fakes em `test/helpers/` atualizados

### Entrega
- [ ] Tríade: format, analyze limpo, `flutter test`; `npm test` das regras (deploy se `firestore.rules` mudar)
- [ ] Emulador, **com conta Google de teste descartável**: excluir com marcas na Estante, conferir no console que não sobrou nada em `users/{uid}` nem no Auth; cancelar o seletor da reautenticação; exclusão offline
- [ ] `PLANO.md` (item da exclusão e política 2.0) e `docs/PRIVACIDADE.md` se o texto mudar
- [ ] `/revisar` (`code-reviewer` e `security-auditor`: auth, storage, rede)
- [ ] `/fechar-sessao`

## Decisões

## Commits

## Notas

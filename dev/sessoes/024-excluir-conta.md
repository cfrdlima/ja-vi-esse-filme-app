# Sessão 024 — Fase 2: excluir a conta pelo app

**Data**: 2026-11-18 · **Branch**: `feature/024-excluir-conta` · **Status**: aberta

## Objetivo
Excluir a conta pelo app, na ordem da decisão 010: login recente, os documentos das subcoleções de uma lista fixa (esperando o servidor confirmar), `user.delete()`, `disconnect()` do Google e a limpeza local. Também fica registrado em decisão o mecanismo da exclusão pela web (página com o Firebase JS ou pedido por formulário/e-mail), que é implementado na sessão 025.

## Checklist
### Preparação
- [x] Conferir no Context7: `reauthenticateWithCredential` e `user.delete()` (`firebase_auth`), `disconnect()` (`google_sign_in` 7.x), `WriteBatch` (limite de 500) e `get(GetOptions(source: Source.server))` (`cloud_firestore` 7.1.0). **Feito:** `requires-recent-login` e `user-mismatch`; lote de até 500; `Source.server` offline falha com `unavailable`; o `disconnect()` do Android só revoga contas do mesmo processo (ver decisão 015)
- [x] Decidir com o usuário: como garantir o login recente (reautenticar sempre antes de apagar?), o prazo da exclusão offline e se o `integration_test` do gateway contra o emulador entra agora. **Decidido:** reautenticar sempre; 15 s por passo; `integration_test` no backlog
- [x] Decisão do mecanismo da exclusão pela web (`/decisao`). **Feito:** decisão 015, pedido por e-mail
- [x] Consultar a `ui-ux-pro-max` (stack Flutter) para a confirmação destrutiva no Perfil e gerar o override se precisar. **Feito:** seção "Excluir a conta" e dois estados no `pages/perfil.md`; nada na stack Flutter (fallback Material 3)

### Lista fixa (RED/GREEN/REFACTOR)
- [x] Lista fixa das subcoleções de `users/{uid}` (`movies`) num lugar só, usada pela exclusão e pelo gateway da Estante. **Mudou:** fica em `core/firestore`, e não no `domain`, porque nome de coleção é detalhe do Firestore; um teste das regras (Node) confere que ela bate com os `match` do `firestore.rules`. **Feito:** `UserCollections`; mutação com a lista vazia faz o teste falhar; o `describe` que lê arquivo sai com 0 mesmo quebrado (ver "Notas")

### Data (RED/GREEN/REFACTOR)
- [x] Gateway da exclusão dos documentos: lê `users/{uid}/movies` do servidor e apaga em lotes até não sobrar nada, esperando a confirmação, com prazo. **Feito:** `FirestoreAccountDocuments` (laço, lote de 500 e prazo, 11 testes com `fakeAsync`); as chamadas do SDK entram na composição
- [x] `FirebaseAuthGateway`: reautenticar com o `idToken` e `delete()`; `GoogleAccountGateway`: `disconnect()`. **Feito:** repasse direto ao SDK, sem teste próprio (como os outros gateways do SDK); o `cloudFirestoreAccountDocuments` monta a leitura do servidor e o `WriteBatch`
- [x] Repositório: login recente → documentos → `user.delete()` → `disconnect()` → limpeza local; sem login recente, `RecentLoginRequiredFailure` sem apagar nada. **Feito:** o `deleteAccount` devolve `AccountDeleted` ou `AccountDeletionCancelled`; falhas depois do `user.delete()` vão para o `ErrorReporter` injetado
- [x] Repositório: falhas tipadas (seletor cancelado, sem rede ou prazo esgotado, `requires-recent-login`, erro do SDK sem `message`/`email`/`credential`); repetir depois de uma falha no meio termina a exclusão. **Feito:** `AccountMismatchFailure` nova (com texto no ARB); `TimeoutException` e `unavailable` do Firestore viram `NetworkFailure`; 22 testes
- [x] Regras: testes no emulador de que o dono apaga todos os documentos e não sobra nada em `users/{uid}`, de que outro `uid` não apaga, e de que a lista fixa bate com as coleções das regras (`rules-file.test.js`) **Feito:** `account-deletion.test.js` com o mesmo laço do gateway (6 testes, 88 verdes); conferido por mutação (sem `delete` nas regras, 4 falham); regras sem mudança

### Estado (RED/GREEN/REFACTOR)
- [x] `SessionNotifier.deleteAccount`: estado "excluindo", sucesso (deslogado), falha com "tentar de novo"; guarda contra chamada dupla e contra login/logout em andamento. **Feito:** `SessionDeletingAccount`, `SessionDeleteAccountFailed` (fora do `SessionFailed`, porque a conta continua) e `SessionAccountDeleted` (subtipo do deslogado, com o aviso no Perfil no lugar do `SnackBar`); o `SignedOut` do `user.delete()` fica guardado até o fim, como no login; 16 testes
- [x] Estante sai de cena quando a exclusão começa, como no logout. **Feito:** skeleton "Excluindo a conta" durante a exclusão, abas de volta na falha, convite depois; 5 widget tests, conferidos por mutação

### UI (RED/GREEN/REFACTOR, widget tests)
- [x] "Excluir conta" no Perfil, com diálogo de confirmação explícita (o que é apagado, sem volta), progresso, erro com "tentar de novo", strings no ARB, `Semantics`, alvo ≥ 48dp, fonte grande. **Feito:** `DeleteAccountSection` e `DeleteAccountDialog`; `SignOutButton.disabled`; aviso no `SignedOutPanel`; 23 widget tests e os 3 estados novos no "em todos os estados" (fonte 2x, 48dp, contraste AA). **Achado:** sair depois de uma exclusão que falhou não esperava o servidor; corrigido com teste no notifier

### Composição
- [x] Gateways novos montados no `main.dart`; fakes em `test/helpers/` atualizados. **Feito:** `cloudFirestoreAccountDocuments` e o `logUnhandledError` no `FirebaseAuthRepository`; `FakeAuthRepository` com exclusão pendente

### Achados aceitos do `/revisar` (o usuário seguiu a recomendação)
- [x] (1) Nenhuma marca grava durante a exclusão: escritas da Estante travadas antes do `deleteAll`, espera das escritas pendentes, e teste de que a marca no meio é recusada. **Feito:** `UserDataWriteLock` em `core/firestore`, compartilhado pelo `main.dart`; a conta trava, espera as pendentes (15 s) e destrava no `finally`; a Estante recusa com `UnexpectedFailure`; 10 testes
- [x] (3) Prazo nos passos depois do `user.delete()` (`disconnect()` e limpeza), com a falha só registrada; teste com o `disconnect()` que não responde. **Feito:** `timeout` de 15 s em cada passo do `_finishDeletion`, o `TimeoutException` registrado como `NetworkFailure`; 4 testes com `fakeAsync`
- [x] (6) `deadline-exceeded` do Firestore como `NetworkFailure`; `user-not-found` e `user-token-expired` na reautenticação como `AccountDisabledFailure`. **Mudou:** `user-token-expired` virou `RecentLoginRequiredFailure` ("entre de novo"), que descreve melhor do que "conta desativada"; 3 testes
- [x] (8) Teste da lista fixa falha com qualquer `match` fora de `/users/{uid}/<nome>/{…}`; item das listas no `PLANO.md` cita a exclusão aninhada. **Feito:** conferido por mutação (`{userId}` derruba 3 testes)
- [ ] (10) Testes do `SignedIn` que chega durante a exclusão e da foto saindo do cache no `SessionAccountDeleted`
- [x] (11) Tirar o nome da conta de teste do log
- [ ] (2, 4, 5, 7, 9) Registrar: o `delete()` sem prazo próprio (decisão 015 corrigida); outros aparelhos e a varredura do Admin SDK (`PLANO.md`/`BACKLOG.md`); o que a política 2.0 declara; o lote que fica na fila depois do prazo (015 e "Notas"); dois estados (reautenticando e apagando) no `BACKLOG.md`

### Entrega
- [x] Tríade: format, analyze limpo, `flutter test`; `npm test` das regras (deploy se `firestore.rules` mudar). **Feito:** format sem mudança, analyze limpo, 1375 verdes; 88 verdes nas regras; `firestore.rules` sem mudança, sem deploy
- [x] Emulador, **com conta Google de teste descartável**: excluir com marcas na Estante, conferir no console que não sobrou nada em `users/{uid}` nem no Auth; cancelar o seletor da reautenticação; exclusão offline. **Feito:** ver "Notas"; o usuário conferiu no console que o Firestore ficou sem documentos e a conta de teste sumiu do Authentication. A exclusão offline aparece como cancelamento (ver "Notas")
- [x] `PLANO.md` (item da exclusão e política 2.0) e `docs/PRIVACIDADE.md` se o texto mudar. **Feito:** o item da exclusão foi dividido (app feito, web na 025, com o portão do Play) e a política 2.0 ganhou a exclusão; o `PRIVACIDADE.md` não mudou (a 2.0 cobre); 4 itens novos no `BACKLOG.md`
- [ ] `/revisar` (`code-reviewer` e `security-auditor`: auth, storage, rede)
- [ ] `/fechar-sessao`

## Decisões
- [015](../decisoes/015-exclusao-da-conta.md): reautenticar sempre antes de apagar, lotes de 500 lidos do servidor, prazo de 15 s por passo, lista fixa das subcoleções e, na web, pedido por e-mail (sessão 025). Complementa a [010](../decisoes/010-conta-propria-com-firebase.md)

## Commits

## Notas
- **`node --test` e erro no `describe`** (Node 22): uma exceção no corpo do `describe` (ex.: `readFileSync` de arquivo que não existe) aparece como `not ok` da suíte, mas não conta em `fail`, e o processo sai com 0. Leitura de arquivo vai dentro do `test`.
- **Emulador (`Pixel_9_Pro`, Android 16, projeto real, conta de teste descartável autorizada pelo usuário):** o "Excluir conta" aparecia centralizado e foi corrigido (commit `fix:`); "Cancelar" no diálogo e o voltar no seletor do Google voltam à conta sem apagar nada; com 3 filmes marcados e a rede ligada, escolher a conta no seletor mostra "Excluindo a conta" com o "Sair" desabilitado e termina em "Sua conta foi excluída.", com a Estante de volta ao convite; nenhum erro do `disconnect()` nem da limpeza no log.
- **Offline, o seletor parece cancelamento:** com modo avião, o seletor abre com as contas do aparelho, mas, depois de escolher a conta, o Play Services devolve `GetCredentialCancellationException`, que o `google_sign_in_android` 7.2.19 traduz para `canceled`. O app trata como "fechou o seletor" (decisão 015): volta à conta sem mensagem e sem apagar nada. O código é o mesmo do cancelamento de verdade, e a `description` não é usada (privacidade), então o Dart não separa os dois. O mesmo vale para o login offline desde a sessão 019. O prazo de 15 s dos lotes ficou só nos testes com `fakeAsync`.
- **`disconnect()` revoga todas as contas do processo** (`google_sign_in_android` 7.2.19, `_cachedAccounts`): uma conta escolhida antes no seletor (um `user-mismatch`, ou uma troca de conta sem reabrir o app) também perde a autorização do app quando a exclusão termina no mesmo processo. Não apaga dados dela; ela só precisa autorizar de novo no próximo login. Por isso o `user-mismatch` não foi testado no aparelho com as contas pessoais (fica nos testes de unidade).
- **Seletor do Google com o logo do Flutter:** vem da marca da tela de consentimento OAuth no Google Cloud, não do código. Para a Fase 4 (ícone e nome do app).


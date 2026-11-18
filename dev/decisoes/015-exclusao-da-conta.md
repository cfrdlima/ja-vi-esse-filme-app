# 015 — Exclusão da conta: reautenticar antes, prazo por passo e pedido por e-mail na web

**Data**: 2026-11-18 · **Status**: aceita

## Contexto
A decisão 010 fixou a ordem da exclusão pelo app: login recente, depois os documentos das subcoleções de uma lista fixa (com o servidor confirmando), `user.delete()`, `disconnect()` do Google e a limpeza local. Ela deixou para a sessão da exclusão o mecanismo da página na web, que o Google Play exige. A decisão 011 manteve o plano Spark, que não tem Cloud Functions.

O que pesou na sessão 024:
- **Login recente:** o `user.delete()` falha com `requires-recent-login` se o login for antigo (documentação do `firebase_auth` 7.1.0). Se o app só descobrir isso no `delete()`, os documentos já foram apagados e a conta fica viva e vazia. O contrato do `AuthRepository` (sessão 018) pede a falha **antes** de apagar qualquer documento.
- **`disconnect()` no Android** (`google_sign_in_android` 7.2.19): ele só revoga as contas autenticadas no mesmo processo (`_cachedAccounts`). Depois de reabrir o app, a conta logada não está nesse cache, e o `disconnect()` não revoga nada.
- **Offline:** o `commit()` de um `WriteBatch` só completa quando o servidor confirma, e o `get(GetOptions(source: Source.server))` falha com `unavailable` sem rede. Sem prazo, a exclusão pode ficar pendente para sempre.
- **Lote:** um `WriteBatch` aceita no máximo 500 escritas.
- **SDK do cliente:** ele não lista subcoleções nem apaga em cascata (decisão 010).
- **Web:** uma página com o Firebase JS repetiria a exclusão, mas pediria o domínio do Pages autorizado no Auth, a Browser key em uso e restrita por referrer, o SDK do `gstatic` com versão fixa, CSP e testes. O Play aceita um pedido de exclusão pela web, sem que ela seja automática.

## Opções consideradas
Sobre o login recente:
1. **Reautenticar sempre**, abrindo o seletor do Google e chamando o `reauthenticateWithCredential` antes de apagar qualquer coisa.
2. **Tentar o `delete()` e reautenticar só no `requires-recent-login`.** Apaga os documentos antes de saber se o `delete()` vai passar.

Sobre o prazo offline:
1. **15 s por passo** (leitura do servidor, cada lote, `delete()`).
2. **5 s**, o mesmo do `syncTimeout` (sessão 022). Pode desistir à toa numa rede lenta.

Sobre a web:
1. **Página no Pages com o Firebase JS** e o login do Google, fazendo a mesma exclusão.
2. **Pedido por e-mail**, com uma página no Pages explicando o passo a passo, e a exclusão feita pelo dono do projeto no console.
3. **Pedido por formulário (Google Forms).** Não prova quem pede, e a confirmação ainda iria por e-mail.

Sobre a prova de que nada sobra:
1. **Testes das regras no emulador (Node), fakes do gateway e conferência no console** na verificação no aparelho.
2. **`integration_test` do gateway real contra o emulador.** É uma `dev_dependency` nova, e pede setup no CI.

## Decisão
- **Reautenticar sempre** antes de apagar qualquer documento: seletor do Google, `idToken` novo e `reauthenticateWithCredential`. Fechar o seletor cancela a exclusão sem apagar nada e não é falha. Uma credencial de outra conta (`user-mismatch`) também para antes de apagar. A reautenticação no mesmo processo também deixa a conta no cache do `google_sign_in_android`, e com isso o `disconnect()` revoga de fato.
- **Lista fixa das subcoleções** de `users/{uid}` num lugar só do código. Hoje ela tem só `movies`. Toda subcoleção nova (as listas da Fase 3 e os `items` de cada lista) entra nessa lista, nas regras e nos testes delas no mesmo ciclo. Um teste das regras confere que a lista bate com os `match` de `users/{uid}/…` no `firestore.rules`.
- **Documentos apagados em lotes de até 500**, lidos do servidor (`Source.server`) e repetidos até a leitura voltar vazia, cada `commit()` esperando a confirmação do servidor.
- **Prazo de 15 s por passo.** Passado o prazo ou sem rede, a exclusão falha com `NetworkFailure`. **Emenda (`/revisar` da sessão 024):** o prazo vale para a espera das escritas pendentes, a leitura do servidor, cada lote, o `disconnect()` e a limpeza, mas **não** para o `user.delete()`. Um `delete()` que estourasse o prazo e terminasse no servidor depois deixaria a sessão cair em `SignedOut` sem `disconnect()` nem limpeza; o prazo de rede do próprio SDK (`network-request-failed`) basta. O `user.delete()` só roda depois de todos os lotes confirmados. Repetir depois de uma falha no meio termina o que faltou: a leitura do servidor só traz o que sobrou.
- **Depois do `user.delete()`:** o `disconnect()` e a mesma limpeza local do logout. Uma falha nesses passos não reabre a conta, que já não existe. Ela é registrada, e a sessão termina em `SignedOut`.
- **Web: pedido por e-mail.** Uma página no Pages (decisão 006) explica o que é apagado e como pedir. O pedido sai do endereço da própria conta Google, e o dono do projeto apaga os documentos e a conta pelo console. O prazo de atendimento e o endereço de suporte são definidos na sessão 025, antes de publicar a página. O Firebase JS não entra.
- **`integration_test` fica no backlog.** A prova fica nos testes das regras (o dono apaga todos os documentos, e nada sobra em `users/{uid}`), nos fakes do gateway e na conferência no console durante a verificação no aparelho.

- **Emenda (`/revisar` da sessão 024): escritas travadas durante a exclusão.** Depois da reautenticação, um `UserDataWriteLock` compartilhado com a Estante recusa marcas e renovações de cópia, e a exclusão espera as escritas pendentes chegarem ao servidor antes da primeira leitura. Sem isso, uma marca confirmada entre a última leitura vazia e o `user.delete()` ficaria órfã em `users/{uid}`. A trava sai no fim, com sucesso ou falha.

Esta decisão complementa a 010 e não substitui nenhuma.

## Consequências
- O `deleteAccount` do contrato (sessão 018) ganha o passo da reautenticação com o seletor, e o cancelamento vira um resultado, não uma falha.
- `FirebaseAuthGateway` ganha `reauthenticateWithGoogleIdToken` e `delete`; `GoogleAccountGateway` ganha `disconnect`; um gateway novo apaga as subcoleções.
- A exclusão pela web só fica completa na sessão 025. **Portão do Play:** nenhum envio para a loja antes da página publicada.
- A política 2.0 declara a exclusão pelo app e o pedido por e-mail: o endereço, o prazo, o que é apagado, que o cache local sai junto e que o pedido por e-mail é tratado pelo dono do projeto. O e-mail recebido também é um dado pessoal tratado e entra na política com o prazo de guarda.
- A Browser key do Firebase continua sem uso. O item do backlog (restringir ou apagar) deixa de depender da página web.
- Estado parcial possível e aceito: se os documentos já foram apagados e o `user.delete()` falha, a conta fica viva e vazia até a próxima tentativa.
- **Lote na fila depois do prazo, aceito (`/revisar` da sessão 024):** o `timeout` não cancela o `commit()`. Com rede lenta, o lote continua na fila local depois da `NetworkFailure`, e o cache já mostra os filmes como apagados, enquanto no servidor eles ainda existem. Tentar de novo termina a exclusão. Se, em vez disso, a pessoa sair com "Sair mesmo assim", o `clearPersistence` descarta o lote, e os filmes reaparecem no próximo login.
- **Outros aparelhos, aceito até a varredura do Admin SDK:** o `user.delete()` não invalida os ID tokens já emitidos. Outro aparelho com a mesma conta aberta passa nas regras por até cerca de 1 h e pode recriar `users/{uid}/movies/{id}`, que fica órfão; o cache local dele também guarda as marcas até sair da conta ou abrir o app de novo sem conta.

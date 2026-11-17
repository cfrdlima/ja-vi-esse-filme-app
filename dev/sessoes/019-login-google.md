# Sessão 019 — Fase 2: login com o Google

**Data**: 2026-11-17 · **Branch**: `feature/019-login-google` · **Status**: fechada

## Objetivo
Entrar com o Google pelo `google_sign_in` nativo, só com a identidade básica e sem escopos extras, passando a credencial ao `FirebaseAuth`. A camada `data` traduz os erros do SDK em falhas tipadas, por trás de adaptadores finos testados com fakes. O `AuthNotifier` e o fake do `AuthRepository` também entram, montados no `main.dart`, e as pendências da 018 são resolvidas na mesma entrega. A limpeza do Firestore no logout e a exclusão da conta ficam para os itens próprios do plano.

## Checklist
### Preparação
- [x] Conferir no Context7 e no pub.dev o `firebase_auth` e o `google_sign_in` 7.x. **Feito:** `firebase_auth` ^7.1.0 e `google_sign_in` ^7.2.0, os dois com minSdk 24. `GoogleSignIn.instance.initialize()` uma única vez antes de tudo, e `authenticate()` sem `scopeHint`. O `serverClientId` vem do `default_web_client_id` gerado a partir do `google-services.json`, que já tem o client Web
- [x] `flutter pub add firebase_auth google_sign_in` (já estão na lista do `CLAUDE.md`)
- [x] Ajustar o contrato do `AuthRepository`: por enquanto o `signOut` não limpa o Firestore, e o `deleteAccount` falha com `UnexpectedFailure` até o item da exclusão

### Pendências da 018 (RED/GREEN/REFACTOR por comportamento)
- [x] `AppUser` recusa `uid` com `/`
- [x] `AppUser` recusa `uid` com espaço nas pontas
- [x] Redator: JWT (`eyJ…`)
- [x] Redator: access token do Google (`ya29.…`)
- [x] Redator: campos `idToken`, `accessToken` e `refreshToken`, e também `id_token` e `refresh_token` (JSON, escapado, chave=valor e `toString` de Map)
- [x] Redator: e-mail. O domínio precisa de ponto, para uma menção como `@ana` não ser mascarada (com teste de falso positivo)
- [x] `failureGeneric` neutro: "Algo deu errado. Tente de novo em instantes." (ARB e teste do `failureMessage`)
- [x] `data_extraction_rules.xml` (`cloud-backup` e `device-transfer`) e `backup_rules.xml` (`fullBackupContent`), excluindo **todos** os domínios (`root`, `file`, `database`, `sharedpref`, `external`). No manifest mesclado (`processDebugMainManifest`), os dois atributos chegam

### Camada `data` (adaptadores finos e repositório)
- [x] Interfaces mínimas (`FirebaseAuthGateway`, `GoogleAccountGateway`) em `data/gateways/auth_gateways.dart`, com fakes no teste do repositório
- [x] RED/GREEN: `authStateChanges` mapeia o usuário do Firebase para `SignedIn(AppUser)` e `null` para `SignedOut`
- [x] RED/GREEN: `signIn` com sucesso devolve `SignInCompleted` e passa o `idToken` ao Firebase
- [x] RED/GREEN: `signIn` com alguém já logado devolve o usuário sem abrir o seletor
- [x] RED/GREEN: `GoogleSignInExceptionCode.canceled` vira `SignInCancelled`, e um `idToken` nulo vira `UnexpectedFailure`
- [x] RED/GREEN, um teste por código: `user-disabled` vira `AccountDisabledFailure`, `network-request-failed` vira `NetworkFailure`, `too-many-requests` vira `RateLimitFailure`, e outro código do Firebase ou do Google, ou um erro desconhecido, vira `UnexpectedFailure`. Guardas: a `message` e o `email` da `FirebaseAuthException` e a `description` da `GoogleSignInException` não chegam à falha. Se o Firebase recusar a credencial, o app sai do Google, para o seletor voltar na próxima tentativa
- [x] RED/GREEN: `signOut` sai do Firebase e do Google, os dois mesmo se um falhar, e a falha sobe como `Failure`. O `deleteAccount` falha com `UnexpectedFailure` sem tocar em nada
- [x] Adaptadores reais (`FirebaseAuthSdkGateway`, `GoogleSignInSdkGateway`): só repasse, sem teste unitário (combinado na abertura), verificados no emulador

### Estado
- [x] Fake do `AuthRepository` em `test/helpers/fake_auth_repository.dart`: estado por `emit`, login pendente até `completeSignIn` ou `failSignIn`, e um `signOut` que emite `SignedOut` antes da falha, como pede o contrato
- [x] `SessionState` selado (`SessionLoading`, `SessionSignedOut`, `SessionSigningIn`, `SessionSignedIn(user)`, `SessionFailed(failure)`). É `Session*`, e não `Auth*`, para não colidir com o `SignedIn` e o `SignedOut` do domínio. O notifier é o `SessionNotifier`
- [x] RED/GREEN: o `SessionNotifier` espelha o `authStateChanges` (estado inicial carregando, depois deslogado ou logado)
- [x] RED/GREEN: o login em andamento expõe o estado de "entrando", e cancelar volta a deslogado sem erro. Um segundo `signIn` durante o primeiro é ignorado, e um `SignedOut` que chega no meio não esconde o "entrando"
- [x] RED/GREEN: uma falha no login vira `SessionFailed` (uma exceção não tipada vira `UnexpectedFailure`), tentar de novo limpa o erro, e um `SignedOut` que chega depois não esconde a falha. Esse último pegou um mutante que tinha sobrevivido
- [x] RED/GREEN: logout, incluindo a falha que vem depois do `SignedOut`
- [x] RED/GREEN: cancela a assinatura do stream no `dispose`

### Composição
- [x] `main.dart` monta o `FirebaseAuthRepository` depois do `Firebase.initializeApp`, e o `MainApp` expõe o `SessionNotifier` com `lazy: false`, acima do `MaterialApp`. Prova por mutação: com `lazy: true`, o teste falha
- [x] Verificação no emulador (Pixel_9_Pro), com um gatilho temporário fora do commit: `SessionSignedOut`, depois `SessionSigningIn` e depois `SessionSignedIn` com uma conta real. O log do `flutter run` não tem e-mail, JWT, `ya29.` nem `idToken`. No logcat, nenhuma linha do processo do app tem e-mail; as 33 com e-mail são todas do `Finsky` (Play Store)

### Entrega
- [x] Tríade: format sem mudança, analyze limpo e 842 testes verdes. **O gitleaks ficou pendente:** o binário não está instalado nesta máquina, mas o CI roda ele no PR
- [x] `/revisar` (`code-reviewer` e `security-auditor`, porque toca auth, storage e manifest). **Feito:** o `security-auditor` aprovou; o `code-reviewer` achou 1 bloqueante e 6 importantes, todos resolvidos (ver abaixo)
- [x] `/fechar-sessao`. **Feito:** format sem mudança (158 arquivos), analyze limpo, 861 testes verdes. O gitleaks não está instalado aqui e fica para o CI do PR

### Achados aceitos do `/revisar`
- [x] Bloqueante (1): sem o Firebase (falha no `initializeApp`), a composição não pode derrubar o app. **Feito:** o `UnavailableAuthRepository` emite `SignedOut`, o login e a exclusão falham com `UnexpectedFailure` e o logout conclui. O `composeAuthRepository` (`@visibleForTesting`, no `main.dart`) só chama o `connect` com o `Firebase.apps` não vazio, e um teste prova que, sem Firebase, ele nem toca no SDK
- [x] RED/GREEN (2): um erro no `authStateChanges` vira `Failure` no repositório (`handleError`) e falha no notifier (`onError`), sem ficar preso em `SessionLoading`
- [x] RED/GREEN (3): `currentUser` dentro do `try` no `signIn`. A exceção ali vira `Failure`. Um `Error` no notifier sai do "entrando" para a falha e continua subindo
- [x] RED/GREEN (4): o último `AuthState` recebido durante o login é reconciliado no fim (um `SignedIn` no meio, seguido de falha ou cancelamento, termina logado)
- [x] RED/GREEN (5): o `SessionFailed` ficou selado, com o `SessionSignInFailed` (também para o erro do stream, porque tentar de novo é entrar) e o `SessionSignOutFailed`. O doc diz que, se o `signOut` do Firebase falhar, a sessão pode continuar aberta
- [x] Guarda (6): o erro do Firebase vence o do Google quando o app sai do Google em silêncio. Prova por mutação: sem o `try`, o teste falha
- [x] Guarda (7): um login que termina depois do `dispose` não lança, e um `signIn` depois do `dispose` não chama a conta. Prova por mutação nas duas guardas `_disposed`

## Decisões
Nenhuma nova. As dependências `firebase_auth` e `google_sign_in` já estão na decisão 010 e no `CLAUDE.md`. Os adaptadores finos, sem pacote de mock, foram combinados na abertura.

## Commits
- `7c989e2` docs: abre a sessão 019
- `c60b8c6` add: AppUser recusa uid com barra ou espaço nas pontas (também traz o `pub add` e o ajuste do contrato)
- `a7df71c` add: redator mascara idToken, accessToken e refreshToken
- `c20ebd8` add: redator mascara JWT e access token do Google soltos no texto
- `d1a52dc` add: redator mascara e-mail
- `1f9c6e9` fix: mensagem genérica de falha sem citar o TMDB
- `d97a740` add: regras de backup e extração de dados excluem todos os domínios
- `95ad80c` add: FirebaseAuthRepository mapeia o usuário do Firebase para AuthState
- `d9ba034` add: signIn passa o idToken do Google ao Firebase
- `623cd78` add: signIn reaproveita quem já está logado e trata o cancelamento
- `fc7a880` add: signIn traduz os erros do Firebase e do Google em falhas tipadas
- `b932293` add: signOut sai do Firebase e do Google mesmo com falha em um deles
- `42e77e0` add: adaptadores finos sobre o FirebaseAuth e o GoogleSignIn
- `baba14b` add: SessionNotifier espelha o estado da conta
- `d24d905` add: SessionNotifier conduz o login com entrando, cancelado e falha
- `827ce54` add: SessionNotifier faz o logout e mantém a falha visível
- `1703565` add: main.dart monta a conta e expõe o SessionNotifier ao app
- `1dfcded` docs: progresso da sessão 019
- `50f67ea` docs: achados do /revisar na sessão 019
- `2ba9997` fix: app sobe com a conta indisponível quando o Firebase falha
- `180b41c` fix: erro no stream da conta vira Failure e SessionFailed
- `ea92494` fix: login não fica preso em entrando com erro no usuário atual ou bug
- `c188886` fix: login reconcilia o estado da conta que chegou no meio
- `6e876bf` fix: falha da sessão diz se foi no login ou no logout
- `54c5d60` test: erro do Firebase vence o do Google ao sair em silêncio
- `08fbb23` test: SessionNotifier ignora login depois do dispose
- `44468a4` docs: achados do /revisar resolvidos na sessão 019
- `docs: fecha sessão 019` (este fechamento)

## Notas
- **Depois das correções do `/revisar`, o app não foi aberto de novo no emulador.** O login real foi verificado antes delas. As correções mudam a composição e o estado, e não a UI, e estão cobertas por teste. Na sessão do Perfil, a verificação no emulador acontece de qualquer forma, com o botão de verdade.
- **Achados do `/revisar` adiados** (com o ok do usuário), levados para o `BACKLOG.md`:
  - (8) teste da primeira falha no `signOut`, com as duas falhando;
  - (9) sair do Google quando o `idToken` vem nulo;
  - (10) tentar de novo o `initialize()` do Google depois de uma falha;
  - (11) guardas do `signOut` no notifier (login em andamento, chamada dupla, `Exception`);
  - (12) regex de e-mail (`pacote@7.1.0`, `logo@2x.png`, `%40`);
  - (13) nomes com prefixo camelCase (`googleAccessToken`);
  - (14) fake reemitindo o estado ao assinar;
  - (15) `deleteAccount` do fake como `Future`;
  - (16) `uid` com IDs reservados do Firestore (`.`, `..`, `__x__`);
  - (17) e-mail de teste em `@example.com`.
- **Fora do escopo, segundo o `security-auditor`:** `USE_BIOMETRIC` e `USE_FINGERPRINT` vêm do `androidx.credentials` (avaliar `tools:node="remove"`); a política 2.0 precisa estar publicada antes do botão de login; o App Check fica na Fase 4.
- **O `toString` do `GoogleSignInAuthentication` imprime o `idToken`.** O adaptador lê só o `.idToken` e nunca registra esse objeto. Qualquer log futuro perto do login precisa passar pelo `redactSecrets`, que agora mascara JWT.
- **O `requires-recent-login` ainda não é traduzido:** nenhum teste do login pede isso. Ele entra com o `deleteAccount` (item da exclusão).
- **Cache do Firestore no logout:** o `cloud_firestore` ainda não entrou. O `terminate()`, o `clearPersistence()` e a recriação da instância ficam para o item do logout, junto do teste de que a falha ao limpar não deixa a sessão aberta.
- **O Pixel_9 não tem espaço:** 96% do `/data` usado, 264 MB livres e o install falha. Os apps de outros projetos que estão nele não foram removidos. Para os próximos testes, use o Pixel_9_Pro.
- **Commit com mais de uma unidade:** o `c60b8c6` juntou o `pub add` e o ajuste do contrato à validação do `uid`. Fica registrado; não reescrevi o histórico.
- **Prova por mutação:** sobre a guarda do `SessionFailed` (no começo o mutante sobreviveu, e o teste novo passou a pegá-lo) e sobre o `lazy: false`.

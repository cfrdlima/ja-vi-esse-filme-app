# Sessão 019 — Fase 2: login com o Google

**Data**: 2026-11-17 · **Branch**: `feature/019-login-google` · **Status**: aberta

## Objetivo
Entrar com o Google pelo `google_sign_in` nativo, só com a identidade básica e sem escopos extras, passando a credencial ao `FirebaseAuth`. A camada `data` traduz os erros do SDK em falhas tipadas, por trás de adaptadores finos testados com fakes. O `AuthNotifier` e o fake do `AuthRepository` também entram, montados no `main.dart`, e as pendências da 018 são resolvidas na mesma entrega. A limpeza do Firestore no logout e a exclusão da conta ficam para os itens próprios do plano.

## Checklist
### Preparação
- [ ] Conferir no Context7 e no pub.dev o `firebase_auth` e o `google_sign_in` 7.x: versões compatíveis com o `firebase_core ^5.2.0` e o minSdk 24, API do `GoogleSignIn.instance` (`initialize`, `authenticate`, `authenticationEvents`), `serverClientId` e códigos de erro
- [ ] `flutter pub add firebase_auth google_sign_in` (já estão na lista do `CLAUDE.md`)
- [ ] Ajustar o contrato do `AuthRepository`: por enquanto o `signOut` não limpa o Firestore, e o `deleteAccount` falha com `UnexpectedFailure` até o item da exclusão

### Pendências da 018 (RED/GREEN/REFACTOR por comportamento)
- [ ] `AppUser` recusa `uid` com `/`
- [ ] `AppUser` recusa `uid` com espaço nas pontas
- [ ] Redator: JWT (`eyJ…`)
- [ ] Redator: access token do Google (`ya29.…`)
- [ ] Redator: campos `idToken`, `accessToken` e `refreshToken` (JSON, escapado e chave=valor)
- [ ] Redator: e-mail
- [ ] `failureGeneric` neutro, sem citar o TMDB (ARB e teste do `failureMessage`)
- [ ] `data_extraction_rules.xml` (`cloud-backup` e `device-transfer`) e `fullBackupContent`, excluindo pelo menos `sharedpref` e `database`. Conferir o manifest mesclado

### Camada `data` (adaptadores finos e repositório)
- [ ] Interfaces mínimas sobre o `FirebaseAuth` e o `GoogleSignIn`, com fakes nos testes
- [ ] RED/GREEN: `authStateChanges` mapeia o usuário do Firebase para `SignedIn(AppUser)` e `null` para `SignedOut`, como stream broadcast
- [ ] RED/GREEN: `signIn` com sucesso devolve `SignInCompleted` e passa o `idToken` ao Firebase
- [ ] RED/GREEN: `signIn` com alguém já logado devolve o usuário sem abrir o seletor
- [ ] RED/GREEN: `GoogleSignInExceptionCode.canceled` vira `SignInCancelled`
- [ ] RED/GREEN, um teste por código: `user-disabled` vira `AccountDisabledFailure`, `network-request-failed` vira `NetworkFailure`, `too-many-requests` vira `RateLimitFailure` e o resto vira `UnexpectedFailure`, sem `e.message`, `e.email` nem `e.credential`
- [ ] RED/GREEN: `signOut` chama o `signOut` do Firebase e do Google, os dois mesmo se um falhar, e a falha sobe como `Failure`
- [ ] REFACTOR

### Estado
- [ ] Fake do `AuthRepository` em `test/helpers/`, no formato que os testes do estado pedirem
- [ ] RED/GREEN: o `AuthNotifier` espelha o `authStateChanges` (estado inicial carregando, depois deslogado ou logado)
- [ ] RED/GREEN: o login em andamento expõe o estado de "entrando"; cancelar volta ao estado anterior sem erro
- [ ] RED/GREEN: uma falha no login fica visível como falha tipada, e tentar de novo limpa o erro
- [ ] RED/GREEN: logout, incluindo a falha que vem depois do `SignedOut`
- [ ] RED/GREEN: cancela a assinatura do stream no `dispose`
- [ ] REFACTOR

### Composição
- [ ] `main.dart` monta o repositório real e o `AuthNotifier` e os injeta, com os testes de widget usando o fake
- [ ] Verificação no emulador: login real com uma conta de teste e o estado logado no log de debug, sem dados pessoais (a UI do Perfil é da próxima sessão)

### Entrega
- [ ] Tríade: format, analyze limpo, testes verdes e gitleaks
- [ ] `/revisar` (`code-reviewer` e `security-auditor`, porque toca auth, storage e manifest)
- [ ] `/fechar-sessao`

## Decisões

## Commits

## Notas

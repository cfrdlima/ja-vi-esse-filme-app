# Sessão 018 — Fase 2: domínio da conta

**Data**: 2026-11-17 · **Branch**: `feature/018-dominio-conta` · **Status**: aberta

## Objetivo
Criar o domínio da conta em `lib/features/auth/domain/`, em Dart puro: a entidade do usuário (`uid`, nome, e-mail, foto), o contrato do repositório (usuário atual em stream, entrar, sair e excluir) e as falhas tipadas (sem rede, conta desativada, login recente exigido). O cancelamento do login é um resultado, e não um erro. Tudo com fakes, sem Firebase nem `google_sign_in`.

## Checklist
### Preparação
- [x] Conferir no Context7 os erros do `firebase_auth` e do `google_sign_in` 7.x. **Feito:** `user-disabled`, `requires-recent-login`, `network-request-failed` e `too-many-requests` no Auth; `GoogleSignInExceptionCode.canceled` no `google_sign_in`
- [x] Decidir onde ficam as falhas da conta. **Feito** com o ok do usuário: em `core/error/failures.dart`, junto da `Failure` selada, para o `failureMessage` continuar exaustivo. O stream emite um estado selado, e não `AppUser?`

### Entidade `AppUser` (RED/GREEN/REFACTOR por comportamento)
- [x] RED/GREEN: cria com `uid`, nome, e-mail e foto; nome, e-mail e foto podem faltar
- [x] RED/GREEN: `uid` vazio (ou só espaços) é recusado com `ArgumentError`, sem o valor na mensagem
- [x] RED/GREEN: igualdade e `hashCode` por valor
- [x] Guarda: `toString` não expõe nome, e-mail, foto nem `uid`. Passou de primeira (o `toString` padrão já é seguro), com prova por mutação
- [x] REFACTOR: `toString` explícito (`AppUser(dados ocultos)`)

### Estados e falhas
- [x] RED/GREEN: `AuthState` selado (`SignedOut`, `SignedIn(user)`) e `SignInOutcome` selado (`SignInCompleted(user)`, `SignInCancelled`), com igualdade e `toString` sem dados pessoais
- [x] RED/GREEN: `AccountDisabledFailure` e `RecentLoginRequiredFailure` em `Failure`, com as mensagens no ARB e no `failureMessage`. Sem rede reaproveita a `NetworkFailure`, e `too-many-requests` reaproveita a `RateLimitFailure`
- [x] REFACTOR: tirado o `==` do `SignedOut` e do `SignInCancelled`, que nenhum teste pedia (o `prefer_const` garante instâncias canônicas)

### Contrato
- [x] `AuthRepository` (`abstract interface`): `authStateChanges`, `signIn()`, `signOut()` e `deleteAccount()`, com as falhas de cada um documentadas
- [x] Guarda de arquitetura (`test/features/domain_purity_test.dart`): nenhum `domain/` importa `flutter`, `http`, storage, `firebase_*`, `cloud_firestore` ou `google_sign_in`. Prova por mutação com um `import` do `firebase_auth`
- [ ] ~~Fake do `AuthRepository`~~ **Adiado** para a sessão do login, junto do estado que o usa (ver Notas)

### Entrega
- [x] Tríade: format sem mudança, analyze limpo, 760 testes, gitleaks 8.30.1 sem vazamento
- [ ] `/revisar` (`code-reviewer`; `security-auditor`, porque é auth)
- [ ] `/fechar-sessao`

## Decisões
Nenhuma nova. As escolhas (falhas em `Failure` e estado selado no stream) seguem o `CLAUDE.md` e a decisão 010.

## Commits
- `cf79a64` docs: abre a sessão 018
- `a0c4b2b` add: entidade AppUser da conta
- `bb61b05` add: AppUser recusa uid vazio
- `7fbc931` add: AppUser com igualdade por valor
- `c48b512` add: AppUser esconde os dados pessoais no toString
- `192e7c1` add: estados selados da conta e do resultado do login
- `f857799` add: falhas tipadas de conta desativada e login recente exigido
- `575e6d1` add: contrato do AuthRepository e teste de pureza do domain

## Notas
- **Fake adiado:** não há precedente de fake com teste próprio em `test/helpers/`, e o formato dele (stream controlado, pedidos pendentes como no `FakeMovieRepository`) depende do que os testes do estado vão pedir. Criá-lo agora seria antecipação.
- **Pendente para a sessão do login:**
  - o `failureGeneric` diz "Algo deu errado ao falar com o TMDB". Uma `UnexpectedFailure` vinda do Auth mostraria esse texto. Antes do login chegar à UI, a mensagem precisa ser neutra ou ganhar uma variante da conta;
  - a camada `data` traduz `user-disabled` para `AccountDisabledFailure`, `requires-recent-login` para `RecentLoginRequiredFailure`, `network-request-failed` para `NetworkFailure`, `too-many-requests` para `RateLimitFailure` (sem `retryAfter`), `GoogleSignInExceptionCode.canceled` para `SignInCancelled` e o resto para `UnexpectedFailure`, sem a `message` do SDK;
  - segundo a documentação do `google_sign_in_android`, um erro de configuração (SHA-1 ou `serverClientId`) também pode chegar como `canceled`. Se o login "cancelar" sozinho depois de escolher a conta, confira a configuração antes de suspeitar do código.
- O `AppUser` não é `const`, porque valida o `uid` no construtor.
- O teste de pureza vale para todas as features, e não só para `auth`. Ele passou de primeira em `movies`.

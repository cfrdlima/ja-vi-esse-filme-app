# Sessão 018 — Fase 2: domínio da conta

**Data**: 2026-11-17 · **Branch**: `feature/018-dominio-conta` · **Status**: aberta

## Objetivo
Criar o domínio da conta em `lib/features/auth/domain/`, em Dart puro: a entidade do usuário (`uid`, nome, e-mail, foto), o contrato do repositório (usuário atual em stream, entrar, sair e excluir) e as falhas tipadas (sem rede, conta desativada, login recente exigido). O cancelamento do login é um resultado, e não um erro. Tudo com fakes, sem Firebase nem `google_sign_in`.

## Checklist
### Preparação
- [ ] Conferir no Context7 os erros do `firebase_auth` e do `google_sign_in` 7.x (cancelamento, `user-disabled`, `network-request-failed`, `requires-recent-login`) para as falhas do domínio cobrirem o que a camada `data` vai traduzir, sem inventar caso
- [ ] Decidir onde ficam as falhas da conta: `sealed` só aceita subtipo na mesma biblioteca, então ou entram em `core/error/failures.dart` (e o `failureMessage` ganha os casos) ou viram um `sealed AuthFailure` próprio da feature

### Entidade `AppUser` (RED/GREEN/REFACTOR por comportamento)
- [ ] RED/GREEN: cria com `uid`, nome, e-mail e foto; nome, e-mail e foto podem faltar
- [ ] RED/GREEN: `uid` vazio é recusado
- [ ] RED/GREEN: igualdade e `hashCode` por valor
- [ ] RED/GREEN: `toString` não expõe nome, e-mail, foto nem `uid` (logs, CLAUDE.md)
- [ ] REFACTOR

### Resultado do login e falhas
- [ ] RED/GREEN: resultado do login `sealed` com `SignedIn(user)` e `SignInCancelled`
- [ ] RED/GREEN: falhas tipadas da conta (sem rede, conta desativada, login recente exigido, inesperada) sem texto técnico no `toString`
- [ ] RED/GREEN: `failureMessage` mapeia as falhas novas (se ficarem em `Failure`), com chaves no ARB
- [ ] REFACTOR

### Contrato e fake
- [ ] `AuthRepository` (`abstract interface`): `Stream<AppUser?> authStateChanges`, `signIn()`, `signOut()`, `deleteAccount()`, com a doc das falhas de cada um
- [ ] Fake em `test/` que exercita o contrato (stream emite o usuário ao entrar e `null` ao sair), útil para o estado da próxima sessão
- [ ] Teste de arquitetura: nada em `features/auth/domain/` importa `flutter`, `firebase_*` ou `google_sign_in`

### Entrega
- [ ] Tríade: `dart format`, `flutter analyze`, `flutter test`, `gitleaks`
- [ ] `/revisar` (`code-reviewer`; `security-auditor`, porque é auth)
- [ ] `/fechar-sessao`

## Decisões

## Commits

## Notas

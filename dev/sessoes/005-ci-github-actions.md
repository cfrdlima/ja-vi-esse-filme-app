# Sessão 005 — Fase 0: CI no GitHub Actions

**Data**: 2026-10-19 · **Branch**: `feature/005-ci-github-actions` · **Status**: aberta

## Objetivo
Criar um workflow do GitHub Actions que rode, em todo push e pull request para `main`, a mesma tríade local: `dart format` sem mudanças, `flutter analyze` sem issues, `flutter test` verde e `gitleaks` sem vazamentos, com o Flutter fixado em 3.44.5. Isso fecha a Fase 0.

## Checklist
O workflow não é código Dart, então o ciclo TDD vira "provar que o job falha pelo motivo certo, depois que passa".

- [x] Conferir as versões atuais das actions (`actions/checkout`, `subosito/flutter-action`) e do `gitleaks`, e fixar cada uma por SHA de commit
- [x] Workflow `.github/workflows/ci.yml`: gatilhos (`push` em `main`, `pull_request`), `permissions: contents: read`, `concurrency` cancelando execuções antigas, `timeout-minutes`
- [x] Passo de setup: Flutter 3.44.5 fixado, com cache do SDK e do pub; `flutter pub get`
- [x] Format — RED: com um arquivo mal formatado, `dart format --output=none --set-exit-if-changed lib test` sai com erro (local)
- [x] Format — GREEN: passo no workflow; sem o arquivo mal formatado, sai 0
- [x] Analyze — RED/GREEN: com um lint quebrado, `flutter analyze` falha; sem ele, passa (`--fatal-infos` para casar com "sem issues")
- [x] Test — RED/GREEN: com um teste quebrado, `flutter test` falha; sem ele, passa (`AppConfig.fromEnvironment` precisa rodar sem `--dart-define`, como já roda)
- [x] Gitleaks — RED/GREEN: com um segredo falso, `gitleaks` falha; sem ele, passa. Histórico completo (`fetch-depth: 0`) e binário com checksum conferido
- [x] Validar a sintaxe do workflow (`actionlint`, se disponível)
- [x] Empurrar a branch e ver o workflow verde no GitHub (PR draft #1); provar o vermelho com um commit temporário na branch (teste quebrado), revertido em seguida
- [x] Badge do CI e nota sobre o workflow no README
- [ ] `/revisar` com `code-reviewer` e `security-auditor` (o diff toca a cadeia de build e a varredura de segredos)

## Decisões
- `subosito/flutter-action` (terceiro, fixado por SHA) para instalar o Flutter, em vez de clonar o SDK no job. Aprovado pelo usuário.
- `gitleaks` via binário da release com o SHA-256 fixado no workflow, em vez da `gitleaks-action` (que exige licença e é mais um terceiro). O checksum não é lido da mesma release, que poderia ter sido adulterada.
- O vermelho do `gitleaks` foi provado só localmente, para não deixar segredo falso no histórico da branch (decisão do usuário).
- O CI roda via PR (draft #1), porque os gatilhos são `push` em `main` e `pull_request`. Não há gatilho em `feature/**` (decisão do usuário).

## Commits
- `93707ce` docs: abre sessão 005
- `4cfb00c` chore: CI com format, analyze, test e gitleaks
- `4ac5e00` test: vermelho temporário para provar o CI
- `b606370` test: reverte o vermelho temporário do CI
- `567e303` docs: badge e nota do CI no README

## Notas
- Versões fixadas: `actions/checkout` v7.0.1 (`3d3c42e`), `subosito/flutter-action` v2.23.0 (`1a44944`), `gitleaks` 8.30.1 (SHA-256 `551f6fc8…70eb`). Os dois jobs (`flutter` e `gitleaks`) rodam em paralelo no `ubuntu-24.04`.
- Endurecimento: `permissions: contents: read`, `persist-credentials: false`, `concurrency` cancelando execuções antigas da mesma ref, `timeout-minutes` por job. O CI não usa nenhum secret: `flutter test` roda sem `--dart-define`, e o teste do `AppConfig` depende disso.
- RED/GREEN local, cada um com um arquivo temporário apagado em seguida:
  - format: um arquivo mal formatado sai 1; sem ele, sai 0;
  - analyze (`--fatal-infos`): um `print` gera `avoid_print` e sai 1; sem ele, "No issues found!";
  - test: `expect(1, 2)` sai 1; sem ele, 232 testes passam;
  - gitleaks: um token `ghp_` falso commitado num clone no scratchpad dá "leaks found: 1" e sai 1; no repositório, "no leaks found".
- `actionlint` 1.7.7 (via `podman`, imagem `rhysd/actionlint`): sem apontamentos.
- No GitHub (PR #1):
  - 1ª execução: verde, Flutter 3.44.5, 232 testes, checksum do gitleaks OK, "no leaks found". Levou 2m25s sem cache.
  - Commit vermelho: o job `flutter` falhou em `test/zz_red_test.dart: vermelho de propósito` (`Expected: <2>`, `Actual: <1>`); o `gitleaks` seguiu verde.
  - Revert: verde de novo, em 1m30s com cache.
- O repositório também tem o check "GitGuardian Security Checks" (app externo, fora deste workflow).
- Sugestão para o usuário: ativar branch protection na `main` exigindo os checks "Format, analyze e test" e "Gitleaks".

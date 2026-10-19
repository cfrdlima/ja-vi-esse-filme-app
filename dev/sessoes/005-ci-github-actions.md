# Sessão 005 — Fase 0: CI no GitHub Actions

**Data**: 2026-10-19 · **Branch**: `feature/005-ci-github-actions` · **Status**: aberta

## Objetivo
Criar um workflow do GitHub Actions que rode, em todo push e pull request para `main`, a mesma tríade local: `dart format` sem mudanças, `flutter analyze` sem issues, `flutter test` verde e `gitleaks` sem vazamentos, com o Flutter fixado em 3.44.5. Isso fecha a Fase 0.

## Checklist
O workflow não é código Dart, então o ciclo TDD vira "provar que o job falha pelo motivo certo, depois que passa".

- [ ] Conferir as versões atuais das actions (`actions/checkout`, `subosito/flutter-action`) e do `gitleaks`, e fixar cada uma por SHA de commit
- [ ] Workflow `.github/workflows/ci.yml`: gatilhos (`push` em `main`, `pull_request`), `permissions: contents: read`, `concurrency` cancelando execuções antigas, `timeout-minutes`
- [ ] Passo de setup: Flutter 3.44.5 fixado, com cache do SDK e do pub; `flutter pub get`
- [ ] Format — RED: com um arquivo mal formatado, `dart format --output=none --set-exit-if-changed lib test` sai com erro (local)
- [ ] Format — GREEN: passo no workflow; sem o arquivo mal formatado, sai 0
- [ ] Analyze — RED/GREEN: com um lint quebrado, `flutter analyze` falha; sem ele, passa (`--fatal-infos` para casar com "sem issues")
- [ ] Test — RED/GREEN: com um teste quebrado, `flutter test` falha; sem ele, passa (`AppConfig.fromEnvironment` precisa rodar sem `--dart-define`, como já roda)
- [ ] Gitleaks — RED/GREEN: com um segredo falso, `gitleaks` falha; sem ele, passa. Histórico completo (`fetch-depth: 0`) e binário com checksum conferido
- [ ] Validar a sintaxe do workflow (`actionlint`, se disponível)
- [ ] Empurrar a branch e ver o workflow verde no GitHub; provar o vermelho com um commit temporário na branch, revertido em seguida
- [ ] Badge do CI e nota sobre o workflow no README
- [ ] `/revisar` com `code-reviewer` e `security-auditor` (o diff toca a cadeia de build e a varredura de segredos)

## Decisões

## Commits

## Notas

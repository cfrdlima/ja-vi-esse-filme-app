# Sessão 002 — Fase 0: fundação e endurecimento

**Data**: 2026-10-16 · **Branch**: `feature/002-fundacao-endurecimento` · **Status**: aberta

## Objetivo
Endurecer a base antes do `core/network`: manifest seguro e com o nome do app, lints estritos, `.gitignore` limpo e handlers globais de erro. Também documentar o projeto (README, `pubspec`, `setup-claude.sh`) e registrar a justificativa do minSdk.

## Checklist
- [x] Lints: `analysis_options.yaml` estrito (`strict-casts`, `strict-inference`, `strict-raw-types`, `avoid_dynamic_calls`, `unawaited_futures`, `avoid_print`…)
- [x] Lints: corrigir o que o `flutter analyze` apontar, sem `// ignore:`
- [x] Manifest — RED: `test/android/manifest_test.dart` cobre `INTERNET` no `main`, `allowBackup="false"`, `usesCleartextTraffic="false"` e `android:label="Já Vi Esse Filme"`
- [x] Manifest — GREEN: ajustar o `AndroidManifest.xml`
- [x] Manifest — REFACTOR
- [x] Handlers de erro — RED: `registerErrorHandlers()` configura `FlutterError.onError` e `PlatformDispatcher.instance.onError`, e este último retorna `true`
- [x] Handlers de erro — GREEN: `lib/core/error/error_handlers.dart`, chamado no `main.dart` (log via `dart:developer`, sem dado sensível)
- [x] Handlers de erro — REFACTOR
- [x] `.gitignore`: remover o bloco duplicado e acrescentar `.env*` (conferir com `git check-ignore`)
- [x] README do projeto e `description` real no `pubspec.yaml`
- [x] `setup-claude.sh`: citar a skill `ui-ux-pro-max`
- [x] Decisão 003: justificativa do minSdk 24
- [x] Falha 5xx: confirmar que já está no item `core/network` do PLANO (nada a codar agora)
- [x] Tríade: `flutter analyze` limpo, `flutter test` verde, app abre no emulador
- [x] `security-auditor` no diff (a sessão mexe no manifest)

## Decisões
- [003 — minSdk 24 herdado do Flutter](../decisoes/003-min-sdk.md)

## Commits

## Notas
- Lints: `require_trailing_commas` ficou de fora porque briga com o formatador do Dart 3.7+, que já decide as vírgulas sozinho. Ligar o modo estrito só gerou 1 issue (`prefer_const_declarations` em `app_colors_test.dart`).
- Teste do manifest: lê o XML como texto em `test/android/`, para não precisar de dependência de parser XML. Fica fora do espelho `lib/`↔`test/` por escolha do usuário.
- Handlers de erro: `registerErrorHandlers({ErrorReporter report})`. O reporter injetável é o ponto em que o crash reporting entra na Fase 4. Os testes restauram `FlutterError.onError`, `presentError` e `PlatformDispatcher.onError` no `tearDown`.
- Falha 5xx: já está no item `core/network` do PLANO. Não houve código nesta sessão.
- Emulador (Medium Phone API 36): o APK debug instalou e abriu sem erro no logcat.
  - O `aapt2` mostra `application-label:'Já Vi Esse Filme'`.
  - O `dumpsys` mostra `minSdk=24 targetSdk=36`, `INTERNET` concedida e flags sem `ALLOW_BACKUP`.
- `security-auditor`: sem bloqueantes, aprovado para fechar.
- **Pendências da auditoria** (levar ao PLANO no `/fechar-sessao`):
  - **Obrigatório na sessão do `TmdbClient`:** autenticar com o token v4 no header `Authorization: Bearer`, e não com `api_key` na query. Criar também um redator, com TDD, que troca `(api_key|session_id|request_token)=...` por `***` antes do `_logError` e de qualquer crash reporter. O `session_id` vai na query dos endpoints de conta.
  - **Antes do primeiro APK de release:** o comando de build do `CLAUDE.md` não tem `--obfuscate --split-debug-info=build/symbols`, que a decisão 001 exige. O release ainda assina com a chave de debug.
  - **Na sessão que adicionar o `flutter_secure_storage`:** criar `data_extraction_rules.xml`, excluindo os dados em `cloud-backup` e `device-transfer`, mais o `fullBackupContent`. Também tratar a falha de leitura da sessão como "deslogado".
  - Sugestão: se um dia existir `.env.example`, adicionar `!.env.example` ao `.gitignore`.

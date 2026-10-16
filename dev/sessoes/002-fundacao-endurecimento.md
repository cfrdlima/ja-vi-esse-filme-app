# Sessão 002 — Fase 0: fundação e endurecimento

**Data**: 2026-10-16 · **Branch**: `feature/002-fundacao-endurecimento` · **Status**: aberta

## Objetivo
Endurecer a base antes do `core/network`: manifest seguro e com o nome do app, lints estritos, `.gitignore` limpo e handlers globais de erro. Também documentar o projeto (README, `pubspec`, `setup-claude.sh`) e registrar a justificativa do minSdk.

## Checklist
- [ ] Lints: `analysis_options.yaml` estrito (`strict-casts`, `strict-inference`, `strict-raw-types`, `avoid_dynamic_calls`, `unawaited_futures`, `avoid_print`…)
- [ ] Lints: corrigir o que o `flutter analyze` apontar, sem `// ignore:`
- [ ] Manifest — RED: `test/android/manifest_test.dart` cobre `INTERNET` no `main`, `allowBackup="false"`, `usesCleartextTraffic="false"` e `android:label="Já Vi Esse Filme"`
- [ ] Manifest — GREEN: ajustar o `AndroidManifest.xml`
- [ ] Manifest — REFACTOR
- [ ] Handlers de erro — RED: `registerErrorHandlers()` configura `FlutterError.onError` e `PlatformDispatcher.instance.onError`, e este último retorna `true`
- [ ] Handlers de erro — GREEN: `lib/core/error/error_handlers.dart`, chamado no `main.dart` (log via `dart:developer`, sem dado sensível)
- [ ] Handlers de erro — REFACTOR
- [ ] `.gitignore`: remover o bloco duplicado e acrescentar `.env*` (conferir com `git check-ignore`)
- [ ] README do projeto e `description` real no `pubspec.yaml`
- [ ] `setup-claude.sh`: citar a skill `ui-ux-pro-max`
- [ ] Decisão 003: justificativa do minSdk 24
- [ ] Falha 5xx: confirmar que já está no item `core/network` do PLANO (nada a codar agora)
- [ ] Tríade: `flutter analyze` limpo, `flutter test` verde, app abre no emulador
- [ ] `security-auditor` no diff (a sessão mexe no manifest)

## Decisões

## Commits

## Notas

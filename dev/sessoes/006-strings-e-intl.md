# Sessão 006 — Antes da Fase 1: strings de UI e `intl`

**Data**: 2026-10-19 · **Branch**: `feature/006-strings-e-intl` · **Status**: aberta

## Objetivo
Decidir onde ficam as strings de UI e como datas e números são formatados em pt-BR, registrando as duas decisões em `dev/decisoes/`. Em seguida, aplicar a escolha ao app atual, que hoje não define locale nenhum, e às strings já existentes: abas, títulos dos placeholders e página não encontrada. Assim a Fase 1 começa no padrão.

## Checklist
- [x] Conferir na documentação atual (Context7) o `gen-l10n` no Flutter 3.44: `l10n.yaml`, pasta de saída sem o pacote sintético, `format`, e se o `flutter pub get` gera o código (importa para o CI)
- [x] `/decisao`: strings de UI (ARB + `gen-l10n` ou constantes Dart)
- [x] `/decisao`: `intl` e `flutter_localizations` como dependências diretas
- [ ] Locale — RED: o app abre com locale `pt_BR`, e os textos do próprio Material saem em português (ex.: o tooltip de voltar é "Voltar")
- [ ] Locale — GREEN: `locale`, `supportedLocales` e `localizationsDelegates` no `MaterialApp.router`
- [ ] Helper de teste: montar widgets com os delegates e o locale do app em um ponto só (`test/helpers/`)
- [ ] Strings — RED: um teste que falha se uma string de UI conhecida não vier do catálogo (ex.: rótulo de aba lido pelo `AppLocalizations`)
- [ ] Strings — GREEN: ARB com abas, títulos, "Em breve", "Página não encontrada" e "Ir para Descobrir"
- [ ] Strings — REFACTOR: migrar `app_shell`, `app_router`, `placeholder_screen` e `not_found_screen`, com os testes atuais seguindo verdes
- [ ] CI: confirmar que o código gerado não quebra o `dart format --set-exit-if-changed` nem o `flutter analyze`, e que o CI gera o mesmo resultado
- [ ] Tríade: `flutter analyze` limpo, `flutter test` verde e emulador em pt-BR (tooltips e abas, com fonte grande)
- [ ] `/revisar` com `code-reviewer`; `security-auditor` não se aplica (não toca auth, storage, rede nem `env/`)

## Decisões
- [004 — Strings de UI em ARB com `gen-l10n`](../decisoes/004-strings-de-ui-em-arb.md)
- [005 — `intl` e `flutter_localizations` como dependências diretas](../decisoes/005-intl-e-flutter-localizations.md)

## Commits

## Notas

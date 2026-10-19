# Sessão 006 — Antes da Fase 1: strings de UI e `intl`

**Data**: 2026-10-19 · **Branch**: `feature/006-strings-e-intl` · **Status**: aberta

## Objetivo
Decidir onde ficam as strings de UI e como datas e números são formatados em pt-BR, registrando as duas decisões em `dev/decisoes/`. Em seguida, aplicar a escolha ao app atual, que hoje não define locale nenhum, e às strings já existentes: abas, títulos dos placeholders e página não encontrada. Assim a Fase 1 começa no padrão.

## Checklist
- [x] Conferir na documentação atual (Context7) o `gen-l10n` no Flutter 3.44: `l10n.yaml`, pasta de saída sem o pacote sintético, `format`, e se o `flutter pub get` gera o código (importa para o CI)
- [x] `/decisao`: strings de UI (ARB + `gen-l10n` ou constantes Dart)
- [x] `/decisao`: `intl` e `flutter_localizations` como dependências diretas
- [x] Locale — RED: o app abre com locale `pt_BR`, e os textos do próprio Material saem em português (ex.: o tooltip de voltar é "Voltar")
- [x] Locale — GREEN: `locale`, `supportedLocales` e `localizationsDelegates` no `MaterialApp.router`
- [x] Helper de teste: montar widgets com os delegates e o locale do app em um ponto só (`test/helpers/`)
- [x] Strings — RED: o catálogo pt-BR tem cada texto atual (`lookupAppLocalizations`), e falha porque o `AppLocalizations` ainda não existe
- [x] Strings — GREEN: ARB com abas, títulos, "Em breve", "Página não encontrada" e "Ir para Descobrir"
- [x] Strings — REFACTOR: migrar `app_shell`, `app_router`, `placeholder_screen` e `not_found_screen`, com os testes atuais seguindo verdes
- [x] CI: o código gerado passa no `dart format --set-exit-if-changed` e no `flutter analyze --fatal-infos`; passo novo `git diff --exit-code lib/l10n` depois do `pub get` (a execução no GitHub fica para o PR, no fechamento)
- [x] Tríade: `flutter analyze` limpo, `flutter test` verde e emulador em pt-BR (tooltips e abas, com fonte grande)
- [x] `/revisar` com `code-reviewer`; `security-auditor` não se aplica (não toca auth, storage, rede nem `env/`)
- [ ] Revisão 1: título de cada aba na app bar, parametrizado (pega a troca de "Minha estante")
- [ ] Revisão 2: trocar o teste tautológico do catálogo por um teste de contrato do `AppLocale`
- [ ] Revisão 3: comentar por que `supportedLocales` é `[pt_BR]` (código e decisão 004)
- [ ] Revisão 4: passo de CI pega também gerado não rastreado (`git status --porcelain`)
- [ ] Revisão 5 e 8: `Builder` inline no lugar do `_Placeholder` com tear-offs; import solto
- [ ] Revisão 9: justificativa da decisão 005 pelo `intl` fixado no `flutter_localizations`

## Decisões
- [004 — Strings de UI em ARB com `gen-l10n`](../decisoes/004-strings-de-ui-em-arb.md)
- [005 — `intl` e `flutter_localizations` como dependências diretas](../decisoes/005-intl-e-flutter-localizations.md)

## Commits
- `c2f469c` docs: abre sessão 006 e registra as decisões 004 e 005
- `e86a487` add: app em pt-BR com as traduções do Material
- `f133a8a` add: catálogo pt-BR das strings de UI com gen-l10n
- `0070c18` refactor: idioma do app em AppLocale e helper de teste com tema e idioma
- `9189ae9` refactor: telas e abas leem os textos do catálogo pt-BR
- `20649a4` chore: CI confere que o código gerado do l10n está em dia

## Notas
- `gen-l10n` no Flutter 3.44.5: o Context7 trouxe o guia de migração do pacote sintético. No `flutter gen-l10n --help` local, não existem mais `--synthetic-package` nem `--format`. Num clone no scratchpad, o `flutter pub get` gerou `lib/l10n/app_localizations*.dart` já formatados e com o `analyze` estrito limpo.
- Locale:
  - RED: `Localizations.localeOf` não era `pt_BR` e o `backButtonTooltip` veio `'Back'`.
  - GREEN: `locale`, `supportedLocales` e `localizationsDelegates`, centralizados depois em `AppLocale` (`lib/core/l10n/app_locale.dart`).
  - O `supportedLocales` é `[pt_BR]` e não `AppLocalizations.supportedLocales` (`[pt]`). Com `[pt]`, o locale resolvido seria `pt` e o teste de `pt_BR` falharia. O delegate do catálogo aceita `pt_BR`, porque só compara o idioma.
- Strings:
  - O RED do catálogo é a falta de `package:ja_vi_esse_filme/l10n/app_localizations.dart`.
  - A migração dos widgets foi REFACTOR: os testes que já conferiam "Em breve", "Ir para Descobrir", rótulos e títulos seguiram verdes.
  - Não há teste que pegue um texto literal novo num widget. Fica como regra de revisão (decisão 004).
- O router é montado sem `BuildContext`, então cada aba recebe um `_Placeholder` com um tear-off const (`_shelfTitle` e os outros) que lê o título no `build`. Sai junto com os placeholders na Fase 1.
- Testes: `test/helpers/test_app.dart` (`testApp` e `testRouterApp`) monta o tema e o idioma do app em um ponto só. Os quatro testes de widget passaram a usar o helper. São 242 testes (eram 232): 2 de locale e 8 do catálogo.
- Código gerado em dia: num ARB mudado e staged, sem o gerado acompanhar, o `pub get` regenera e o `git diff --exit-code lib/l10n` sai 1. O `actionlint` não apontou nada.
- Emulador (Medium Phone API 36, sistema em `en-US`):
  - Abas, títulos e "Em breve" em pt-BR.
  - A árvore de acessibilidade mostra "Guia 1 de 4" etc., ou seja, o Material saiu em português num aparelho em inglês.
  - Na aba Estante com fonte 1.3x, nada vaza e o título é "Minha estante".
- Tríade: `dart format` sem mudanças, `flutter analyze --fatal-infos` sem issues, `flutter test` com 242 testes passando e `gitleaks` sem vazamentos.

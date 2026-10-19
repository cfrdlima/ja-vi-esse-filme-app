# 004 — Strings de UI em ARB com `gen-l10n`

**Data**: 2026-10-19 · **Status**: aceita

## Contexto
A Fase 1 vai trazer dezenas de textos de UI: títulos, estados vazio e de erro, ações, plurais ("1 filme" / "3 filmes") e textos com parâmetro ("Nota 7,8"). Hoje os poucos textos que existem (abas, placeholders, página não encontrada) estão literais nos widgets. O app também não define locale, então os textos do próprio Material, como tooltips e diálogos, saem em inglês.

O app é só pt-BR por enquanto. O `CLAUDE.md` pede textos de UI em PT-BR e código em inglês.

## Opções consideradas
1. **Constantes Dart** (ex.: `abstract final class AppStrings`): zero dependência e zero geração de código. Não resolve plural nem formatação, e passar a usar ARB depois exigiria trocar todos os pontos de uso.
2. **ARB + `gen-l10n`** (`flutter_localizations`): é o padrão do Flutter. Os getters são checados em compilação, o catálogo resolve plural e parâmetros formatados (ICU), e outro idioma entra sem refatorar. O custo é a geração de código e os testes de widget precisarem dos delegates.

## Decisão
Opção 2.
- **Catálogo:** `lib/l10n/app_pt.arb` é o template. As chaves ficam em inglês e em camelCase (ex.: `tabDiscover`), e cada uma tem `@chave.description`.
- **Geração:** o `l10n.yaml` aponta `arb-dir: lib/l10n` e usa `nullable-getter: false`, para que `AppLocalizations.of(context)` não devolva nulo. O código é gerado em `lib/l10n/`. O pacote sintético `package:flutter_gen` não existe mais no Flutter 3.44.
- **Locale:** fixo em `pt_BR` no `MaterialApp`, independente do idioma do aparelho. O Material e o Cupertino também saem em português.
  - O ARB é `"@@locale": "pt"`, mas o `supportedLocales` do app é `[pt_BR]`, e não o `AppLocalizations.supportedLocales` (`[pt]`). Com `[pt]`, a resolução devolveria `pt`, e o `Localizations.localeOf` e o `intl` perderiam a região. O delegate do catálogo compara só o idioma, por isso aceita `pt_BR`.
- **Código gerado versionado.** O `flutter pub get` regenera os arquivos, e o CI confere com `git diff --exit-code` que o versionado bate com o gerado.

## Consequências
- Nenhum widget tem texto literal de UI: tudo vem de `AppLocalizations.of(context)`.
- `domain` continua sem texto de UI. Uma falha de domínio vira mensagem só na `presentation`.
- Testes de widget montam a árvore pelo helper de `test/helpers/`, que aplica os delegates e o locale do app.
- Depende das dependências diretas da decisão 005.
- Para adicionar um idioma, basta criar `app_<locale>.arb` e rever o locale fixo.

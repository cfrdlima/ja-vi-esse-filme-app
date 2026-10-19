# 005 — `intl` e `flutter_localizations` como dependências diretas

**Data**: 2026-10-19 · **Status**: aceita

## Contexto
O `CLAUDE.md` exige aprovação para qualquer dependência fora da stack. A decisão 004 adota ARB com `gen-l10n`, e o código gerado importa `package:intl`. A Fase 1 também vai formatar datas de lançamento ("19 de out. de 2026"), notas ("7,8") e durações em pt-BR.

Os dois pacotes já estavam no `pubspec.lock` como dependências transitivas, trazidas pelo `material_ui`/`cupertino_ui` do `go_router`: `flutter_localizations` (SDK) e `intl` 0.20.2.

## Opções consideradas
1. **Declarar as duas como dependências diretas**: é o que o `gen-l10n` pede. O `DateFormat` e o `NumberFormat` formatam em pt-BR sem código próprio. Nada novo é baixado.
2. **Formatação própria, sem `intl`**: não é viável com a 004, porque o código gerado depende do `intl`. Também seria reimplementar nomes de mês e separador decimal.

## Decisão
Opção 1. O `flutter_localizations` vem do SDK. O `intl` entra com `^0.20.2`, a versão que o SDK já resolve. Usar uma versão diferente da exigida pelo `flutter_localizations` quebraria o `pub get`.

## Consequências
- Formatadores de data, nota e duração só são criados na Fase 1, quando a primeira tela precisar. Eles ficam na `presentation`, porque o `domain` continua em Dart puro, sem `intl`.
- A cada upgrade do Flutter, o `intl` acompanha a versão que o SDK exige.

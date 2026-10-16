# Sessão 001 — Fase 0: design system com ui-ux-pro-max e tokens em core/theme

**Data**: 2026-10-16 · **Branch**: `feature/001-design-system-tokens` · **Status**: aberta

## Objetivo
Gerar o design system do app com a skill `ui-ux-pro-max` (stack Flutter) em `design-system/ja-vi-esse-filme/MASTER.md`, aprovado pelo usuário. Depois, traduzi-lo em tokens testados em `lib/core/theme/` (Material 3, tema escuro, fontes empacotadas) e aplicar o tema no `MaterialApp`.

## Checklist
- [x] B1. Gerar e persistir o design system (`--design-system --persist`, stack Flutter) → `design-system/ja-vi-esse-filme/MASTER.md`
- [x] B1. Apresentar paleta, tipografia, estilo e anti-padrões → **aguardar ok**
- [x] B2. Baixar as fontes (`.ttf`, OFL) para `assets/fonts/` e declará-las no `pubspec.yaml` (sem `google_fonts`)
- [x] Cores — RED: teste do `ColorScheme` escuro com as cores do `MASTER.md`
- [x] Cores — GREEN: `app_colors.dart` + `ColorScheme`
- [x] Cores — REFACTOR
- [x] Contraste — RED: os pares texto/fundo principais atingem AA (luminância relativa)
- [x] Contraste — GREEN / REFACTOR
- [x] Tipografia — RED: o `TextTheme` usa as famílias empacotadas
- [x] Tipografia — GREEN: `app_typography.dart` / REFACTOR
- [x] Tokens extras — RED: a `ThemeExtension` expõe espaçamentos, raios e a cor de "já visto"
- [x] Tokens extras — GREEN: `app_spacing.dart` + `ThemeExtension` / REFACTOR
- [x] Tema — RED: `AppTheme.dark()` é Material 3, escuro e registra a extensão
- [x] Tema — GREEN: `app_theme.dart` / REFACTOR: aplicar no `MaterialApp` do `main.dart`
- [x] Validar no emulador (Medium Phone API 36: fundo `#0F0F23` e texto em Inter; o Pixel 9 Pro não subiu porque havia locks de uma instância anterior em `~/.android/avd/Pixel_9_Pro.avd/`)
- [x] Corrigir no `CLAUDE.md` a versão do SDK (o `pubspec.yaml` usa `^3.12.2`; o `CLAUDE.md` diz `^3.7`)
- [x] Incluir no `MASTER.md` o Hero do pôster (grade → detalhes) e o feedback de toque (auditoria ⚠️15)
- [x] Prever `ListView.builder`/`GridView.builder` na skill `tela-4-estados` (auditoria ⚠️16)
- [x] `/revisar` (code-reviewer: 0 bloqueantes, 7 importantes, 6 sugestões; tratar 1–7)
- [ ] Revisão 1 — RED/GREEN: `ColorScheme` com `surfaceContainerLowest/Low/Highest`, `surfaceDim/Bright`, `outlineVariant` e `scrim` do MASTER
- [ ] Revisão 2 — RED/GREEN: ícone da aba ativa em `onPrimary` sobre o indicador dourado
- [ ] Revisão 3 — RED/GREEN: `fontFamily` Inter no `ThemeData`, `displayLarge/Medium` em Playfair, `letterSpacing` do MASTER
- [ ] Revisão 4 — RED/GREEN: borda de foco com 2dp, `errorBorder` e `focusedErrorBorder`
- [ ] Revisão 5 — RED/GREEN: `bottomSheetTheme` e scrim de 50% em diálogo e sheet
- [ ] Revisão 6 — RED/GREEN: token `focusRing` na `ThemeExtension`
- [ ] Revisão 7 — RED/GREEN: borda do `OutlinedButton` desabilitado
- [ ] Validar de novo no emulador
- [ ] `/fechar-sessao`

## Decisões
- Paleta da skill ajustada (aprovada): `primary` = dourado `#CA8A04`; índigos só como superfície/secundária; `outline` `#6366F1`; `watched` `#34D399`; `error` `#F87171` (o `#EF4444` dava 4,48 sobre o card).
- Tipografia: Playfair Display (títulos) + Inter (texto), aprovada pelo usuário.
- [002 — Adotar a skill ui-ux-pro-max como fonte da verdade de design](../decisoes/002-ui-ux-pro-max-fonte-de-design.md)

## Commits

## Notas
- Fontes: TTF variáveis oficiais do `google/fonts` (Playfair Display `[wght]`, Inter `[opsz,wght]`), com o `OFL.txt` de cada uma em `assets/fonts/`. No Flutter 3.44, o `FontWeight` controla o eixo `wght` sozinho. Falta registrar as licenças no `LicenseRegistry` (tela "Sobre", Fase 1).
- Contraste: o RED do ciclo veio dos tokens de "já visto", que ainda não existiam. Os outros pares já tinham sido calculados ao aprovar a paleta, então passaram de primeira; um teste extra garante que o cálculo reprova um par ruim (índigo sobre o fundo).
- Tipografia, REFACTOR: troquei a subclasse de `TextStyle` por funções. A subclasse muda o `runtimeType`, e isso quebra o `==` do `TextStyle`.
- Auditoria de prontidão (`dev/checklist-prontidao.md`): PRONTO COM RESSALVAS, sem bloqueantes. O usuário resolve emulador e licenças Android no terminal.
- **No `/fechar-sessao` desta sessão:**
  - No `PLANO.md`, marcar a criação do projeto como feita e incluir os itens que a auditoria achou fora do plano:
    - Fase 0: manifest (`INTERNET`, `allowBackup`, cleartext explícito), handlers de erro globais, falha 5xx, README, CI com versão do Flutter fixada.
    - Antes da Fase 1: decisão sobre strings de UI (ARB ou constantes) e `intl`; política de privacidade.
    - Fase 1: Hero do pôster.
    - Fase 2: validar a origem do retorno do deep link de login.
    - Fase 4: crash reporting.
  - Criar a próxima sessão como **002 — fundação e endurecimento**, com:
    - manifest (`INTERNET`, `allowBackup`, cleartext);
    - `.gitignore` (remover o bloco duplicado e acrescentar `.env*`);
    - README e descrição do `pubspec`;
    - `analysis_options` estrito;
    - handlers globais de erro;
    - falha 5xx;
    - atualizar o `setup-claude.sh`;
    - registrar o minSdk.

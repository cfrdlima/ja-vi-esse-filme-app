# Sessão 001 — Fase 0: design system com ui-ux-pro-max e tokens em core/theme

**Data**: 2026-10-16 · **Branch**: `feature/001-design-system-tokens` · **Status**: aberta

## Objetivo
Gerar o design system do app com a skill `ui-ux-pro-max` (stack Flutter) em `design-system/ja-vi-esse-filme/MASTER.md`, aprovado pelo usuário. Depois, traduzi-lo em tokens testados em `lib/core/theme/` (Material 3, tema escuro, fontes empacotadas) e aplicar o tema no `MaterialApp`.

## Checklist
- [x] B1. Gerar e persistir o design system (`--design-system --persist`, stack Flutter) → `design-system/ja-vi-esse-filme/MASTER.md`
- [x] B1. Apresentar paleta, tipografia, estilo e anti-padrões → **aguardar ok**
- [ ] B2. Baixar as fontes (`.ttf`, OFL) para `assets/fonts/` e declará-las no `pubspec.yaml` (sem `google_fonts`)
- [ ] Cores — RED: teste do `ColorScheme` escuro com as cores do `MASTER.md`
- [ ] Cores — GREEN: `app_colors.dart` + `ColorScheme`
- [ ] Cores — REFACTOR
- [ ] Contraste — RED: os pares texto/fundo principais atingem AA (luminância relativa)
- [ ] Contraste — GREEN / REFACTOR
- [ ] Tipografia — RED: o `TextTheme` usa as famílias empacotadas
- [ ] Tipografia — GREEN: `app_typography.dart` / REFACTOR
- [ ] Tokens extras — RED: a `ThemeExtension` expõe espaçamentos, raios e a cor de "já visto"
- [ ] Tokens extras — GREEN: `app_spacing.dart` + `ThemeExtension` / REFACTOR
- [ ] Tema — RED: `AppTheme.dark()` é Material 3, escuro e registra a extensão
- [ ] Tema — GREEN: `app_theme.dart` / REFACTOR: aplicar no `MaterialApp` do `main.dart`
- [ ] Validar no emulador
- [ ] Corrigir no `CLAUDE.md` a versão do SDK (o `pubspec.yaml` usa `^3.12.2`; o `CLAUDE.md` diz `^3.7`)
- [x] Incluir no `MASTER.md` o Hero do pôster (grade → detalhes) e o feedback de toque (auditoria ⚠️15)
- [ ] Prever `ListView.builder`/`GridView.builder` na skill `tela-4-estados` (auditoria ⚠️16)
- [ ] `/revisar` e `/fechar-sessao`

## Decisões
- Paleta da skill ajustada (aprovada): `primary` = dourado `#CA8A04`; índigos só como superfície/secundária; `outline` `#6366F1`; `watched` `#34D399`; `error` `#F87171` (o `#EF4444` dava 4,48 sobre o card).
- Tipografia: Playfair Display (títulos) + Inter (texto), aprovada pelo usuário.
- [002 — Adotar a skill ui-ux-pro-max como fonte da verdade de design](../decisoes/002-ui-ux-pro-max-fonte-de-design.md)

## Commits

## Notas
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

# Design System — Já Vi Esse Filme (MASTER)

> **Lógica:** ao construir uma tela, veja primeiro `design-system/ja-vi-esse-filme/pages/<tela>.md`. Se existir, ele **sobrepõe** este arquivo. Senão, siga as regras abaixo.
>
> Este é a **fonte da verdade** de design (decisão 002). Os tokens em `lib/core/theme/` são traduções diretas deste arquivo; mude aqui primeiro.

---

**Projeto:** Já Vi Esse Filme · **Stack:** Flutter (Material 3) · **Tema padrão:** escuro
**Origem:** `ui-ux-pro-max` — categoria *Theater/Cinema*, estilo *Dark Mode (OLED)*, gerado em 2026-10-16 e ajustado na sessão 001 (contraste, papéis M3, tradução para Flutter).

---

## 1. Estilo

**Dark Mode (OLED) — "sala de cinema".** Fundo quase preto azulado, o pôster é o protagonista e o dourado de holofote marca as ações. Interface discreta e de alto contraste, sem poluição visual.

- Hierarquia por **tons de superfície** (fundo → card → muted), não por sombras.
- Brilho e glow mínimos; só em pontos isolados (ver `docs/DESIGN.md`).
- Ícones de um único conjunto: **Material Symbols (rounded)**. Nunca emoji como ícone.

## 2. Paleta (tema escuro)

Contraste WCAG calculado sobre as superfícies; o teste de tokens verifica os pares marcados.

| Token | Papel no Material 3 | Hex | Contraste |
|---|---|---|---|
| `surfaceLowest` | `surfaceContainerLowest` | `#0A0A1A` | — |
| `background` | `surface`, `surfaceDim` | `#0F0F23` | — |
| `surfaceLow` | `surfaceContainerLow` | `#151529` | — |
| `card` | `surfaceContainer` | `#1B1B30` | — |
| `muted` | `surfaceContainerHigh` | `#27273B` | — |
| `surfaceHighest` | `surfaceContainerHighest`, `surfaceBright` | `#2C2C42` | todos os textos ≥ 4,6; `outline` 3,0 |
| `foreground` | `onSurface` | `#F8FAFC` | 18,0 fundo · 16,1 card · 13,9 muted |
| `mutedForeground` | `onSurfaceVariant` | `#94A3B8` | 7,4 fundo · 6,6 card · 5,7 muted |
| `gold` | `primary` | `#CA8A04` | 6,4 fundo · 5,7 card · 5,0 muted |
| `onGold` | `onPrimary` | `#0F172A` | 6,1 sobre `gold` |
| `indigo` | `secondaryContainer` | `#1E1B4B` | — |
| `onIndigo` | `onSecondaryContainer` | `#F8FAFC` | 15,3 sobre `indigo` |
| `indigoBright` | `secondary` | `#312E81` | `foreground` sobre ela: 10,9 |
| `outline` | `outline` | `#6366F1` | 4,2 fundo · 3,8 card · 3,3 muted (mín. 3:1 para borda/ícone) |
| `outlineVariant` | `outlineVariant` | `#3F3F5A` | decorativo (divisores); não usar como única borda de controle |
| `watched` | `ThemeExtension` (já visto) | `#34D399` | 9,8 fundo · 8,8 card; `onWatched` `#0F172A` 9,3 |
| `error` | `error` | `#F87171` | 6,8 fundo · 6,1 card · 5,3 muted |
| `onError` | `onError` | `#000000` | 7,6 sobre `error` |
| `focusRing` | `ThemeExtension` (anel de foco) | `#FFFFFF` | 19,5 fundo |
| `scrim` | `scrim`, barreira de diálogo/sheet | `#000000` a 50% | — |

Os demais papéis do M3 seguem o padrão do `ColorScheme`: `primaryContainer` = `primary`, `tertiary` = `secondary`, `inversePrimary` = `onPrimary`.

Regras:
- `primary` (dourado) é a cor de ação: botão principal, aba ativa, indicador de seleção.
- Os índigos são de superfície e destaque secundário, **nunca** cor de botão sobre o fundo (contraste 1,18).
- "Já visto" usa `watched` + ícone + texto; nunca só a cor.

## 3. Tipografia

**Playfair Display** (títulos) + **Inter** (texto e interface). Ambas OFL, **empacotadas** em `assets/fonts/` (sem `google_fonts`).

| Estilo M3 | Família | Peso | Tamanho / altura |
|---|---|---|---|
| `displayLarge` | Playfair Display | 700 | 57 / 64 |
| `displayMedium` | Playfair Display | 700 | 45 / 52 |
| `displaySmall` | Playfair Display | 700 | 36 / 44 |
| `headlineLarge` | Playfair Display | 700 | 32 / 40 |
| `headlineMedium` | Playfair Display | 700 | 28 / 36 |
| `headlineSmall` | Playfair Display | 600 | 24 / 32 |
| `titleLarge` | Playfair Display | 600 | 22 / 28 |
| `titleMedium` | Inter | 600 | 16 / 24 |
| `titleSmall` | Inter | 600 | 14 / 20 |
| `bodyLarge` | Inter | 400 | 16 / 24 |
| `bodyMedium` | Inter | 400 | 14 / 20 |
| `bodySmall` | Inter | 400 | 12 / 16 |
| `labelLarge` | Inter | 500 | 14 / 20 |
| `labelMedium` | Inter | 500 | 12 / 16 |
| `labelSmall` | Inter | 500 | 11 / 16 |

Regras:
- Playfair só em títulos (nome do filme, títulos de seção). Metadados, botões e corpo em Inter.
- Família padrão do app: Inter. Qualquer estilo fora da tabela (inclusive o `primaryTextTheme`) sai em Inter, nunca em Roboto.
- `letterSpacing` 0 em todos os estilos, exceto `label*` com 0,1. Não herdar os espaçamentos do M3 (0,25–0,5), que deixam a Inter aberta demais.
- Corpo base 16; nada de texto corrido abaixo de 12.
- Tamanhos respeitam o `textScaler` do sistema; testar com 1.5 sem overflow.

## 4. Espaçamento, raios e elevação

**Espaçamento** (`AppSpacing`, em dp):

| Token | Valor | Uso |
|---|---|---|
| `xs` | 4 | ajustes finos |
| `sm` | 8 | entre ícone e texto, entre pôsteres da grade |
| `md` | 16 | padding padrão de tela e card |
| `lg` | 24 | entre seções |
| `xl` | 32 | blocos grandes |
| `xxl` | 48 | topo de telas vazias/erro |
| `xxxl` | 64 | backdrop/hero de detalhes |

**Raios** (`AppRadii`): `sm` 8 (botões, chips, campos) · `md` 12 (pôsteres, cards) · `lg` 16 (bottom sheets, diálogos).

**Elevação:** por tom de superfície (`surface` → `surfaceContainer` → `surfaceContainerHigh`). Sombra só em diálogos e bottom sheets.

## 5. Componentes

- **Botão principal:** `FilledButton` com `primary`/`onPrimary`, raio `sm`, altura mínima 48dp, `labelLarge`.
- **Botão secundário:** `OutlinedButton` com borda `outline`, texto `onSurface`. Desabilitado: borda `onSurface` a 12%.
- **Card / pôster:** fundo `surfaceContainer`, raio `md`, proporção 2:3, sem sombra. Placeholder desenhado quando não há `poster_path`.
- **Campo de texto (busca):** preenchido com `surfaceContainerHigh`, raio `sm`, rótulo visível (não só placeholder). Sem borda em repouso; foco com borda `outline` de 2dp; erro com borda `error` de 1dp, e de 2dp quando também estiver em foco.
- **Diálogo / bottom sheet:** fundo `surfaceContainerHigh`, raio `lg` (no sheet, só nos cantos de cima), scrim preto a 50%.
- **Aba ativa (`NavigationBar`):** indicador `primary` com ícone `onPrimary` (6,1:1).
- **Anel de foco:** `focusRing` com 2dp em volta do elemento focado (teclado/D-pad).
- **Selo "já visto":** ícone `check_circle` + texto, cor `watched`.

## 6. Padrão de navegação e telas

- **Abas inferiores (`NavigationBar`)**, 4 destinos: Descobrir · Buscar · Estante · Perfil. Aba ativa com indicador `primary` e ícone `onPrimary`.
- **Rótulo da aba em uma linha só**, curto o bastante para caber com fonte 1.3x (o limite que o `NavigationBar` aplica) numa tela de 320dp. Por isso a aba é "Estante", e o título da tela continua "Minha estante".
- **Descobrir / Minha estante:** grade de pôsteres 2:3 com `GridView.builder`, espaçamento `sm`, padding `md`.
- **Detalhes:** backdrop no topo com **gradiente/scrim** até `surface` (contraste AA do título sobre a imagem); ações fixas (já vi / favorito / lista); trailers abrem fora do app.
- **Toda tela tem 4 estados:** carregando (skeleton), vazio, erro (com "Tentar de novo") e sucesso.

## 7. Movimento e interação

- **Hero do pôster:** grade/lista → detalhes com `Hero(tag: 'poster-<id>')`; o mesmo pôster continua na tela de detalhes.
- **Feedback de toque:** todo elemento clicável usa `InkWell`/ripple do Material (sem hover), alvo mínimo **48×48dp** e 8dp entre alvos.
- **Durações:** curta 150 ms (estado de botão, seleção) · média 250 ms (entrada de conteúdo) · Hero/rotas 300 ms. Saída mais rápida que entrada. Curva `Curves.easeOutCubic`.
- Mudança de estado nunca é instantânea, mas animação é sutil (fade + deslocamento ≤ 12dp).
- **Movimento reduzido:** se `MediaQuery.disableAnimationsOf(context)` for `true`, pular animações não essenciais.

## 8. Anti-padrões (não usar)

- ❌ Detalhes do filme sem trailers quando o TMDB tem vídeos
- ❌ Emoji como ícone; ícones de conjuntos misturados
- ❌ Texto com contraste abaixo de 4,5:1; borda/ícone abaixo de 3:1
- ❌ Cor como único indicador (ex.: "já visto" só verde)
- ❌ Índigo como cor de botão sobre o fundo
- ❌ Mudança de estado instantânea; animação que desloca layout
- ❌ Blur, glassmorphism ou sombra grande em itens de lista/grade
- ❌ Spinner solto no lugar de skeleton
- ❌ Cor, fonte ou tamanho fora dos tokens de `lib/core/theme/`

## 9. Checklist antes de entregar uma tela

- [ ] Só tokens do tema (nenhum `Color(0x…)` ou tamanho mágico no widget)
- [ ] Contraste AA nos textos; 3:1 em bordas e ícones
- [ ] `Semantics` em pôster e ícone clicável; alvos ≥ 48dp
- [ ] `textScaler` 1.5 sem overflow
- [ ] Ripple em todo clicável; Hero do pôster quando houver navegação para detalhes
- [ ] Movimento reduzido respeitado
- [ ] Os 4 estados implementados e testados
- [ ] Conteúdo respeita safe area e não fica atrás da `NavigationBar`
- [ ] Validado no emulador

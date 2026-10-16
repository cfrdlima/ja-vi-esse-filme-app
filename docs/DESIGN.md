# Design — Já Vi Esse Filme

A fonte da verdade de design é **`design-system/ja-vi-esse-filme/MASTER.md`**, gerado pela skill `ui-ux-pro-max` com stack **Flutter**.

- Overrides por tela: `design-system/ja-vi-esse-filme/pages/<tela>.md`. Se existir, ele vale para aquela tela; senão, vale o `MASTER.md`.
- Tokens em código: `lib/core/theme/` (`ThemeData` Material 3 + `ThemeExtension`). Widgets nunca usam cor, fonte ou espaçamento fora desses tokens.
- Para alterar o design: atualize o `MASTER.md` (ou o override da tela) **primeiro** e só depois o código.

## Regras de adaptação para Flutter
- **Fontes empacotadas** em `assets/fonts/` e declaradas no `pubspec.yaml`. Não use o pacote `google_fonts` (ele baixa a fonte em tempo de execução).
- **Efeitos pesados** (glassmorphism, blur, sombras grandes) só em pontos isolados, como o topo da tela de detalhes. Nunca em itens de lista ou grade.
- **Contraste mínimo AA** em texto sobre pôster/backdrop: use gradiente ou scrim.
- **Tema escuro** é o padrão; claro é opcional.

# 002 — Adotar a skill ui-ux-pro-max como fonte da verdade de design

**Data**: 2026-10-16 · **Status**: aceita

## Contexto
Precisávamos de uma direção de design consistente e de regras de UX, sem duplicar fontes. O `docs/DESIGN.md` era um template vazio e a skill `frontend-design` é voltada para web.

## Opções consideradas
- **`frontend-design` sozinha**: boa para explorar conceitos visuais, mas focada em web (CSS, Google Fonts) e sem base de regras de UX.
- **Escrever o design system à mão**: controle total, mas lento e sem base de referência.
- **`ui-ux-pro-max`** (`nextlevelbuilder/ui-ux-pro-max-skill`, MIT): orientação específica para Flutter, base local de estilos, paletas, tipografia e diretrizes de UX, e gera um `MASTER.md` persistente com overrides por tela.

## Decisão
Adotar a `ui-ux-pro-max`, versionada em `.claude/skills/ui-ux-pro-max/`. O `design-system/ja-vi-esse-filme/MASTER.md` gerado por ela é a fonte da verdade de design, e o `docs/DESIGN.md` fica só com as regras de adaptação para Flutter. A `frontend-design` passa a ser opcional, só para explorar conceitos.

## Consequências
- Skill de terceiros versionada no repo. Cada atualização exige revisar os scripts antes, procurando chamadas de rede e escritas fora do projeto. A revisão da versão 2.15.0 (commit `56ea9cf`) não encontrou nenhuma das duas: os scripts usam só a biblioteca padrão do Python e só escrevem em `design-system/` com `--persist`.
- A cópia local troca `${CLAUDE_PLUGIN_ROOT}` por caminhos relativos à raiz do projeto no `SKILL.md`. Reaplique essa troca ao atualizar.
- Sugestões de web (imports do Google Fonts, CSS, Tailwind) precisam ser traduzidas para Flutter.
- Fontes empacotadas em `assets/fonts/`, sem o pacote `google_fonts`.
- Mudança de design começa pelo `MASTER.md` e só depois chega a `lib/core/theme/`.

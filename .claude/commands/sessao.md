---
description: Abre uma nova sessão de desenvolvimento (branch + log)
argument-hint: [descrição curta da sessão, opcional]
---
Abra uma nova sessão de trabalho.

1. Leia `dev/PLANO.md` (fase atual e "Última sessão") e o log mais recente em `dev/sessoes/`.
2. Verifique `git status`. Se houver alterações não commitadas ou uma sessão anterior sem fechar, **pare e me avise**. Não continue.
3. Defina o objetivo: use "$ARGUMENTS" se foi informado; senão, proponha o próximo item não marcado do `PLANO.md` e peça minha confirmação.
4. Descubra o próximo número `NNN` (3 dígitos) a partir dos arquivos de `dev/sessoes/`.
5. Crie a branch `feature/NNN-<slug>` a partir de `main` atualizada.
6. Crie `dev/sessoes/NNN-<slug>.md` com:
   - `# Sessão NNN — <título>`
   - **Data**: hoje · **Branch**: `feature/NNN-<slug>` · **Status**: aberta
   - `## Objetivo` (1–3 frases)
   - `## Checklist` com os passos quebrados em ciclos TDD (RED/GREEN/REFACTOR por comportamento)
   - `## Decisões`, `## Commits`, `## Notas` (vazios)
7. Leia as decisões de `dev/decisoes/` relevantes para o objetivo.
8. Mostre um resumo: objetivo, checklist, arquivos que provavelmente serão tocados e riscos. **Espere meu ok antes de escrever código.**

---
description: Fecha a sessão atual — só com analyze limpo e testes verdes
---
Feche a sessão aberta.

1. Encontre o log com **Status: aberta** em `dev/sessoes/`. Se não houver, avise e pare.
2. Rode, nesta ordem, e **cole as saídas resumidas**:
   - `dart format --output=none --set-exit-if-changed lib/ test/`
   - `flutter analyze`
   - `flutter test`
   - `gitleaks detect --no-banner` (se instalado)
3. **Se qualquer um falhar, NÃO feche.** Mostre o erro, proponha a correção e pare.
4. Se a sessão tocou auth, storage, rede ou `env/`, confirme que `/revisar` foi rodado; se não, rode o subagente `security-auditor` agora.
5. Atualize o log da sessão: marque o checklist, preencha **Commits** (`git log main..HEAD --oneline`), **Decisões** (links para `dev/decisoes/`), **Notas** (o que ficou pendente) e mude para **Status: fechada**.
6. Em `dev/PLANO.md`: marque `[x]` os itens concluídos e reescreva a seção "Última sessão" (número, título, resumo de 2 linhas, próximo passo sugerido).
7. Ideias que surgiram e não entram no plano vão para `dev/BACKLOG.md`.
8. Commit `docs: fecha sessão NNN`.
9. **Pergunte antes** de integrar: merge `--no-ff` da branch em `main` e apagar a branch local. Não faça push sem eu pedir.

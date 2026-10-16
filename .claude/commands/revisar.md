---
description: Revisão independente do diff da sessão (qualidade + segurança)
---
Faça uma revisão independente do trabalho desta sessão.

1. Obtenha o diff: `git diff main...HEAD` mais alterações não commitadas.
2. Rode o subagente `code-reviewer` com esse diff.
3. Se o diff tocar `auth`, storage, `core/network`, `core/config`, `env/`, `AndroidManifest.xml` ou abertura de URLs, rode também o subagente `security-auditor`.
4. Consolide os achados por severidade (**bloqueante / importante / sugestão**), com arquivo:linha.
5. **Não corrija nada automaticamente.** Pergunte quais achados devo tratar; os aceitos viram itens via `/tarefa`.

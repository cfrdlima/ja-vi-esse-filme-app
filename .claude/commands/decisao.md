---
description: Registra uma decisão técnica ou de produto em dev/decisoes/
argument-hint: <descrição da decisão>
---
Registre a decisão: "$ARGUMENTS".

1. Descubra o próximo número `NNN` em `dev/decisoes/`.
2. Se o contexto da decisão não estiver claro na conversa, **faça até 2 perguntas** antes de escrever. Não invente motivação.
3. Crie `dev/decisoes/NNN-<slug>.md`:
   ```
   # NNN — <título>
   **Data**: hoje · **Status**: aceita | proposta | substituída por NNN
   ## Contexto
   ## Opções consideradas
   ## Decisão
   ## Consequências
   ```
4. Se substituir uma decisão anterior, atualize o status da antiga.
5. Se houver sessão aberta, adicione o link em **Decisões** no log dela.

# Atendimento do pedido de exclusão por e-mail

Procedimento interno (decisão 015, sessão 025) para atender o pedido descrito em `docs/EXCLUSAO-DA-CONTA.md`. Fica fora da cópia pública.

**Prazo:** responder em até 15 dias depois do recebimento (LGPD, art. 19, II).

1. **Conferir o remetente.** O pedido precisa vir do endereço da conta Google. Se vier de outro endereço, responder pedindo que escreva do endereço da conta, sem dizer se ela existe, e parar aqui.
2. **Achar a conta.** No console do Firebase, em Authentication › Usuários, buscar pelo e-mail do remetente e copiar o `uid`. Sem conta com esse e-mail, responder que não há conta ligada ao endereço e ir ao passo 7.
3. **Desativar a conta** no Authentication (menu da linha › Desativar). Assim um aparelho com a conta aberta não renova o token. Os ID tokens já emitidos continuam valendo por até cerca de 1 h.
4. **Apagar os documentos.** No Firestore, apagar cada subcoleção de `users/{uid}` que aparece no `UserCollections` (`lib/core/firestore/`), hoje só `movies`, e o próprio `users/{uid}` se existir.
5. **Excluir a conta** no Authentication (menu da linha › Excluir conta).
6. **Conferir depois de 1 h** que `users/{uid}` continua vazio. Se um aparelho com o token antigo recriou algo, apagar de novo.
7. **Responder** ao remetente confirmando a exclusão e lembrando o que fica por um tempo (backups do Google por até cerca de 180 dias e a cópia em outros aparelhos), como na página.
8. **Guardar** o pedido e a resposta com o marcador `exclusao-atendida` e a data. Apagar os dois **6 meses** depois do atendimento.

Nunca copiar o `uid`, o e-mail ou as marcas para Issue, commit, log de sessão ou qualquer outro lugar.

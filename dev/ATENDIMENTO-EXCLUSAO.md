# Atendimento do pedido de exclusão por e-mail

Procedimento interno (decisão 015, sessão 025) para atender o pedido descrito em `docs/EXCLUSAO-DA-CONTA.md`. Fica fora da cópia pública e só existe no repositório privado.

**Prazo:** até 15 dias depois do recebimento, sem contar a espera da confirmação (passo 2). É um compromisso do projeto, e não o prazo do art. 19, II da LGPD, que trata da confirmação e do acesso aos dados.

**Regra das respostas:** responder sempre numa mensagem nova, digitando o endereço do `From`. Nunca usar "Responder", que segue o `Reply-To`. Nunca dizer se uma conta existe a quem não passou pelo passo 1.

## Pedido de exclusão da conta

1. **Conferir o remetente.** Em "Mostrar original" no Gmail, exigir `DMARC: PASS`, ou `SPF: PASS` e `DKIM: PASS` com o `d=` do domínio do `From`. Sem isso, ou com o pedido vindo de outro endereço, mandar ao `From` uma mensagem pedindo que escreva do endereço da conta, sem dizer se ela existe, e parar aqui.
2. **Pedir a confirmação.** Mandar ao endereço do `From` uma mensagem nova pedindo que confirme a exclusão respondendo a ela. Só seguir quando a confirmação chegar desse endereço e passar na mesma conferência do passo 1. Sem confirmação em 30 dias, encerrar o pedido e ir ao passo 10.
3. **Achar a conta.** No console do Firebase, em Authentication › Usuários, buscar pelo e-mail. A linha certa tem o e-mail **exatamente** igual ao do `From` (mesmo domínio, mesmos pontos) e o provedor `google.com`. Copiar o `uid`. Sem essa linha, mandar ao remetente que não há conta ligada ao endereço e ir ao passo 9 (os dados que ficaram sem conta).
4. **Desativar a conta** nessa linha (menu da linha › **Desativar conta**) e anotar a hora. Assim um aparelho com a conta aberta não renova o token. Os ID tokens já emitidos continuam valendo por até cerca de 1 h, e as regras do Firestore não olham se a conta está desativada.
5. **Apagar os documentos.** No Firestore, abrir `users/<uid>` e conferir que o `uid` do caminho é o mesmo da linha desativada. O documento `users/<uid>` aparece em itálico, porque o app não cria o pai, só as subcoleções. Apagar cada subcoleção do `UserCollections` (`lib/core/firestore/user_collections.dart`), hoje só `movies`, pelo menu da coleção › **Excluir coleção**.
6. **Esperar 1 h contada da desativação** (passo 4) e abrir `users/<uid>` de novo. Se um aparelho com o token antigo recriou algo, apagar de novo.
7. **Excluir a conta** no Authentication, só na linha que já aparece como desativada (menu da linha › **Excluir conta**).
8. **Responder** ao remetente, numa mensagem nova, confirmando a exclusão. Lembrar o que fica por um tempo (backups do Google por até cerca de 180 dias e a cópia em outros aparelhos) e o link <https://myaccount.google.com/permissions> para remover o acesso do app à conta Google, como na página.
9. **Dados sem conta.** Também quando o pedido é sobre marcas que ficaram depois de uma exclusão pelo app: no Authentication, conferir a lista de `uid` com conta; no Firestore, abrir a coleção `users` e apagar as subcoleções de todo `users/<uid>` que não está nessa lista. Não é preciso saber de quem eram. Responder ao remetente que os dados sem conta foram apagados.
10. **Guardar** o pedido, a confirmação e as respostas com o marcador `exclusao-atendida` e a data. Depois de **6 meses**, apagar as mensagens, inclusive as respostas em "Enviados", e esvaziar a Lixeira, que guarda por 30 dias.

Nunca copiar o `uid`, o e-mail ou as marcas para Issue, commit, log de sessão ou qualquer outro lugar.

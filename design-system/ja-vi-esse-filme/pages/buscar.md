# Override — Buscar

> Vale para a aba Buscar. O que não está aqui segue o `MASTER.md` e, para a grade, a paginação e a espera do 429, o override `descobrir.md`.
> Consulta à `ui-ux-pro-max` (stack Flutter) na sessão 010:
> - `ux` "Input Labels": todo campo tem rótulo visível, e a dica (placeholder) não serve de rótulo sozinha;
> - `ux` "No Results" e "Empty States": sem resultado não é tela em branco nem "0 resultados"; mostra mensagem com sugestão do que fazer;
> - `ux` "Autocomplete": resultados aparecem enquanto o usuário digita, com o pedido em debounce, sem exigir "enter";
> - stack Flutter "Use TextEditingController" e "Dispose controllers": o campo tem um controller, descartado no `dispose`;
> - stack Flutter "Use SliverList for custom scroll": campo e grade na mesma composição de slivers, sem lista aninhada.
> A busca "search field clear button" na stack Flutter não trouxe resultado. O botão de limpar e o teclado abaixo são padrão geral (fallback).

## Campo de busca
- No topo da tela, fora da rolagem da grade, com padding `md` nas laterais. É um `TextField` do tema (Material 3), com o rótulo visível "Título do filme" (o título da tela já diz "Buscar") e o ícone de lupa decorativo à esquerda.
- O texto tem no máximo 100 caracteres (`maxLength`, sem o contador visível). O limite também vale no domínio (`SearchQuery`), que conta code points; o campo conta caracteres visíveis. Um termo com acento combinante ou emoji composto pode caber no campo e passar do domínio, e aí a tela mostra o aviso de "longo demais".
- A ação do teclado é "buscar" (`TextInputAction.search`). Ela fecha o teclado e busca na hora, sem esperar o debounce.
- Quando há texto, aparece à direita um botão de limpar (`IconButton`, alvo ≥ 48dp, tooltip e rótulo de leitor de tela "Limpar busca"). Ele apaga o termo, volta ao estado inicial e põe o foco no campo (abrindo o teclado, se a rolagem o tinha fechado).
- Arrastar a grade fecha o teclado (`keyboardDismissBehavior: onDrag`).
- A aba guarda o termo e os resultados ao trocar de aba (shell vivo), mas o app não guarda histórico de busca no aparelho (política de privacidade, seção 3).

## Debounce e validação
- O pedido sai **400 ms** depois da última tecla. Cada tecla nova reinicia a contagem.
- O termo é aparado (trim). Com menos de **2** caracteres, nada é pedido e a tela fica no estado inicial.
- Um termo igual ao já mostrado não pede de novo.
- A resposta de um termo antigo que chega depois da do termo novo é descartada.

## Estados
- **Inicial (sem termo ou termo curto):** ícone de lupa grande em `onSurfaceVariant` e um texto curto convidando a buscar ("Busque pelo título, em português ou no original"). Não é erro nem vazio.
- **Carregando:** a mesma grade de skeleton da Descobrir, abaixo do campo, que continua editável. Um termo novo abre uma grade nova, que começa do topo (sem `PageStorageKey`).
- **Vazio:** "Nenhum filme encontrado para “<termo>”. Confira a grafia ou tente o título original." Não tem "Tentar de novo", porque repetir a mesma busca daria o mesmo resultado; a ação é editar o termo.
- **Longo demais:** "Use até 100 caracteres na busca.", sem pedido ao TMDB.
- **Erro:** mensagem por tipo de falha e o `RetryButton` com a espera do 429, como na Descobrir. Tentar de novo repete o termo atual.
- **Sucesso:** a grade de pôsteres da Descobrir, com paginação infinita.

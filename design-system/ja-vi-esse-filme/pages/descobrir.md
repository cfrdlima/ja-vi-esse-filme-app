# Override — Descobrir

> Vale para a aba Descobrir. O que não está aqui segue o `MASTER.md`.
> Consulta à `ui-ux-pro-max` (stack Flutter) na sessão 008:
> - `ListView.builder` / `GridView.builder`, `cached_network_image`, lazy loading e tamanho de imagem adequado (`w342`);
> - feedback de carregamento estável (skeleton, sem piscar) e status acessível de ocupado;
> - respeitar o "reduzir movimento".
> A busca por paginação infinita não trouxe regra específica. As regras de paginação abaixo são o padrão geral (fallback), e não resultado do banco.

## Grade
- `GridView.builder` com `SliverGridDelegateWithMaxCrossAxisExtent`, para que o número de colunas acompanhe a largura (2 colunas no celular comum e mais no tablet), sem largura fixa.
- Pôster 2:3, raio `md`, fundo `surfaceContainer`, sem sombra. Espaçamento `sm` entre os itens e padding `md` na tela (`MASTER.md`).
- Sem texto sobre o pôster na grade. O título vai no `Semantics` do pôster.
- Placeholder desenhado (ícone de filme em `onSurfaceVariant` sobre `surfaceContainer`) quando não há `poster_path` e enquanto a imagem carrega. Erro de imagem também mostra o placeholder, nunca uma imagem quebrada.

## Estados
- **Carregando (primeira página):** grade de skeleton com as mesmas células 2:3 da grade real, para não pular o layout. A animação é de pulso suave de opacidade e fica estática quando `MediaQuery.disableAnimationsOf` é verdadeiro. A grade tem `Semantics` de "carregando".
- **Vazio:** mensagem curta. Em Descobrir, o vazio vem do TMDB e não do usuário, então a ação é "Tentar de novo".
- **Erro (primeira página):** mensagem amigável por tipo de falha (sem rede, limite de requisições, genérica) e o botão "Tentar de novo", com alvo ≥ 48dp.
- **Sucesso:** grade.

## Paginação infinita (fallback)
- Pede a próxima página quando faltam cerca de 2 telas de conteúdo para o fim da rolagem, e não só no último item.
- Rodapé ocupando a largura toda da grade:
  - carregando: indicador de progresso pequeno e centralizado, que é o único spinner permitido, por ser localizado e não a tela inteira;
  - erro: texto curto e "Tentar de novo" no próprio rodapé, sem perder os filmes já carregados;
  - última página: nada.
- Nunca dispara dois pedidos da mesma página.

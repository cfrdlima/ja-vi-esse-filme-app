# Override — Descobrir

> Vale para a aba Descobrir. O que não está aqui segue o `MASTER.md`.
> Consulta à `ui-ux-pro-max` (stack Flutter) na sessão 008:
> - `ListView.builder` / `GridView.builder`, `cached_network_image`, lazy loading e tamanho de imagem adequado (`w342`);
> - feedback de carregamento estável (skeleton, sem piscar) e status acessível de ocupado;
> - respeitar o "reduzir movimento".
> A busca por paginação infinita não trouxe regra específica. As regras de paginação abaixo são o padrão geral (fallback), e não resultado do banco.
>
> Consulta na sessão 009 (seletor de categoria e espera do 429):
> - `ux` "Chip Collection Reflow": chips quebram linha quando falta espaço ou a fonte cresce, sem cortar o rótulo;
> - `ux` "Disabled States": o estado desabilitado precisa ser visualmente distinto do habilitado;
> - a stack Flutter não trouxe nada para seletor nem contagem regressiva (duas buscas sem resultado), então a contagem abaixo é padrão geral (fallback).

## Seletor de categoria
- Acima da grade: `ChoiceChip` de seleção única (Populares, Em cartaz, Melhor avaliados) dentro de um `Wrap`, com espaçamento `sm` e padding `md` nas laterais. Com fonte grande, os chips descem para a linha seguinte.
- Escolha única e sempre uma selecionada; começa em Populares.
- Cada categoria carrega na primeira vez que é aberta e depois fica viva: voltar a ela mostra os filmes e a rolagem em que estava, sem pedir de novo ao TMDB.
- Em cartaz usa `region=BR`.

## Grade
- Grade preguiçosa (`SliverGrid` com builder, num `CustomScrollView` para o rodapé caber na mesma rolagem), usando `SliverGridDelegateWithMaxCrossAxisExtent` com **largura máxima de célula de 180dp**. Assim o número de colunas acompanha a largura (3 colunas num celular de 400dp e mais no tablet), sem largura fixa.
- Pôster 2:3, raio `md`, fundo `surfaceContainer`, sem sombra. Espaçamento `sm` entre os itens e padding `md` na tela (`MASTER.md`).
- Sem texto sobre o pôster na grade. O título vai no `Semantics` do pôster.
- Placeholder desenhado (ícone de filme em `onSurfaceVariant` sobre `surfaceContainer`) quando não há `poster_path` e enquanto a imagem carrega. Erro de imagem também mostra o placeholder, nunca uma imagem quebrada.

## Estados
- **Carregando (primeira página):** grade de skeleton com as mesmas células 2:3 da grade real, para não pular o layout. A animação é de pulso suave de opacidade (ciclo de **1200 ms**, ida e volta, `Curves.easeInOut`) e fica estática quando `MediaQuery.disableAnimationsOf` é verdadeiro. A grade tem `Semantics` de "carregando".
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

## Espera do limite de requisições (429, fallback)
- Quando o TMDB manda `Retry-After`, o "Tentar de novo" (da tela e do rodapé) fica desabilitado e mostra "Tentar de novo em N s", contando de segundo em segundo, e volta ao texto normal quando a espera acaba.
- A espera tem teto de 60 s, para um valor enorme no header não travar o botão. Sem o header, o botão fica habilitado desde o início.
- A contagem não é região viva do leitor de tela, para não anunciar a cada segundo. O leitor lê o rótulo atual ao focar o botão.

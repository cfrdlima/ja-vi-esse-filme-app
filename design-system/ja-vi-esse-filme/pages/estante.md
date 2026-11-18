# Override — Estante

> Vale para a aba Estante (Fase 2). O que não está aqui segue o `descobrir.md` (grade, skeleton, paginação) e o `MASTER.md`.
> Consulta à `ui-ux-pro-max` (stack Flutter) na sessão 023:
> - `ux` "Empty States": mensagem útil e uma ação, nunca a tela em branco;
> - `ux` "Active State": a aba atual fica destacada (indicador e cor), e não só pela posição;
> - stack Flutter "Use ListView.builder": grade preguiçosa com builder, como no Descobrir;
> - `ux` "Continuous Animation": animação infinita só no indicador de carregamento (o skeleton para com o "reduzir movimento").
> A stack Flutter não trouxe nada para `TabBar` nem abas (duas buscas: "TabBar tabs" e "tab"). A estrutura das abas abaixo é padrão geral (fallback).

## Estrutura
- `Scaffold` com `AppBar` "Minha estante" e um `TabBar` no `bottom` com **Assistidos**, **Quero assistir** e **Favoritos**, nessa ordem, a mesma da fileira de marcas dos Detalhes. Começa em Assistidos.
- `TabBarView` com uma grade por aba. Cada aba carrega na primeira vez que é aberta e depois fica viva: voltar a ela mostra os filmes e a rolagem em que estava.
- Com fonte grande (escala acima de 1), o `TabBar` fica rolável (`isScrollable`), para o rótulo não ser cortado.
- Sem conta, não há `TabBar`, só o convite (ver "Sem conta").

## Grade
- Igual à do Descobrir: `SliverGrid` com célula de no máximo 180dp, pôster 2:3, sem texto sobre o pôster e com o título no `Semantics`.
- A mais recente primeiro: ordem pela data da marca da aba, descendente. Uma marca feita offline entra no topo com a data estimada.
- Toque abre os Detalhes do filme, empilhados na própria aba Estante. Os Detalhes esperam a tag `poster-<id>`, e o mesmo filme pode estar em duas abas vivas: **só a aba visível tem o Hero**, e as outras mostram o pôster sem ele.

## Cópia vencida (decisão 013)
- Uma cópia com mais de 6 meses desde o `cachedAt` não aparece como atual: a célula mostra o placeholder desenhado, e o `Semantics` diz "Atualizando dados do filme", sem o título velho.
- A renovação com o TMDB é pedida ao aparecer a cópia vencida, uma vez por filme enquanto a aba vive. Quando o Firestore devolve a cópia nova, a célula mostra o pôster e o título.
- Se a renovação falhar (sem rede, 429), o placeholder fica, sem mensagem de erro na célula. O toque continua abrindo os Detalhes, que buscam no TMDB.

## Estados (por aba)
- **Carregando:** skeleton da grade, como no Descobrir.
- **Vazio:** uma frase da aba ("Nenhum filme assistido ainda.", "Nada na lista de quero assistir.", "Nenhum favorito ainda.") e o botão "Descobrir filmes", que leva à aba Descobrir. Sem ícone: a mensagem segue a mesma do Descobrir e da Buscar (`MoviesMessage`).
- **Erro:** mensagem por tipo de falha e "Tentar de novo" (alvo ≥ 48dp), que reassina.
- **Sucesso:** grade.

## Paginação (stream com limite crescente)
- A aba assina os primeiros 20 filmes. Faltando cerca de 2 telas para o fim, o limite cresce em 20 e a assinatura é refeita com o limite novo: a lista inteira continua ao vivo, sem itens duplicados ou pulados.
- Rodapé: indicador pequeno enquanto o limite novo não chega; erro com "Tentar de novo" no rodapé, sem perder os filmes já mostrados; nada quando vieram menos filmes que o limite (fim).
- Nunca pede o mesmo limite duas vezes, nem com o erro no rodapé: só o "Tentar de novo" sai dele.
- Teto de 200 filmes por aba (decisão 014): com mais, o rodapé diz "Mostrando os 200 filmes mais recentes.".

## Sem conta
- No lugar das abas: ícone de estante, "Entre para guardar os filmes que você viu, quer ver e mais gosta." e o botão "Entrar com Google" (o mesmo do Perfil, com as diretrizes de marca do Google).
- Ao entrar, as abas aparecem em Assistidos. Ao sair da conta, a Estante volta para o convite e não mostra nada da conta anterior.

## Saindo da conta
- Quando a saída começa (inclusive na pergunta das marcas sem sincronizar), as abas saem de cena, com os streams e a renovação: no lugar, o skeleton com "Saindo". Se a pessoa ficar na conta, as abas voltam e assinam de novo.
- Se a saída falhar, a Estante não volta às abas, que reabririam o Firestore no cache que ficou: aviso "Não deu para sair da conta. Tente de novo no Perfil." com o botão "Ir para o Perfil".

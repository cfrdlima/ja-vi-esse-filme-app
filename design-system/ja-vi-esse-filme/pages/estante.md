# Override — Estante

> Vale para a aba Estante (Fase 2). O que não está aqui segue o `descobrir.md` (grade, skeleton, paginação) e o `MASTER.md`.
> Consulta à `ui-ux-pro-max` (stack Flutter) na sessão 023:
> - `ux` "Empty States": mensagem útil e uma ação, nunca a tela em branco;
> - `ux` "Active State": a aba atual fica destacada (indicador e cor), e não só pela posição;
> - stack Flutter "Use ListView.builder": grade preguiçosa com builder, como no Descobrir;
> - `ux` "Continuous Animation": animação infinita só no indicador de carregamento (o skeleton para com o "reduzir movimento").
> A stack Flutter não trouxe nada para `TabBar` nem abas (duas buscas: "TabBar tabs" e "tab"). A estrutura das abas abaixo é padrão geral (fallback).

## Estrutura
- `Scaffold` com `AppBar` "Minha estante" e um `TabBar` no `bottom` com **Assistidos**, **Quero assistir**, **Favoritos** e **Listas**, nessa ordem: as três primeiras seguem a fileira de marcas dos Detalhes, e Listas fica por último (decisão 019). Começa em Assistidos.
- `TabBarView` com uma grade por aba. Cada aba carrega na primeira vez que é aberta e depois fica viva: voltar a ela mostra os filmes e a rolagem em que estava.
- O `TabBar` é sempre rolável (`isScrollable`, alinhado ao início): com as quatro abas, "Quero assistir" saía cortado num Pixel 9 Pro mesmo com a fonte normal (sessão 029).
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

## Aba Listas (sessão 029, decisão 019)
> Consulta à `ui-ux-pro-max` (stack Flutter) na sessão 029: `ux` "Confirmation Dialogs" (confirmar antes de apagar), "Confirmation Messages" (aviso curto do sucesso), "Empty States" (mensagem e ação), "Input Labels" (rótulo visível, não só o placeholder), "Gesture Conflicts" (nada de deslizar para o lado no conteúdo, que briga com as abas) e stack Flutter "Use ListView.builder" e "Use keys for stateful items". As buscas por folha com caixas de seleção ("bottom sheet checkbox list", "modal sheet") e por limite de caracteres não trouxeram regra específica; a folha e o contador abaixo são padrão geral (fallback).

- **Lista das listas:** `ListView.builder` de `ListTile` com `ValueKey` do id, o ícone `list` e o nome em uma linha, com reticências e o nome inteiro no `Semantics`. Ordem alfabética, sem diferenciar maiúsculas e acentos. Sem contagem de filmes (pediria uma leitura por lista).
  - Toque abre a tela da lista, empilhada na aba Estante.
  - `IconButton` `more_vert` à direita (alvo de 48dp, tooltip "Opções da lista <nome>") abre o menu com **Renomear** e **Apagar**. Sem deslizar para apagar.
- **Nova lista:** `FilledButton.tonal.icon` (`add`) "Nova lista" no topo da aba, acima das listas. Com 50 listas, o botão fica desabilitado e o texto "Você chegou ao limite de 50 listas." aparece abaixo dele.
- **Diálogo do nome** (criar e renomear): `AlertDialog` com o título "Nova lista" ou "Renomear lista", um `TextField` com o rótulo visível "Nome da lista", `autofocus`, a primeira letra maiúscula e o contador do `maxLength` (50) à vista. O erro aparece embaixo do campo ("Dê um nome à lista."), e não no topo. O botão "Criar" ou "Salvar" fica desabilitado com o nome inválido, e o Enter do teclado confirma. "Cancelar" fecha sem gravar.
- **Criar e renomear são otimistas**, como as marcas: a lista aparece ou muda na hora. Se o servidor recusar, a mudança volta, e um `SnackBar` mostra a falha com "Tentar de novo".
- **Apagar:** sempre com `AlertDialog` "Apagar a lista <nome>?", o texto "Os filmes saem desta lista, mas continuam nas suas marcas e nas outras listas." e as ações "Cancelar" e "Apagar" (cor `error`). Apagar **não** é otimista, porque precisa do servidor (decisão 019): a linha fica desabilitada, com um indicador pequeno no lugar do menu. Sucesso: a linha some, e o `SnackBar` diz "Lista apagada.". Falha (sem rede): a linha volta, e o `SnackBar` mostra a falha com "Tentar de novo".
- **Estados:** carregando com o skeleton de linhas; vazio com "Nenhuma lista ainda." e o botão "Criar lista", que abre o diálogo; erro com a mensagem e "Tentar de novo"; sucesso com a lista.

## Tela da lista
- `AppBar` com o nome da lista (uma linha, reticências) e o mesmo menu `more_vert` com Renomear e Apagar. Depois de apagar, a tela volta para a aba Listas.
- **Grade** igual à das abas: os mais recentes primeiro (`lists.<id>` descendente), o mesmo limite crescente com teto de 200, a mesma cópia vencida com placeholder e renovação, e o Hero só na tela visível.
- **Tirar o filme:** um toque longo na célula abre uma folha com o título do filme e a ação "Tirar da lista". O leitor de tela recebe a mesma ação como ação própria da célula ("Tirar da lista"). Depois de tirar, o `SnackBar` diz "Filme tirado da lista." com "Desfazer". Desfazer põe o filme de volta, mas no topo, porque a hora em que entrou é a do servidor (decisão 019).
- **Estados:** carregando com o skeleton da grade; vazio com "Nenhum filme nesta lista." e "Descobrir filmes"; erro com "Tentar de novo"; sucesso com a grade. Se a lista for apagada em outro aparelho com a tela aberta: "Esta lista foi apagada." e o botão "Voltar para as listas".

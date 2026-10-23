# Override — Detalhes do filme

> Vale para a tela de detalhes, aberta pela Descobrir e pela Buscar. O que não está aqui segue o `MASTER.md`. O pôster, o placeholder e o pulso do skeleton são os do override `descobrir.md`.
> Consulta à `ui-ux-pro-max` (stack Flutter) na sessão 011:
> - `ux` "Back Button" e `back-behavior`: o voltar é previsível e preserva a rolagem e o estado da tela anterior;
> - `ux` "Line Length" e "Line Height": texto longo com no máximo 65 a 75 caracteres por linha e entrelinha de 1,5;
> - `ux` "Alt Text": imagem com conteúdo tem texto alternativo;
> - `ux` "Image Optimization": tamanho de imagem adequado ao espaço;
> - `truncation-strategy` e `dynamic-type`: quebrar linha antes de cortar, e crescer com a fonte do sistema;
> - stack Flutter "Use Hero for transitions": avaliado e não usado (ver "Transição");
> - stack Flutter "Use ListView.builder": avaliado para o elenco e não usado (ver "Elenco").
> A busca por lista horizontal de imagens na stack Flutter não trouxe resultado. O layout do elenco abaixo é padrão geral (fallback).

## Estrutura
- `Scaffold` com `AppBar` de voltar (seta padrão, com tooltip do Material) e o título do filme numa linha, com reticências. A barra inferior das abas continua visível, porque a tela é uma rota dentro da aba.
- O conteúdo rola inteiro na vertical, com padding `md`, e a largura do texto fica limitada a **640dp** (`AppSizes.readableWidth`), centralizada no tablet.
- Ordem de leitura: cabeçalho, gêneros, sinopse, elenco.

## Cabeçalho
- Linha com o pôster à esquerda (**120dp** de largura, 2:3, `w342`, raio `md`) e, à direita, numa coluna que quebra linha:
  - título em `headlineSmall`, sem limite de linhas;
  - data de lançamento no formato curto do pt-BR ("25/05/1977");
  - duração em horas e minutos ("2 h 1 min", ou "45 min" abaixo de uma hora);
  - nota com uma casa decimal e vírgula ("8,2"), com ícone de estrela decorativo e rótulo de leitor de tela "Nota 8,2 de 10".
- O que o TMDB não mandar (sem data, duração nula ou 0, nota 0) some, sem traço nem "desconhecido".
- O pôster aqui é imagem com conteúdo: o `Semantics` diz "Pôster de <título>". Sem `poster_path`, mostra o placeholder desenhado.

## Gêneros
- `Wrap` de rótulos não interativos (`Chip` sem ação), espaçamento `sm`, que quebram linha com fonte grande. Sem gêneros, a seção some.

## Sinopse
- Título de seção "Sinopse" em `titleMedium`, marcado como cabeçalho para o leitor de tela, e o texto em `bodyLarge` com entrelinha 1,5, sem limite de linhas (o texto é o conteúdo principal; cortar e pedir "ler mais" esconderia sem ganho).
- Sinopse pt-BR vazia usa a do idioma original (decisão 008). Sem nenhuma, mostra "Sinopse não disponível." em `onSurfaceVariant`.

## Elenco
- Título de seção "Elenco" e uma fileira horizontal com até **15** pessoas, na ordem do TMDB (`order`).
- Cada pessoa: foto 2:3 com **96dp** de largura na fonte padrão, crescendo na mesma escala da fonte do sistema para o nome não quebrar no meio da palavra (`w185`, raio `md`, placeholder de pessoa sem `profile_path`), o nome em `bodyMedium` e o personagem em `bodySmall` `onSurfaceVariant`, cada um com até 2 linhas e reticências. O leitor de tela lê "<nome>, <personagem>" num nó só, e a foto é decorativa dentro dele.
- A fileira é uma `Row` dentro de um `SingleChildScrollView` horizontal, e não um `ListView.builder`: são no máximo 15 itens, e assim a altura acompanha a fonte grande sem altura fixa. A última pessoa visível fica cortada na borda, o que mostra que a fileira rola.
- Sem elenco, a seção some.

## Estados
- **Carregando:** skeleton com o bloco do pôster, três linhas de texto do cabeçalho e um bloco de parágrafo, no pulso da Descobrir (parado com "reduzir movimento"). `Semantics` de "carregando". O título da `AppBar` fica vazio até o filme chegar.
- **Não encontrado (404 ou id inválido na rota):** a mensagem centralizada da grade (`MoviesMessage`), "Filme não encontrado.", e nenhuma ação além do voltar da `AppBar`. Repetir daria o mesmo resultado.
- **Erro:** mensagem por tipo de falha e o `RetryButton` com a espera do 429, como na grade.
- **Sucesso:** conteúdo acima.
- A mensagem do não encontrado e do erro é região viva (`liveRegion`), como na grade.

## Navegação e transição
- Tocar num pôster da grade abre os detalhes na mesma aba (`/descobrir/filme/:id` ou `/buscar/filme/:id`). O pôster da grade tem `Semantics` de botão e alvo do tamanho da célula (sempre ≥ 48dp).
- O voltar (seta, gesto ou botão do sistema) desempilha só os detalhes e devolve a grade na mesma rolagem, com a busca ou a categoria intactas.
- **Transição:** a padrão do Material para rota empilhada, sem `Hero`. As páginas do TMDB podem repetir um filme, e duas grades com a mesma tag de `Hero` quebram a transição.

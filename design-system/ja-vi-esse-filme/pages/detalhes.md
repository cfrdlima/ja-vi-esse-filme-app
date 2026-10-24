# Override — Detalhes do filme

> Vale para a tela de detalhes, aberta pela Descobrir e pela Buscar. O que não está aqui segue o `MASTER.md`. O pôster, o placeholder e o pulso do skeleton são os do override `descobrir.md`.
> Consulta à `ui-ux-pro-max` (stack Flutter) na sessão 011:
> - `ux` "Back Button" e `back-behavior`: o voltar é previsível e preserva a rolagem e o estado da tela anterior;
> - `ux` "Line Length" e "Line Height": texto longo com no máximo 65 a 75 caracteres por linha e entrelinha de 1,5;
> - `ux` "Alt Text": imagem com conteúdo tem texto alternativo;
> - `ux` "Image Optimization": tamanho de imagem adequado ao espaço;
> - `truncation-strategy` e `dynamic-type`: quebrar linha antes de cortar, e crescer com a fonte do sistema;
> - stack Flutter "Use Hero for transitions": adotado na sessão 012 (ver "Transição");
> - stack Flutter "Use ListView.builder": avaliado para o elenco e não usado (ver "Elenco").
> A busca por lista horizontal de imagens na stack Flutter não trouxe resultado. O layout do elenco abaixo é padrão geral (fallback).

## Estrutura
- `Scaffold` com `AppBar` de voltar (seta padrão, com tooltip do Material) e o título do filme numa linha, com reticências. A barra inferior das abas continua visível, porque a tela é uma rota dentro da aba.
- O conteúdo rola inteiro na vertical, com padding `md`, e a largura do texto fica limitada a **640dp** (`AppSizes.readableWidth`), centralizada no tablet.
- Ordem de leitura: cabeçalho, gêneros, sinopse, elenco, trailers.

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

## Trailers
> Consulta à `ui-ux-pro-max` (stack Flutter) na sessão 013: `ux` "Auto-Play Video" (tocar para assistir, nunca tocar sozinho), `touch-target-size` (≥ 48dp) e `press-feedback` (ripple), `icons` "arrow-square-out" (indicador de link externo: decorativo ao lado de texto visível, e o controle tem nome acessível) e stack Flutter "Use keys for stateful items". A busca por link externo na stack Flutter não trouxe resultado; o resto desta seção é padrão geral (fallback).

- Título de seção "Trailers" (cabeçalho para o leitor de tela) e uma lista vertical com até **5** vídeos, depois do elenco. A ordem vem do domínio: oficiais primeiro, depois português antes dos outros idiomas, depois Brasil antes de Portugal, e por último trailer antes de teaser. Vídeos com a mesma `key` aparecem uma vez só.
- Cada vídeo é um `ListTile` com o ícone de play à esquerda, o nome em `bodyLarge` com até 2 linhas e reticências, o tipo e o site em `bodySmall` `onSurfaceVariant` ("Trailer · YouTube") e o ícone de link externo (`open_in_new`) à direita. O item tem `ValueKey` da `key` do vídeo e o ripple do Material, e a altura mínima é de 48dp, crescendo com a fonte.
- Os ícones são decorativos. O leitor de tela lê o item como link: "<nome>, <tipo>. Abre no YouTube".
- **Sem miniatura:** a imagem viria do `img.youtube.com`, um host a mais para validar e declarar na política. Fica para depois, se fizer falta.
- Tocar abre o YouTube fora do app (decisão 009). Se nenhum app abrir o link, aparece um `SnackBar` com "Não foi possível abrir o trailer.".
- Sem trailer, a seção some.

## Estados
- **Carregando:** skeleton com o bloco do pôster, três linhas de texto do cabeçalho e um bloco de parágrafo, no pulso da Descobrir (parado com "reduzir movimento"). `Semantics` de "carregando". O título da `AppBar` fica vazio até o filme chegar.
- **Não encontrado (404 ou id inválido na rota):** a mensagem centralizada da grade (`MoviesMessage`), "Filme não encontrado.", e nenhuma ação além do voltar da `AppBar`. Repetir daria o mesmo resultado.
- **Erro:** mensagem por tipo de falha e o `RetryButton` com a espera do 429, como na grade.
- **Sucesso:** conteúdo acima.
- A mensagem do não encontrado e do erro é região viva (`liveRegion`), como na grade.

## Navegação e transição
- Tocar num pôster da grade abre os detalhes na mesma aba (`/descobrir/filme/:id` ou `/buscar/filme/:id`). O pôster da grade tem `Semantics` de botão e alvo do tamanho da célula (sempre ≥ 48dp).
- O voltar (seta, gesto ou botão do sistema) desempilha só os detalhes e devolve a grade na mesma rolagem, com a busca ou a categoria intactas.
- **Transição:** a padrão do Material para rota empilhada, com o pôster voando da grade até o cabeçalho num `Hero(tag: 'poster-<id>')` (sessão 012; consulta à `ui-ux-pro-max`: stack Flutter "Use Hero for transitions", `ux` "Excessive Motion", com um único elemento animado, e "Reduced Motion").
  - **Tag única:** a tag só precisa ser única dentro de um navigator. Cada aba tem o seu (o go_router 18.1.0 dá um `HeroController` do Material a cada um), a grade tira os ids repetidos que o TMDB manda entre as páginas e a Descobrir só monta a grade de uma categoria por vez.
  - **Destino no primeiro quadro:** os detalhes carregam depois do push, e sem destino o `Hero` não voa. A grade passa o `Movie` à rota (`extra`), e o skeleton mostra o pôster de verdade no lugar do bloco pulsante. Sem `extra` (URL direta), fica o skeleton de sempre, sem voo.
  - **Erro e "não encontrado"** não têm pôster, então o voltar desses estados usa só a transição da rota.
  - **Movimento reduzido:** com `disableAnimations`, não há `Hero` e a troca é a da rota.
  - **Mesma imagem no cache:** o pôster é decodificado no tamanho do arquivo (`w342`), sem `memCacheWidth` por largura. Assim a grade, o voo e o cabeçalho usam a mesma imagem já decodificada, e o pôster voa desenhado, sem passar pelo placeholder.
  - **Teclado:** o shell não encolhe com o teclado (cada tela desvia sozinha, e a aba recebe só a parte do teclado acima da barra). Se o navigator da aba mudasse de tamanho com o teclado fechando no meio do voo, o pôster sairia esticado.

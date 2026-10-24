# Override — Sobre

> Vale para a tela "Sobre", aberta pela aba Perfil, e para a entrada que leva até ela. O que não está aqui segue o `MASTER.md`.
> Consulta à `ui-ux-pro-max` (stack Flutter) na sessão 014:
> - `ux` "Back Button" e `back-behavior`: o voltar é previsível e devolve o Perfil como estava;
> - `nav-hierarchy`: a navegação principal (abas) fica separada da secundária (entradas do Perfil);
> - `ux` "Alt Text": imagem com conteúdo tem texto alternativo (o logo do TMDB);
> - pro-rules "Correct Brand Logos": logo oficial, sem mudar cor nem proporção;
> - pro-rules "Touch Target Minimum", "Tap feedback" e "Semantic native controls": alvo ≥ 48dp, ripple do Material e `ListTile` no lugar de um contêiner com gesto;
> - `icons` "arrow-square-out": indicador de link externo decorativo ao lado de texto visível, com o controle tendo nome acessível;
> - stack Flutter "Use Semantics widget" e "Use Navigator 2.0 or GoRouter" (a rota é do go_router, com deep link `/perfil/sobre`).
> As buscas por tela de configurações e por indicador de link externo no domínio `ux` trouxeram só resultados de web, sem aplicação aqui. O layout abaixo é padrão geral (fallback).

## Entrada no Perfil
- Enquanto o Perfil não tem conteúdo próprio (Fase 2), ele mostra uma lista com uma entrada só: `ListTile` com o ícone `info_outline` decorativo, o título "Sobre o app" em `bodyLarge` e o chevron à direita. Altura mínima de 48dp, crescendo com a fonte, e ripple do Material.
- O leitor de tela lê "Sobre o app, botão". Tocar empilha `/perfil/sobre` na aba, com a barra das abas visível.

## Estrutura
- `Scaffold` com `AppBar` de voltar (seta padrão, com tooltip do Material) e o título "Sobre". Rota empilhada com `MaterialPage` explícita, pelo mesmo motivo dos detalhes (BACKLOG, go_router 18.1.0).
- Conteúdo numa lista vertical com padding `md` e largura limitada a **640dp** (`AppSizes.readableWidth`), centralizada no tablet.
- Ordem de leitura: identidade do app, dados do TMDB, privacidade, licenças.

## Identidade do app
- Nome "Já Vi Esse Filme" em `headlineSmall` (Playfair Display), que é a marca mais destacada da tela, e a versão em `bodyMedium` `onSurfaceVariant` ("Versão 1.0.0"). A versão vem do build (`--dart-define=APP_VERSION`, tirada do `pubspec.yaml`); sem ela, a linha some.

## Dados do TMDB
- Título de seção "Dados e imagens" em `titleMedium`, marcado como cabeçalho para o leitor de tela.
- Logo "alt short" do TMDB, em PNG com 1x, 2x e 3x (o TMDB só fornece SVG, e o app não usa `flutter_svg`). Largura de **120dp**, menor que o nome do app, como pedem os termos do TMDB (§3). Cor e proporção do arquivo oficial, sem tingir, espelhar ou girar. O gradiente do logo é claro e fica legível sobre o `surface` escuro.
  - Exceção registrada ao "Vector-Only Assets" das pro-rules: o raster vem do SVG oficial em três densidades, que basta para um logo de tamanho fixo.
- A altura do logo fica reservada pela proporção do SVG (`AppSizes.tmdbLogoAspectRatio`), para o aviso não pular quando a imagem carrega. Se o PNG não carregar, aparece o nome "TMDB" em `titleSmall`, porque a atribuição é obrigatória.
- O logo é imagem com conteúdo: `Semantics` com "Logo do TMDB" e `excludeSemantics` na imagem.
- Aviso em `bodyMedium`: "Este app usa o TMDB e as APIs do TMDB, mas não é endossado, certificado nem aprovado de outra forma pelo TMDB." Logo abaixo, o texto exato dos termos em `bodySmall` `onSurfaceVariant`: "This application uses TMDB and the TMDB APIs but is not endorsed, certified, or otherwise approved by TMDB." O original fica fora da tradução do ARB e é lido com `locale` `en` no `Semantics`, para o leitor de tela pronunciar em inglês.

## Privacidade
- Título de seção "Privacidade" (cabeçalho para o leitor de tela) e um resumo curto em `bodyMedium` com entrelinha 1,5: o que o app guarda no aparelho hoje e que não há conta nem anúncio. O texto acompanha a versão publicada da política (decisão 006).
- Link "Política de privacidade" como `ListTile`: ícone `privacy_tip_outlined` decorativo à esquerda, título em `bodyLarge`, subtítulo "Abre no navegador" em `bodySmall` `onSurfaceVariant` e o ícone `open_in_new` decorativo à direita. Altura mínima de 48dp e ripple do Material.
- O leitor de tela lê o item como link: "Política de privacidade. Abre no navegador".
- Tocar abre o GitHub Pages fora do app (decisões 006 e 009). Se nenhum app abrir o link, aparece um `SnackBar` com "Não foi possível abrir a política de privacidade.".

## Licenças
- Título de seção "Licenças" e um `ListTile` "Licenças de código aberto" com o ícone `description_outlined` decorativo e o chevron à direita.
- Tocar abre o `showLicensePage` do Flutter, com o nome e a versão do app no topo. Fica sem ícone até o ícone do app existir (Fase 4). A lista inclui as fontes Inter e Playfair Display (OFL), registradas no `LicenseRegistry`, além das licenças dos pacotes, que o Flutter já junta.
- A página de licenças é do Flutter e herda o tema do app; não recebe override.

## Estados
- A tela é estática: o conteúdo vem do app e do ARB, sem pedido de rede. Por isso não há carregando, vazio nem erro de carga.
- O único erro é o de abrir o link da política, mostrado como `SnackBar` (acima), sem exceção.
- A versão é constante de compilação, então não há estado de carregamento.

## Fonte grande
- Títulos, aviso e resumo quebram linha sem limite. Os `ListTile` crescem com a fonte, e os títulos deles quebram em até 2 linhas com reticências.
- O logo mantém 120dp: é marca, não texto.

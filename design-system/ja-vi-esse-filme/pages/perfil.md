# Override — Perfil

> Vale para a aba Perfil com a conta (Fase 2). A entrada "Sobre o app" segue o `sobre.md`. O que não está aqui segue o `MASTER.md`.
> Consulta à `ui-ux-pro-max` (stack Flutter) na sessão 020:
> - `ux` "Accessible Authentication (Minimum)": o login é OAuth pelo seletor do sistema, sem senha nem código para digitar;
> - `ux` "ARIA Labels": todo controle tem nome acessível (botão do Google, "Sair", "Tentar de novo");
> - `ux` "Loading Indicators" e "Loading States": skeleton estável no carregando, e retorno de "ocupado" no botão enquanto o seletor está aberto, sem congelar a tela;
> - pro-rules "Correct Brand Logos", "Touch Target Minimum" e "Semantic native controls";
> - stack Flutter "Use pub.dev packages": `cached_network_image` para a foto.
> A busca por avatar e placeholder na stack Flutter não trouxe nada específico. O layout abaixo é padrão geral (fallback).
> Botão do Google: [diretrizes de marca](https://developers.google.com/identity/branding-guidelines), conferidas na sessão 020.

## Estrutura
- `Scaffold` com `AppBar` "Perfil". O corpo é uma `ListView` com padding `md` e largura limitada a `AppSizes.readableWidth`.
- Ordem: o bloco da conta (que muda com o estado), um divisor e a entrada "Sobre o app". A entrada aparece em **todos** os estados, igual ao `sobre.md`.

## Estados do bloco da conta
O bloco segue o `SessionState`, com um `switch` exaustivo.

| Estado | Conteúdo |
|---|---|
| `SessionLoading` | Skeleton: círculo do avatar e duas barras (nome e linha de apoio) com o `SkeletonPulse`. Sem spinner solto. O leitor de tela lê "Carregando a conta". |
| `SessionSignedOut` | Ícone `account_circle_outlined` decorativo em `AppSizes.stateIcon`, o título "Entre para guardar seus filmes" em `titleMedium`, o texto de apoio em `bodyMedium` `onSurfaceVariant` (o que a conta guarda: assistidos, quero ver e favoritos, sincronizados entre aparelhos; Descobrir e Buscar continuam sem conta) e o botão do Google. |
| `SessionSigningIn` | Mesmo layout do deslogado. O botão fica desabilitado, e o "G" dá lugar a um `CircularProgressIndicator` de 20dp. O texto não muda, para o botão não mudar de largura. O `Semantics` do botão diz "Entrando com o Google". |
| `SessionSignedIn` | Avatar de **72dp** (`AppSizes.profileAvatar`), o nome em `titleLarge` (sem nome, "Sua conta") e o e-mail em `bodyMedium` `onSurfaceVariant`. Abaixo, `OutlinedButton` "Sair" com o ícone `logout`. |
| `SessionSignInFailed` | O layout do deslogado com a mensagem do `failureMessage` em `bodyMedium` cor `error`, acima do botão. O botão do Google funciona como "tentar de novo" (tocar chama o `signIn`), porque é a mesma ação. |
| `SessionSignOutFailed` | O layout do logado com a mensagem do `failureMessage` em `bodyMedium` cor `error` e, no lugar do "Sair", o `RetryButton.filled`, que chama o `signOut`. |

Não há estado "vazio": sem conta, o deslogado é o vazio, e ele já chama para a ação.

## Botão "Entrar com o Google"
- O desenho é nosso, com o "G" oficial, porque os botões prontos do pacote do Google trazem o texto em inglês gravado na imagem. A diretriz permite e incentiva traduzir o texto.
- Tema **Dark** da diretriz, que é cor de marca e por isso fica fora da paleta do app. Os tokens ficam em `AppColors` (`googleButtonFill`, `googleButtonStroke`, `googleButtonText`), sem `Color(0x…)` no widget:
  - fundo `#131314`;
  - borda de 1dp `#8E918F`, por dentro;
  - texto `#E3E3E3`.

  O contraste do texto sobre o fundo é de cerca de 14:1, acima do AA.
- Forma **pílula**, com raio igual a metade da altura. Altura mínima de **48dp**, que é o alvo de toque do app. A diretriz permite escalar o botão; o botão dela tem 40, e a altura cresce com a fonte.
- Espaçamento da diretriz: 12dp antes do "G", 10dp entre o "G" e o texto e 12dp depois do texto. O "G" mede **20dp** e vem do `g-logo.png` oficial (200×204), só redimensionado, sem trocar cor nem proporção.
- Texto "Entrar com o Google" em **Google Sans Medium 14/20**. A fonte é o recorte Latin do `GoogleSans[GRAD,opsz,wght].ttf` (OFL), instanciado em `wght=500` (52 KB), com a licença no `LicenseRegistry`. A família `GoogleSans` só serve a este botão; o resto do app segue o `MASTER.md`. Com fonte grande, o texto quebra em até 2 linhas, e o botão cresce na altura.
- Proibido pela diretriz: o "G" sozinho sem o botão, o "G" monocromático, "Google" sozinho como rótulo, e mudar o tamanho relativo ou a cor do "G".
- Desabilitado (entrando): opacidade 0,38 no texto e na borda, padrão do Material. O "G" é trocado pelo indicador, nunca desbotado.
- Ripple do Material dentro da pílula. O leitor de tela lê "Entrar com o Google, botão". O "G" é decorativo (`excludeSemantics`), porque o texto já diz a marca.

## Avatar
- `CircleAvatar` de 72dp com a foto pelo `cached_network_image`, com `memCacheWidth` no tamanho físico.
- **Host validado:** a foto só carrega com `https` e o host `googleusercontent.com` ou um subdomínio dele. Fora disso, sem foto ou com erro no download, aparece o placeholder.
- Placeholder desenhado: a inicial do nome em `titleLarge` sobre `secondaryContainer`, ou o ícone `person` quando não há nome. Nunca uma imagem quebrada.
- A foto é decorativa ao lado do nome escrito (`excludeSemantics`). O leitor de tela lê o nome e o e-mail.
- **Logout:** a entrada da foto sai do cache de disco e da memória quando a sessão fecha (decisão 010: o logout limpa o aparelho).

## Fonte grande
- O nome quebra em até 2 linhas com reticências, e o e-mail fica em 1 linha com reticências no fim.
- Os botões crescem na altura. O avatar mantém 72dp.
- Teste com fonte 2x numa tela de 360×640 lógicos, em todos os estados, sem overflow.

## Movimento
- A troca entre estados usa o `AnimatedSwitcher` com a duração curta do `AppMotion`, e fica instantânea com o "reduzir movimento" ligado.

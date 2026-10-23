# 006 — Política de privacidade: fonte no repositório, publicação em repositório público separado

**Data**: 2026-10-23 · **Status**: aceita

## Contexto
A Play Store exige uma política de privacidade numa URL pública, e a política precisa estar acessível também de dentro do app. A LGPD (art. 9º) pede que o titular tenha acesso fácil às informações sobre o tratamento dos dados e a um canal de contato. O contato escolhido tem dois canais: as Issues do GitHub, para dúvidas gerais, e o e-mail `xbtechnologies.app@gmail.com`, canal privado para pedidos do titular. Uma Issue é sempre pública, e quem faz um pedido pela LGPD tende a se identificar nela (revisão da sessão 007).

O repositório do app (`cfrdlima/ja-vi-esse-filme-app`) é **privado** e não tem GitHub Pages. Por isso o público não consegue ler uma política hospedada nele nem abrir Issues.

## Opções consideradas
1. **Tornar este repositório público.** Issues e Pages sairiam de um lugar só. Em troca, todo o código e o histórico ficam expostos, o que exige uma auditoria do histórico antes.
2. **Repositório público separado**, só para a política (GitHub Pages) e para o contato (Issues). O código continua privado. O custo é manter duas cópias do texto em sincronia.
3. **Texto só dentro do app (ARB).** Não atende a exigência da Play Store de URL pública, e um texto longo em ARB é ruim de manter e de revisar.

## Decisão
Opção 2.
- **Fonte da verdade:** `docs/PRIVACIDADE.md`, neste repositório, versionado e revisado junto com o código que muda o que o app coleta.
- **Publicação:** um repositório público separado, sem código do app, com o texto no GitHub Pages e as Issues abertas para contato. O nome provisório é `cfrdlima/ja-vi-esse-filme-suporte`. Ele é criado na sessão da tela "Sobre" (Fase 1), com confirmação do usuário por ser uma ação pública, para que o link da tela já tenha destino. A cada mudança de versão da política, ele recebe uma cópia do `docs/PRIVACIDADE.md`, seguindo o procedimento abaixo.
- **No app:** a tela "Sobre" (Fase 1) mostra um resumo curto, em ARB conforme a decisão 004, e um link só para a página do GitHub Pages. A própria página aponta para as Issues e para o e-mail, e assim a lista de hosts permitidos do app fica com um único host. O link abre em modo externo e com host validado. Isso exige o `url_launcher`, que precisa ser aprovado como dependência e registrado em decisão quando a tela "Sobre" for implementada.
- **Mudança no que o app coleta** (cache de imagens na Fase 1, login na Fase 2, "já vi" na Fase 3, crash reporting e um eventual proxy da decisão 001 na Fase 4): a mesma sessão atualiza o `docs/PRIVACIDADE.md`, inclusive a data de vigência.
- **Procedimento de publicação**, para que nada do repositório privado vaze:
  - o repositório público nasce novo e vazio, nunca como fork, `subtree split` ou push de uma branch deste repositório;
  - o texto é copiado como conteúdo de arquivo, sem git;
  - os comentários HTML internos (`<!-- ... -->` e marcadores "A REVISAR") saem da cópia;
  - `gitleaks detect` roda no repositório público antes de cada push;
  - o repositório público não recebe workflows nem secrets do privado.

## Consequências
- Até o repositório público existir, a política não tem URL pública e as Issues não funcionam para quem está de fora. O e-mail já funciona.
- Há o risco de as duas cópias divergirem. Por isso o checklist de release (Fase 4) compara o `docs/PRIVACIDADE.md` com a versão publicada.
- O host da URL pública (`cfrdlima.github.io`) entra na lista de hosts permitidos para links externos, criada junto com o `url_launcher`. Essa lista não é o `AppConfig.allowedHosts`, que valida só a base URL da API e recebe o token Bearer. Pôr o `github.io` nela mandaria o token para o Pages. A validação do link usa uma URL constante, esquema `https`, host comparado por igualdade (sem `endsWith`), sem `userInfo` e prefixo de path `/ja-vi-esse-filme-suporte/`.
- Se a conta `cfrdlima` for renomeada, outra pessoa pode registrar o subdomínio `cfrdlima.github.io`, e os links dos APKs antigos passariam a apontar para conteúdo de terceiros. Para evitar isso, a conta não é renomeada, ou passa-se a usar um domínio próprio com CNAME verificado no GitHub.

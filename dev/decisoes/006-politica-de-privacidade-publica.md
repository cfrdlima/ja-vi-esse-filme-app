# 006 — Política de privacidade: fonte no repositório, publicação em repositório público separado

**Data**: 2026-10-23 · **Status**: aceita

## Contexto
A Play Store exige uma política de privacidade numa URL pública, e a política precisa estar acessível também de dentro do app. A LGPD (art. 9º) pede que o titular tenha acesso fácil às informações sobre o tratamento dos dados e a um canal de contato. O contato escolhido são as Issues do GitHub.

O repositório do app (`cfrdlima/ja-vi-esse-filme-app`) é **privado** e não tem GitHub Pages. Por isso o público não consegue ler uma política hospedada nele nem abrir Issues.

## Opções consideradas
1. **Tornar este repositório público.** Issues e Pages sairiam de um lugar só. Em troca, todo o código e o histórico ficam expostos, o que exige uma auditoria do histórico antes.
2. **Repositório público separado**, só para a política (GitHub Pages) e para o contato (Issues). O código continua privado. O custo é manter duas cópias do texto em sincronia.
3. **Texto só dentro do app (ARB).** Não atende a exigência da Play Store de URL pública, e um texto longo em ARB é ruim de manter e de revisar.

## Decisão
Opção 2.
- **Fonte da verdade:** `docs/PRIVACIDADE.md`, neste repositório, versionado e revisado junto com o código que muda o que o app coleta.
- **Publicação:** um repositório público separado, sem código do app, com o texto no GitHub Pages e as Issues abertas para contato. O nome provisório é `cfrdlima/ja-vi-esse-filme-suporte`. Ele é criado antes do release (Fase 4) e recebe uma cópia do `docs/PRIVACIDADE.md` a cada mudança de versão da política.
- **No app:** a tela "Sobre" (Fase 1) mostra um resumo curto, em ARB conforme a decisão 004, e um link para a URL pública. O link abre em modo externo e com host validado. Isso exige o `url_launcher`, que precisa ser aprovado como dependência e registrado em decisão quando a tela "Sobre" for implementada.
- **Mudança no que o app coleta** (login na Fase 2, "já vi" na Fase 3, crash reporting na Fase 4): a mesma sessão atualiza o `docs/PRIVACIDADE.md`, inclusive a data de vigência.

## Consequências
- Até o repositório público existir, a política não tem URL pública, e o contato pelas Issues não funciona para quem está de fora. A política informa o canal e a URL definitivos, e a Fase 4 cria o repositório antes de publicar.
- Há o risco de as duas cópias divergirem. Por isso o checklist de release (Fase 4) compara o `docs/PRIVACIDADE.md` com a versão publicada.
- O host da URL pública (`cfrdlima.github.io`) entra na lista de hosts permitidos para links externos, criada junto com o `url_launcher`. Essa lista não é o `AppConfig.allowedHosts`, que valida só a base URL da API.

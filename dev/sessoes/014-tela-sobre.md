# Sessão 014 — Fase 1: Tela "Sobre"

**Data**: 2026-10-24 · **Branch**: `feature/014-tela-sobre` · **Status**: aberta

## Objetivo
A aba Perfil ganha uma entrada "Sobre" que empilha a tela em `/perfil/sobre`, com a atribuição obrigatória ao TMDB (logo e aviso de não endosso), um resumo da política de privacidade com link para o GitHub Pages e as licenças das fontes no `LicenseRegistry`. Antes do link, a política é publicada no repositório público `cfrdlima/ja-vi-esse-filme-suporte`, seguindo o procedimento da decisão 006 e só com a confirmação do usuário.

## Checklist
- [x] Investigar: termos e guia de atribuição do TMDB (logo aprovado, texto exato do aviso, formato do arquivo) antes de modelar. Sem `flutter_svg`, o logo entra como PNG em `assets/`
- [ ] Design: consultar a `ui-ux-pro-max` (stack Flutter) sobre a tela "Sobre" e criar `pages/sobre.md`
- [ ] Repositório público: preparar a cópia limpa do `docs/PRIVACIDADE.md` (sem comentários HTML nem "A REVISAR", seção 3.3 fora, vigência com data), rodar o `gitleaks` e só criar o repo, dar push e ligar o Pages depois do ok do usuário
- [ ] `docs/PRIVACIDADE.md`: link das Issues e URL do Pages no lugar do marcador da decisão 006, versão e vigência
- [ ] `ExternalLinkPolicy`: aceitar `cfrdlima.github.io` só com o prefixo de path `/ja-vi-esse-filme-suporte/`, sem abrir qualquer caminho dos outros hosts — RED / GREEN / REFACTOR
- [ ] URL da política como constante num lugar só, aprovada pela política de link — RED / GREEN
- [ ] Licenças das fontes (Inter e Playfair Display, OFL) no `LicenseRegistry`, registradas no `main.dart` a partir dos `.txt` dos assets — RED / GREEN
- [ ] Rota `/perfil/sobre` empilhada (`MaterialPage` explícita, como os detalhes) e entrada "Sobre" no Perfil, alvo ≥ 48dp — RED / GREEN
- [ ] Tela "Sobre": nome e versão do app, logo do TMDB com `Semantics`, aviso de não endosso — RED / GREEN
- [ ] Tela "Sobre": resumo da política e link que chama o abridor com a URL do Pages; falha ao abrir mostra aviso, sem exceção — RED / GREEN
- [ ] Tela "Sobre": "Licenças" abre o `showLicensePage` e lista as fontes — RED / GREEN
- [ ] Versão do app: decidir a fonte (`package_info_plus` é dependência nova; alternativa é `--dart-define`), perguntar antes e registrar com `/decisao` se entrar
- [ ] Strings novas em ARB (decisão 004)
- [ ] Tríade: `flutter analyze` limpo, `flutter test` verde e emulador (abrir a política, voltar ao app, licenças, fonte grande)
- [ ] `/revisar`: `code-reviewer` e `security-auditor` (a sessão mexe na política de links externos e publica conteúdo)

## Decisões

## Commits

## Notas
- **Atribuição do TMDB (investigação):**
  - os termos de uso (§3) pedem o logo do TMDB, menos destacado que a marca do app, e deixam claro que o logo não implica endosso;
  - o aviso obrigatório é "This [application] uses TMDB and the TMDB APIs but is not endorsed, certified, or otherwise approved by TMDB." O FAQ traz uma versão curta ("This product uses the TMDB API but is not endorsed or certified by TMDB") e diz que a atribuição fica numa seção "About" ou "Credits";
  - os termos não falam de tradução do aviso;
  - o logo não pode mudar de cor nem de proporção, nem ser espelhado ou girado. A página de logos só oferece SVG (primary full, short e long, e duas alternativas);
  - sem `flutter_svg`, o logo "alt short" (273,42 × 35,52) vira PNG com o `librsvg` (via ImageMagick), em 1x, 2x e 3x, com fundo transparente e a mesma proporção. Os SVGs baixados não têm script nem referência externa.

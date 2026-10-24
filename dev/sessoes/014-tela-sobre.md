# Sessão 014 — Fase 1: Tela "Sobre"

**Data**: 2026-10-24 · **Branch**: `feature/014-tela-sobre` · **Status**: aberta

## Objetivo
A aba Perfil ganha uma entrada "Sobre" que empilha a tela em `/perfil/sobre`, com a atribuição obrigatória ao TMDB (logo e aviso de não endosso), um resumo da política de privacidade com link para o GitHub Pages e as licenças das fontes no `LicenseRegistry`. Antes do link, a política é publicada no repositório público `cfrdlima/ja-vi-esse-filme-suporte`, seguindo o procedimento da decisão 006 e só com a confirmação do usuário.

## Checklist
- [x] Investigar: termos e guia de atribuição do TMDB (logo aprovado, texto exato do aviso, formato do arquivo) antes de modelar. Sem `flutter_svg`, o logo entra como PNG em `assets/`
- [x] Design: consultar a `ui-ux-pro-max` (stack Flutter) sobre a tela "Sobre" e criar `pages/sobre.md`
- [x] Repositório público: preparar a cópia limpa do `docs/PRIVACIDADE.md` (sem comentários HTML nem "A REVISAR", seção 3.3 fora, vigência com data), rodar o `gitleaks` e só criar o repo, dar push e ligar o Pages depois do ok do usuário
- [x] `docs/PRIVACIDADE.md`: link das Issues e URL do Pages no lugar do marcador da decisão 006, versão e vigência
- [x] `ExternalLinkPolicy`: aceitar `cfrdlima.github.io` só com o prefixo de path `/ja-vi-esse-filme-suporte/`, sem abrir qualquer caminho dos outros hosts — RED / GREEN / REFACTOR
- [x] URL da política como constante num lugar só, aprovada pela política de link — RED / GREEN
- [x] Licenças das fontes (Inter e Playfair Display, OFL) no `LicenseRegistry`, registradas no `main.dart` a partir dos `.txt` dos assets — RED / GREEN
- [x] Rota `/perfil/sobre` empilhada (`MaterialPage` explícita, como os detalhes) e entrada "Sobre" no Perfil, alvo ≥ 48dp — RED / GREEN
- [x] Tela "Sobre": nome e versão do app, logo do TMDB com `Semantics`, aviso de não endosso — RED / GREEN
- [x] Tela "Sobre": resumo da política e link que chama o abridor com a URL do Pages; falha ao abrir mostra aviso, sem exceção — RED / GREEN
- [x] Tela "Sobre": "Licenças" abre o `showLicensePage` e lista as fontes — RED / GREEN
- [x] Versão do app: decidir a fonte (`package_info_plus` é dependência nova; alternativa é `--dart-define`), perguntar antes e registrar com `/decisao` se entrar
- [x] Strings novas em ARB (decisão 004)
- [x] Tríade: `flutter analyze` limpo, `flutter test` verde e emulador (abrir a política, voltar ao app, licenças, fonte grande)
- [ ] `/revisar`: `code-reviewer` e `security-auditor` (a sessão mexe na política de links externos e publica conteúdo)

## Decisões

## Commits

## Notas
- **Atribuição do TMDB (investigação):**
  - os termos de uso (§3) pedem o logo do TMDB, menos destacado que a marca do app, e deixam claro que o logo não implica endosso;
  - o aviso obrigatório é "This [application] uses TMDB and the TMDB APIs but is not endorsed, certified, or otherwise approved by TMDB." O FAQ traz uma versão curta ("This product uses the TMDB API but is not endorsed or certified by TMDB") e diz que a atribuição fica numa seção "About" ou "Credits";
  - os termos não falam de tradução do aviso. Decidido com o usuário: a tela mostra a tradução em PT-BR como texto principal e, logo abaixo, o texto exato dos termos em inglês, que não vai para tradução no ARB;
  - o logo não pode mudar de cor nem de proporção, nem ser espelhado ou girado. A página de logos só oferece SVG (primary full, short e long, e duas alternativas);
  - sem `flutter_svg`, o logo "alt short" (273,42 × 35,52) vira PNG com o `librsvg` (via ImageMagick), em 1x, 2x e 3x, com fundo transparente e a mesma proporção. Os SVGs baixados não têm script nem referência externa.
- **Design:** consultei a `ui-ux-pro-max`:
  - `ux` "Back Button", "Alt Text", `back-behavior` e `nav-hierarchy`;
  - pro-rules "Correct Brand Logos", "Touch Target Minimum", "Tap feedback" e "Semantic native controls";
  - `icons` "arrow-square-out";
  - stack Flutter "Use Semantics widget" e "Use Navigator 2.0 or GoRouter";
  - as buscas por tela de configurações e por indicador de link externo no `ux` só trouxeram resultados de web, e esse trecho ficou como padrão geral.

  O override `pages/sobre.md` registra a exceção ao "Vector-Only Assets" (logo em PNG a partir do SVG oficial) e põe o aviso original em inglês com `locale` `en` no `Semantics`.
- **Política 1.0** (decidido com o usuário):
  - a versão publicada descreve só o app atual, sem login. O texto do login (3.2, linha do `session_id`, partes das seções 6 a 9 e 11) ficou no `docs/PRIVACIDADE.md`, em comentários `FASE 2 (fora da publicada)`, e volta com a versão do app que tiver login;
  - o nome do controlador continua na seção 1;
  - versão 1.0, com vigência a partir de 24/10/2026;
  - a seção 5 saiu de "site de um filme" (o app não abre esse link) e passou a citar a própria política;
  - **base legal:** o art. 33, IX só cobre as bases dos incisos II, V e VI do art. 7º. Sem login, a busca estava só em legítimo interesse (inciso IX), o que deixava a transferência internacional sem apoio. A busca passou para o art. 7º, V, e a seção 6 cita o "art. 33, IX, combinado com o art. 7º, V". Não houve revisão jurídica: vale levar ao checklist de release.
- **Publicação (decisão 006),** com o ok do usuário:
  - a cópia foi gerada do `docs/PRIVACIDADE.md` tirando os comentários HTML, numa pasta nova do scratchpad, com `git init` próprio e um commit só (`index.md`, `README.md` e `_config.yml` com `lang: pt-BR`);
  - o `gitleaks detect` rodou na pasta e no histórico, sem vazamentos;
  - `gh repo create cfrdlima/ja-vi-esse-filme-suporte --public --disable-wiki`, com push da `main`, e o Pages ligado na `main`, na raiz;
  - o repo é público, não é fork, tem Issues ligadas, wiki desligada, nenhum secret e nenhum workflow.
  - a página saiu no ar em `https://cfrdlima.github.io/ja-vi-esse-filme-suporte/` (HTTP 200, `lang="pt-BR"`), sem "A REVISAR" nem `session_id` no HTML.
- **Host novo na política de links** (decisão 009 pede o porquê): o `cfrdlima.github.io` entra para abrir a política publicada (decisão 006). A política passou a guardar um prefixo de caminho por host: `/ja-vi-esse-filme-suporte/` no Pages, porque cada repositório da conta é um site no mesmo host, e `/` no YouTube, sem mudança. O `Uri` do Dart resolve `..` e `%2E%2E` antes da comparação (conferido num script). Com a checagem do prefixo removida, 5 testes reprovam.
- **Licenças das fontes:** `registerFontLicenses()` (`core/licenses/`) põe a OFL da Inter e da Playfair Display no `LicenseRegistry`, lendo os `.txt` declarados como assets no `pubspec.yaml`. O `main()` chama a função logo depois dos handlers de erro, e essa ligação não tem teste (BACKLOG, `bootstrap()` testável).
- **Rota do Sobre:**
  - o Perfil deixou de ser placeholder e virou a `ProfileScreen` (`features/profile/`), com a entrada "Sobre o app" (`ListTile`, `context.go(AppRoutes.about)`);
  - a `AboutScreen` (`features/about/`) entrou só com a `AppBar` "Sobre", e o conteúdo vem nos próximos itens;
  - `/perfil/sobre` usa `MaterialPage` explícita, como os detalhes. Trocar por `builder` reprova o teste de animação;
  - o `ListTile` expõe `hasSelectedState` na semântica, e o teste aceita isso.
- **Versão do app:** decidida com o usuário, por `--dart-define=APP_VERSION`, sem dependência nova. O Flutter não passa a versão do `pubspec.yaml` como define sozinho (conferido no `flutter_tools`). O comando de run e build do `CLAUDE.md` e do README tira a versão do próprio `pubspec.yaml` com `sed`. Assim não há uma segunda cópia do número, e o `env/*.json` fica como está. O `AppConfig.appVersion` é o único leitor. Sem o define (testes, ou um `flutter run` sem ele), a linha da versão some.
- **Cabeçalho do Sobre:**
  - nome do app em `headlineSmall` e versão em `bodyMedium`;
  - seção "Dados e imagens" com o logo (120dp, `Semantics` de imagem "Logo do TMDB");
  - aviso em PT-BR (ARB) e o original dos termos fora do ARB (`TmdbAttribution.noticeOriginal`), com `LocaleStringAttribute` `en` para o leitor de tela.
- **Logo:** PNGs de 120×16, 240×32 e 360×47 em `assets/images/` (1x, 2.0x e 3.0x), 8 bits, sem metadados. O arredondamento para pixel inteiro muda a proporção em até 2,5% no 1x (7,5:1 contra 7,7:1 do SVG). A tela desenha com largura 120 e altura pela proporção do arquivo da densidade.
- **Refactor:** o `_SectionTitle` dos detalhes virou `SectionTitle` em `core/widgets/`, usado também pelo Sobre.
- **Privacidade no Sobre:**
  - a `PrivacySection` vem depois da atribuição ao TMDB e traz o resumo da política 1.0 (sem login, sem servidor, só o cache de pôsteres, sem anúncios nem analytics) e o link "Política de privacidade" para o `AppLinks.privacyPolicy`;
  - a falha ao abrir vira `SnackBar`;
  - a entrelinha do resumo vem do `textTheme`, sem `height` no widget.
- **Refactor:** o tile de trailer e o link da política repetiam o mesmo padrão: um nó de link com o toque no `Semantics`, um `ListTile`, o `open` e o `SnackBar` na falha. Os dois viraram `ExternalLinkTile` em `core/widgets/`, com testes próprios.
- **Licenças no Sobre:**
  - a `LicensesSection` fecha a tela, com o `ListTile` "Licenças de código aberto" que abre o `showLicensePage` com o nome do app e a versão do build (sem versão quando ela vem vazia);
  - o teste confere a Inter e a Playfair Display na lista, e precisa de `runAsync`, porque a página lê o registro fora do quadro;
  - a página fica sem `applicationIcon`, porque o ícone do app só chega na Fase 4.
- **Emulador (Medium Phone API 36, `flutter run` com o `APP_VERSION`):**
  - o Perfil mostra a entrada "Sobre o app", e o toque empilha o Sobre com a barra das abas visível;
  - o Sobre aparece conforme o `pages/sobre.md`: "Versão 0.1.0", o logo do TMDB com 120dp e menor que o nome do app, o aviso em PT-BR com o original em inglês abaixo, a privacidade e as licenças;
  - "Política de privacidade" abre o Chrome em `cfrdlima.github.io/ja-vi-esse-filme-suporte/`, com a política 1.0 renderizada. O Chrome do emulador estava no primeiro uso e pediu conta e notificações, que dispensei. O voltar devolve o app no Sobre;
  - "Licenças de código aberto" mostra "Já Vi Esse Filme 0.1.0", e a lista tem "Inter" e "Playfair Display", com 1 licença cada (achadas no `uiautomator`);
  - com `font_scale` 2.0, o Sobre e o Perfil quebram linha sem overflow, e o logo mantém 120dp. A escala voltou a 1.0 no fim;
  - o log do `flutter run` não tem exceção nem overflow.
- **Tríade antes do `/revisar`:** `dart format` sem mudanças, `flutter analyze` sem issues, 730 testes passando e `gitleaks` sem vazamentos.

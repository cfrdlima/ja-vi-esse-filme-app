# Sessão 007 — Antes da Fase 1: política de privacidade

**Data**: 2026-10-23 · **Branch**: `feature/007-politica-de-privacidade` · **Status**: fechada

## Objetivo
Levantar os dados que o app trata hoje e vai tratar nas Fases 2 a 4, decidir onde a política de privacidade fica e como a tela "Sobre" vai mostrá-la. Depois, escrever a política em PT-BR seguindo a LGPD, com contato pelas Issues do GitHub.

## Checklist
- [x] Inventário de dados: o token v4 (do app, não é dado pessoal), o `session_id`, o account id e o nome de usuário (Fase 2), favoritos, watchlist e listas (guardados no TMDB), "já vi" com nota e data (Fase 3, armazenamento ainda a decidir), flags no `shared_preferences`, crash reporting (Fase 4) e o termo de busca (enviado ao TMDB, não guardado no aparelho)
- [x] Conferir na web os termos de uso da API e a política de privacidade do TMDB (o terceiro que recebe os dados)
- [x] `/decisao`: onde a política fica (URL pública exigida pela Play Store) e como a tela "Sobre" a mostra (link externo ou texto no app)
- [x] Redigir a política: controlador, dados e finalidade, base legal, compartilhamento com o TMDB, retenção, direitos do titular (LGPD, art. 18), contato pelas Issues do GitHub e data de vigência. Os pontos que dependem de decisão futura ficam marcados para revisão
- [x] Atualizar o `dev/checklist-prontidao.md` (item Privacidade/LGPD). Os itens do PLANO que dependem da política ficam para o `/fechar-sessao` (ver Notas)
- [x] Tríade: `flutter analyze` e `flutter test` seguem como estavam (a sessão não tem código novo, então o TDD não se aplica)
- [x] `/revisar`: `code-reviewer` no texto e, se a política descrever o armazenamento da sessão, o `security-auditor` para conferir que ela bate com a decisão 001
- [x] Revisão R1–R12 e S1–S6 (texto): canal privado por e-mail, controlador identificado, marcador do proxy, links externos, logout e desinstalação, afirmações absolutas, cache de imagens, base legal e art. 33/18/19, retenção do id/nome, procedimento do repositório público, destino do link da "Sobre", faixa etária 13+
- [x] S7 e pendências de Fase levadas ao PLANO no `/fechar-sessao`

## Decisões
- [006 — Política de privacidade: fonte no repositório, publicação em repositório público separado](../decisoes/006-politica-de-privacidade-publica.md)

## Commits
- `bfa491f` docs: abre sessão 007 e registra a decisão 006
- `3e02d13` docs: política de privacidade (rascunho 0.1)
- `7e7622d` docs: tratamento da revisão da sessão 007 (política 0.2)

## Notas
- Inventário de dados (código em 2026-10-23):
  - **Hoje o app não guarda nada no aparelho.** Não há uso de `shared_preferences`, `flutter_secure_storage` nem `url_launcher` em `lib/`. O manifest pede só `INTERNET` e tem `allowBackup="false"`.
  - **Rede:** só o TMDB. A API em `api.themoviedb.org` usa o token v4 do app (credencial do app, não do usuário), e as imagens vêm de `image.tmdb.org`. As fontes são empacotadas e não há chamada ao Google Fonts. O TMDB recebe o IP, o termo de busca e os filmes abertos.
  - **Erros:** o `debugPrint` vai para o logcat local, com o texto passado pelo `redactSecrets`. Não há envio para servidor.
  - **Fase 2:** o `session_id` fica no `flutter_secure_storage` (decisão 001) e o account id e o nome de usuário vêm de `/account` (onde ficam guardados ainda vai ser decidido na Fase 2). Favoritos, watchlist e listas são guardados na conta do usuário no TMDB, não pelo app. O login acontece no site do TMDB, no navegador, e o app nunca vê a senha.
  - **Fase 3:** "já vi", nota pessoal e data. O armazenamento ainda vai ser decidido (local ou listas/avaliações do TMDB). Fica marcado como "a revisar" na política.
  - **Fase 4:** crash reporting (Crashlytics ou Sentry) seria um terceiro novo, com dados do aparelho. Também fica como "a revisar".
  - Não há analytics, anúncios, localização, câmera nem contatos.
- TMDB (conferido na web em 2026-10-23):
  - Termos da API:
    - logo e aviso de que o app "uses TMDB and the TMDB APIs but is not endorsed, certified, or otherwise approved by TMDB";
    - **cache de dados do TMDB por no máximo 6 meses**, o que importa para o "modo offline" do BACKLOG e para a Fase 3;
    - uso pago exige contrato;
    - os termos não pedem nada específico sobre a política de privacidade do app.
  - Política de privacidade do TMDB:
    - vigente desde 2026-08-24;
    - o TMDB coleta o IP e dados de uso da API;
    - processa os dados em vários países, inclusive os EUA, o que é transferência internacional no sentido da LGPD;
    - contato: privacyrequest@xperi.com.
  - Links: https://www.themoviedb.org/api-terms-of-use · https://www.themoviedb.org/privacy-policy
- **Bloqueio:** o repositório `cfrdlima/ja-vi-esse-filme-app` é **privado** e não tem GitHub Pages. O público não consegue abrir Issues nem acessar uma URL de política hospedada aqui.
- Decisão 006, a opção escolhida pelo usuário: a fonte do texto fica em `docs/PRIVACIDADE.md`, e a publicação vai para um repositório público separado, com GitHub Pages e Issues. O nome provisório é `cfrdlima/ja-vi-esse-filme-suporte`, e o repositório é criado na Fase 4. A tela "Sobre" mostra um resumo em ARB e um link externo. Isso exige o `url_launcher`, que precisa ser aprovado quando a tela for feita.
- Política: `docs/PRIVACIDADE.md`, versão 0.1 (rascunho). Ela cobre o uso sem login, o login TMDB, os erros, a base legal (art. 7º, V), a transferência internacional (art. 33), a retenção, os direitos (art. 18), a segurança, o contato e as crianças. Os comentários `A REVISAR` ficam em três pontos:
  - o armazenamento do "já vi" (Fase 3);
  - o crash reporting (Fase 4);
  - o link do repositório de suporte (Fase 4).
- Os itens do `checklist-prontidao.md` são uma auditoria (não se marcam). O item Privacidade/LGPD só passou a apontar para `docs/PRIVACIDADE.md` e a cobrar a ausência de "A REVISAR" no release.
- O `AppConfig.allowedHosts` valida só a base URL da API. O host da política vai para uma lista própria de links externos, junto com o `url_launcher`.
- Para o `/fechar-sessao` levar ao PLANO:
  - Fase 4: criar o repositório público de suporte e publicar a política;
  - Fases 2, 3 e 4: atualizar o `docs/PRIVACIDADE.md` junto com o login, o "já vi" e o crash reporting.
- Tríade (sem código novo): `flutter analyze` sem issues, `flutter test` com 239 testes passando e `gitleaks` sem vazamentos.
- Revisão (`code-reviewer` e `security-auditor`): nada bloqueante, e o `security-auditor` aprovou fechar. Foram aceitos R1 a R12 e S1 a S6, que são de texto, nesta sessão. S7 vai para o PLANO.
- Respostas do usuário para a revisão:
  - canal privado: `xbtechnologies.app@gmail.com`;
  - controlador: Claudinei de Lima;
  - público: 13+;
  - base legal: a escolha ficou comigo.
- Base legal:
  - **Legítimo interesse** (art. 7º, IX) para o uso sem login e os logs locais. O app não tem termos de uso próprios, então o inciso V seria frágil nesse caso. O dado é mínimo (IP e busca, enviados direto ao TMDB) e o uso é o que se espera de um app de filmes.
  - **Execução de contrato** (art. 7º, V) para o login. O contrato é o da conta TMDB, do qual o titular é parte, e o pedido parte do titular.
  - **Transferência internacional:** art. 33, IX. "Revogar consentimento" saiu da política, porque nenhuma base usada é consentimento.
- Política 0.2:
  - controlador identificado, com a Resolução CD/ANPD nº 2/2022 para a ausência de encarregado;
  - dois canais de contato: o e-mail para pedidos e as Issues para dúvidas, com o aviso de não pôr dado pessoal;
  - seção nova "Links externos" (YouTube, site do filme e GitHub);
  - o logout pede o encerramento da sessão ao TMDB, e desinstalar não o encerra;
  - frases absolutas trocadas: "construído para não registrar", "mascarando" e "cifrado, com chave no Keystore";
  - o Android vitals passa a constar em 3.4;
  - lista completa do art. 18, mais a oposição, e o prazo de 15 dias do art. 19;
  - a seção 3.3 passou a ser só o marcador;
  - a afirmação sobre permissões aparece só na seção 9;
  - vigência com data explícita na publicação.
  - Os marcadores `A REVISAR` passaram de 3 para 7: proxy, cache de imagens, retenção do id e do nome, "já vi", crash reporting, `data_extraction_rules` e o link do repositório de suporte.
- Decisão 006:
  - o e-mail entra como canal privado;
  - o repositório de suporte passa a ser criado na sessão da tela "Sobre" (Fase 1), e não mais na Fase 4, para que o link já tenha destino;
  - o app linka só para o Pages, que tem um único host;
  - procedimento de publicação que não vaza o repositório privado;
  - regras de validação do link;
  - risco de alguém tomar o subdomínio `github.io` se a conta for renomeada.
- Para o `/fechar-sessao` levar ao PLANO, além do que já estava acima:
  - Fase 1: na tela "Sobre", criar o repositório de suporte, publicar a política e declarar o cache de imagens; `include_adult=false` nas buscas (público 13+);
  - Fase 2: `data_extraction_rules`, logout que apaga o storage mesmo se o `DELETE` falhar, login no navegador externo ou em Custom Tabs (nunca em WebView) com origem do deep link validada, e decidir a retenção do id e do nome;
  - Fase 4: conferir as permissões do manifest mesclado com plugins novos e comparar a política publicada com o `docs/PRIVACIDADE.md`.
- Fechamento:
  - `dart format` sem mudanças, `flutter analyze` sem issues, `flutter test` com 239 testes passando e `gitleaks` sem vazamentos;
  - `/revisar` rodou com o `code-reviewer` e o `security-auditor`.
  - As pendências de Fase foram para o PLANO, e o limite de cache de 6 meses do TMDB foi para o item "modo offline" do BACKLOG.
- **Pendências:**
  - A política fica em rascunho até os 7 marcadores `A REVISAR` serem resolvidos, cada um na sua fase.
  - O texto não teve revisão jurídica.

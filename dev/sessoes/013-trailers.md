# Sessão 013 — Fase 1: Trailers

**Data**: 2026-10-23 · **Branch**: `feature/013-trailers` · **Status**: aberta

## Objetivo
Os detalhes do filme passam a mostrar os trailers que o TMDB tem, e tocar num deles abre o YouTube fora do app (`url_launcher` em modo externo). A URL é montada pelo app a partir da `key` do vídeo e passa por uma validação de host antes de abrir. Sem trailer, a seção some.

## Checklist
- [x] Investigar: o `language=pt-BR` filtra os `videos` do `append_to_response`? Conferir na documentação do TMDB (Context7/web) o `include_video_language` e os campos de `videos.results` (`key`, `site`, `type`, `official`, `iso_639_1`, `name`) antes de modelar
- [x] Dependência: conferir a versão atual do `url_launcher`, o minSdk (decisão 003) e o que ele pede no manifest (`<queries>` de `VIEW` com `https`), e registrar a decisão 009 com `/decisao`
- [x] Design: consultar a `ui-ux-pro-max` (stack Flutter) sobre a seção de trailers e o link externo, e criar a seção "Trailers" em `pages/detalhes.md`
- [x] Fixture: detalhes com `videos` (trailer e teaser do YouTube, vídeo do Vimeo, `key` inválida, campos `null`)
- [x] Datasource pede `videos` no mesmo `append_to_response` (com o `include_video_language`, se a investigação pedir) — RED / GREEN
- [x] Model: só vídeos do YouTube, do tipo trailer ou teaser, com `key` no formato do YouTube; o resto é descartado sem quebrar o parse — RED / GREEN
- [x] Entidade `Trailer` no domain e `MovieDetails.trailers`, na ordem: oficial e pt-BR primeiro, trailer antes de teaser, com teto — RED / GREEN / REFACTOR
- [x] `core`: validador de link externo com lista própria de hosts (não o `AppConfig.allowedHosts`): `https`, host por igualdade, sem `userInfo`, e URL montada pelo app a partir da `key` — RED / GREEN
- [x] `core`: abridor de link externo sobre o `url_launcher` (`LaunchMode.externalApplication`), atrás de uma interface injetada no `main.dart`, com falha tipada quando não abre — RED / GREEN
- [x] Seção "Trailers" nos detalhes: lista com nome e tipo, alvo ≥ 48dp, `Semantics` de link ("<nome>, <tipo>. Abre no YouTube") — RED / GREEN
- [x] Tocar num trailer chama o abridor com a URL validada — RED / GREEN
- [x] Falha ao abrir (sem app nem navegador) mostra aviso ao usuário, sem exceção — RED / GREEN
- [x] Sem trailers, a seção some — RED / GREEN
- [x] Strings novas em ARB (decisão 004)
- [x] Manifest: avaliar o `<queries>` de `VIEW` `https` (ficou de fora, decisão 009) e conferir se a seção de permissões do `docs/PRIVACIDADE.md` muda (não muda)
- [x] Tríade: `flutter analyze` limpo, `flutter test` verde e emulador (filme com e sem trailer, abrir o YouTube, voltar ao app, fonte grande)
- [x] `/revisar`: `code-reviewer` e `security-auditor` (a sessão abre URL externa e adiciona dependência)
- [ ] I1: `MovieDetails` tira trailers com `key` repetida antes do corte, mantendo o mais relevante — RED / GREEN
- [ ] I2: teste de estabilidade da ordem com mais de 32 trailers equivalentes (o `sort` do Dart já é estável abaixo disso) — RED
- [ ] I3: teste do corte com o único oficial na 7ª posição, saindo em primeiro
- [ ] I4: o toque do leitor de tela (`SemanticsAction.tap`) abre o trailer — RED / GREEN
- [ ] S2: trailer sem nome lido como "Teaser. Abre no YouTube", sem repetir o tipo — RED / GREEN
- [ ] S3: um só `open` local para o `onTap` do `ListTile` e do `Semantics` — REFACTOR
- [ ] S4: qualquer erro do `launchUrl` vira `LinkNotOpened(noApp)`, não só `PlatformException` — RED / GREEN
- [ ] S8: entre os vídeos em português, os do Brasil (`iso_3166_1 == BR`) vêm antes — RED / GREEN
- [ ] A2: casos de regressão na política: ponto no fim do host, homógrafo cirílico, `www.youtube.com%2F@evil.com`, `evil.com\@www.youtube.com`
- [ ] BACKLOG: S1, S9, A1, A3

## Decisões
- [009 — `url_launcher` e links externos](../decisoes/009-url-launcher-e-links-externos.md)

## Commits
- be5611f add: main injeta o abridor de links do url_launcher
- 97045f7 add: seção de trailers nos detalhes, depois do elenco
- 721037a add: lista de trailers que abre o YouTube e avisa quando não abre
- 4669414 add: abridor de link externo sobre o url_launcher, com falha tipada
- 268d43f add: política de link externo com lista própria de hosts
- 774a8fc add: model lê os trailers do YouTube e descarta o resto
- 8b8b698 add: trailers do YouTube nos detalhes, com key validada e ordem de relevância
- c16a6b5 add: detalhes pedem os vídeos em português e inglês
- 68a4819 docs: seção de trailers no design dos detalhes
- e65d280 chore: adiciona url_launcher (decisão 009)
- d082408 docs: decisão 009, url_launcher e links externos
- 2be1934 docs: abre sessão 013

## Notas
- **Investigação do TMDB:**
  - a referência oficial de `/movie/{id}/videos` lista só o `language` como parâmetro;
  - o `include_video_language` foi anunciado pela equipe do TMDB no fórum ("All of the `/videos` endpoints now support a `include_video_language` param", 2021-07-29, inclusive com `append_to_response=videos`);
  - segundo o fórum, com ele o `language` deixa de filtrar os vídeos, a lista aceita até 5 idiomas e o valor `null` não aparece documentado para vídeos;
  - ficou `include_video_language=pt,en`, em código ISO 639-1. No emulador, o filme testado trouxe vídeos nos dois idiomas.
- **Dependência:** `url_launcher` 6.3.3 (publicado em 2026-10-02). O `url_launcher_android` 6.3.33 pede minSdk 24, o mesmo do app (decisão 003). O manifest do plugin só declara uma `WebViewActivity` com `exported="false"`, que o app não usa. Não há permissão nova, então a política de privacidade não muda: a seção de links externos já cita o trailer do YouTube.
- **Sem `<queries>`:** o app não chama o `canLaunchUrl`, e o `false` ou a `PlatformException` do `launchUrl` viram `LinkNotOpened` (decisão 009).
- **Design:** consultei a `ui-ux-pro-max`:
  - `ux` "Auto-Play Video", `touch-target-size`, `press-feedback` e `icons` "arrow-square-out";
  - stack Flutter "Use keys for stateful items";
  - a busca por link externo na stack Flutter não trouxe resultado, e esse trecho ficou como padrão geral.

  A seção "Trailers" entrou em `pages/detalhes.md`. Ficou sem miniatura, porque ela viria de outro host (`img.youtube.com`).
- **Semântica:** o `ListTile` sozinho marcava o item como botão. O item virou um nó só, de link, com o rótulo "<nome>, <tipo>. Abre no YouTube" e o toque no próprio `Semantics`.
- **Injeção:** o `ExternalLinkOpener` vem por `Provider` acima do `MaterialApp`, montado no `main.dart`. A `TrailerList` lê o abridor no toque. Não criei um notifier, porque não há estado a guardar: é uma ação só, cuja falha vira `SnackBar`.
- **Emulador (Medium Phone API 36),** com "Devoradores de Estrelas":
  - a seção aparece depois do elenco com 5 trailers;
  - tocar abre o app do YouTube no vídeo certo;
  - o voltar devolve o app na mesma rolagem;
  - com fonte 2x, os nomes quebram em 2 linhas com reticências, sem overflow;
  - nenhuma exceção no log do `flutter run`.

  Não testei no aparelho um filme sem trailer nem um aparelho sem app que abra o link. Os dois estão cobertos pelos testes.
- **Observações do emulador:**
  - os dois primeiros trailers são da Sony Pictures **Portugal**. O `iso_639_1` `pt` junta pt-BR e pt-PT, e o país (`iso_3166_1`) não entra na ordem;
  - há um vão grande entre o elenco e o título "Trailers", que parece vir da altura da fileira do elenco (já existia antes da sessão).
- **Tríade antes do `/revisar`:**
  - `dart format` sem mudanças (118 arquivos);
  - `flutter analyze` sem issues;
  - `flutter test` com 662 testes passando (eram 604);
  - `gitleaks` sem vazamentos.

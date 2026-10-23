# Sessão 013 — Fase 1: Trailers

**Data**: 2026-10-23 · **Branch**: `feature/013-trailers` · **Status**: aberta

## Objetivo
Os detalhes do filme passam a mostrar os trailers que o TMDB tem, e tocar num deles abre o YouTube fora do app (`url_launcher` em modo externo). A URL é montada pelo app a partir da `key` do vídeo e passa por uma validação de host antes de abrir. Sem trailer, a seção some.

## Checklist
- [ ] Investigar: o `language=pt-BR` filtra os `videos` do `append_to_response`? Conferir na documentação do TMDB (Context7/web) o `include_video_language` e os campos de `videos.results` (`key`, `site`, `type`, `official`, `iso_639_1`, `name`) antes de modelar
- [ ] Dependência: conferir a versão atual do `url_launcher`, o minSdk (decisão 003) e o que ele pede no manifest (`<queries>` de `VIEW` com `https`), e registrar a decisão 009 com `/decisao`
- [ ] Design: consultar a `ui-ux-pro-max` (stack Flutter) sobre a seção de trailers e o link externo, e criar a seção "Trailers" em `pages/detalhes.md`
- [ ] Fixture: detalhes com `videos` (trailer e teaser do YouTube, vídeo do Vimeo, `key` inválida, campos `null`)
- [ ] Datasource pede `videos` no mesmo `append_to_response` (com o `include_video_language`, se a investigação pedir) — RED / GREEN
- [ ] Model: só vídeos do YouTube, do tipo trailer ou teaser, com `key` no formato do YouTube; o resto é descartado sem quebrar o parse — RED / GREEN
- [ ] Entidade `Trailer` no domain e `MovieDetails.trailers`, na ordem: oficial e pt-BR primeiro, trailer antes de teaser, com teto — RED / GREEN / REFACTOR
- [ ] `core`: validador de link externo com lista própria de hosts (não o `AppConfig.allowedHosts`): `https`, host por igualdade, sem `userInfo`, e URL montada pelo app a partir da `key` — RED / GREEN
- [ ] `core`: abridor de link externo sobre o `url_launcher` (`LaunchMode.externalApplication`), atrás de uma interface injetada no `main.dart`, com falha tipada quando não abre — RED / GREEN
- [ ] Seção "Trailers" nos detalhes: lista com nome e tipo, alvo ≥ 48dp, `Semantics` de link ("Abrir trailer <nome> no YouTube") — RED / GREEN
- [ ] Tocar num trailer chama o abridor com a URL validada — RED / GREEN
- [ ] Falha ao abrir (sem app nem navegador) mostra aviso ao usuário, sem exceção — RED / GREEN
- [ ] Sem trailers, a seção some — RED / GREEN
- [ ] Strings novas em ARB (decisão 004)
- [ ] Manifest: `<queries>` de `VIEW` `https`, e conferir se a seção de permissões do `docs/PRIVACIDADE.md` muda
- [ ] Tríade: `flutter analyze` limpo, `flutter test` verde e emulador (filme com e sem trailer, abrir o YouTube, voltar ao app, fonte grande)
- [ ] `/revisar`: `code-reviewer` e `security-auditor` (a sessão abre URL externa e adiciona dependência)

## Decisões

## Commits

## Notas

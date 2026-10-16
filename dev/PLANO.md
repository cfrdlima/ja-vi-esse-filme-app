# Plano — Já Vi Esse Filme (Flutter)

> Fonte da verdade do que construir. Atualizado por `/fechar-sessao`.

## Última sessão
_Nenhuma ainda. Comece com `/sessao`._

## Fase 0 — Fundação
- [ ] Criar projeto (`flutter create --org <seu.dominio> ja_vi_esse_filme`), `analysis_options.yaml`, `.gitignore` com `env/*.json` (exceto `example.json`)
- [ ] `core/config` lendo `--dart-define-from-file` + `env/example.json`
- [ ] Gerar design system com `ui-ux-pro-max` (stack Flutter) → `design-system/ja-vi-esse-filme/MASTER.md`
- [ ] `core/theme` com tokens do `MASTER.md` (tema escuro, fontes empacotadas)
- [ ] `core/network`: cliente TMDB com falhas tipadas (rede, 401, 404, 429) — TDD com `MockClient`
- [ ] `go_router` com shell de navegação (Descobrir / Buscar / Minha estante / Perfil)
- [ ] CI (GitHub Actions): format, analyze, test, gitleaks
- [ ] Confirmar decisão 001 (chave TMDB e proxy)

## Fase 1 — Explorar (sem login)
- [ ] Descobrir: populares, em cartaz, melhor avaliados (paginação infinita)
- [ ] Busca com debounce e estados vazio/erro
- [ ] Detalhes do filme: sinopse, gêneros, duração, nota, elenco
- [ ] Trailers (abrir YouTube externo com host validado)
- [ ] Tela "Sobre" com atribuição ao TMDB

## Fase 2 — Conta TMDB
- [ ] Login via sessão TMDB (request_token → navegador → session_id no secure storage)
- [ ] Logout invalidando a sessão
- [ ] Favoritos (`/account/{id}/favorite`)
- [ ] Watchlist ("quero ver")

## Fase 3 — "Já vi esse filme"
- [ ] Marcar como **já visto** (definir armazenamento — ver decisão a criar)
- [ ] Nota pessoal / data em que assistiu
- [ ] Listas personalizadas (criar, renomear, adicionar/remover filme)

## Fase 4 — Polimento e release
- [ ] Acessibilidade e fonte grande
- [ ] Ícone, splash, nome do app
- [ ] Build release ofuscado e assinado

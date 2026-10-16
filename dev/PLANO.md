# Plano — Já Vi Esse Filme (Flutter)

> Fonte da verdade do que construir. Atualizado por `/fechar-sessao`.

## Última sessão
**001 — Fase 0: design system com ui-ux-pro-max e tokens em core/theme** (fechada em 2026-10-16) · [log](sessoes/001-design-system-tokens.md)
O design system "cinema escuro" (dourado sobre índigo, Playfair Display + Inter empacotadas) está no `MASTER.md` e traduzido em `lib/core/theme/`. São 124 testes, com contraste AA, e o tema está aplicado no `MaterialApp`.
**Próximo passo:** `/sessao 002 — fundação e endurecimento` com:
- manifest (`INTERNET`, `allowBackup`, cleartext explícito);
- `.gitignore` sem o bloco duplicado e com `.env*`;
- README e descrição do `pubspec`;
- `analysis_options` estrito;
- handlers globais de erro;
- falha 5xx;
- `setup-claude.sh` atualizado;
- registro do minSdk.

## Fase 0 — Fundação
- [x] Criar projeto (`io.github.cfrdlima.ja_vi_esse_filme`), `analysis_options.yaml`, `.gitignore` com `env/*.json` (exceto `example.json`)
- [ ] `analysis_options.yaml` estrito (`strict-casts`, `strict-inference`, `strict-raw-types`, `avoid_dynamic_calls`, `unawaited_futures`, `avoid_print`…)
- [ ] Manifest: permissão `INTERNET` no `main`, `android:allowBackup="false"` e `usesCleartextTraffic="false"` explícito (antes do `core/network`)
- [ ] README do projeto e descrição real no `pubspec.yaml`
- [ ] `.gitignore`: remover o bloco duplicado e acrescentar `.env*`
- [ ] `setup-claude.sh` atualizado (citar a skill `ui-ux-pro-max`)
- [ ] Registrar a justificativa do minSdk 24 (decisão curta ou `CLAUDE.md`)
- [ ] Handlers globais de erro no `main.dart` (`FlutterError.onError` e `PlatformDispatcher.instance.onError`)
- [ ] `core/config` lendo `--dart-define-from-file` + `env/example.json`
- [x] Gerar design system com `ui-ux-pro-max` (stack Flutter) → `design-system/ja-vi-esse-filme/MASTER.md`
- [x] `core/theme` com tokens do `MASTER.md` (tema escuro, fontes empacotadas)
- [ ] `core/network`: cliente TMDB com falhas tipadas (rede, 401, 404, 429, 5xx) — TDD com `MockClient`
- [ ] `go_router` com shell de navegação (Descobrir / Buscar / Minha estante / Perfil)
- [ ] CI (GitHub Actions): format, analyze, test, gitleaks, com a versão do Flutter fixada (3.44.5)
- [ ] Confirmar decisão 001 (chave TMDB e proxy)

## Antes da Fase 1
- [ ] Decisão: strings de UI centralizadas (`flutter_localizations` + ARB) ou em constantes
- [ ] Decisão: `intl` para datas e números em pt-BR (dependência nova)
- [ ] Política de privacidade (o que o app coleta, LGPD), para a tela "Sobre"

## Fase 1 — Explorar (sem login)
- [ ] Descobrir: populares, em cartaz, melhor avaliados (paginação infinita)
- [ ] Busca com debounce e estados vazio/erro
- [ ] Detalhes do filme: sinopse, gêneros, duração, nota, elenco
- [ ] Hero do pôster entre a grade/lista e os detalhes
- [ ] Trailers (abrir YouTube externo com host validado)
- [ ] Tela "Sobre" com atribuição ao TMDB, política de privacidade e licenças das fontes (`LicenseRegistry`)

## Fase 2 — Conta TMDB
- [ ] Login via sessão TMDB (request_token → navegador → session_id no secure storage), validando a origem do retorno do deep link
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
- [ ] Crash reporting (Crashlytics ou Sentry — exige decisão de dependência)
- [ ] Build release ofuscado e assinado

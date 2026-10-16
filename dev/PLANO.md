# Plano — Já Vi Esse Filme (Flutter)

> Fonte da verdade do que construir. Atualizado por `/fechar-sessao`.

## Última sessão
**002 — Fase 0: fundação e endurecimento** (fechada em 2026-10-16) · [log](sessoes/002-fundacao-endurecimento.md)
O manifest ganhou `INTERNET`, perdeu o backup, proíbe cleartext e mostra o nome do app, tudo com teste. Também entraram lints estritos, handlers globais de erro com reporter injetável, `.gitignore` limpo, README e a decisão 003 (minSdk 24). São 134 testes.
**Próximo passo:** `/sessao 003 — core/config e core/network`.
- Confirmar a decisão 001 com o token v4 de leitura no header `Authorization: Bearer`.
- `core/config` lendo `--dart-define-from-file`.
- `TmdbClient` com falhas tipadas e o redator de segredos no log.

## Fase 0 — Fundação
- [x] Criar projeto (`io.github.cfrdlima.ja_vi_esse_filme`), `analysis_options.yaml`, `.gitignore` com `env/*.json` (exceto `example.json`)
- [x] `analysis_options.yaml` estrito (`strict-casts`, `strict-inference`, `strict-raw-types`, `avoid_dynamic_calls`, `unawaited_futures`, `avoid_print`…)
- [x] Manifest: permissão `INTERNET` no `main`, `android:allowBackup="false"` e `usesCleartextTraffic="false"` explícito (antes do `core/network`)
- [x] README do projeto e descrição real no `pubspec.yaml`
- [x] `.gitignore`: remover o bloco duplicado e acrescentar `.env*`
- [x] `setup-claude.sh` atualizado (citar a skill `ui-ux-pro-max`)
- [x] Registrar a justificativa do minSdk 24 (decisão curta ou `CLAUDE.md`)
- [x] Handlers globais de erro no `main.dart` (`FlutterError.onError` e `PlatformDispatcher.instance.onError`)
- [ ] `core/config` lendo `--dart-define-from-file` + `env/example.json` (token v4 de leitura; atualizar o README junto)
- [x] Gerar design system com `ui-ux-pro-max` (stack Flutter) → `design-system/ja-vi-esse-filme/MASTER.md`
- [x] `core/theme` com tokens do `MASTER.md` (tema escuro, fontes empacotadas)
- [ ] `core/network`: cliente TMDB com falhas tipadas (rede, 401, 404, 429, 5xx) — TDD com `MockClient`
- [ ] `core/network`: autenticar com o token v4 em `Authorization: Bearer`, sem `api_key` na query (auditoria da sessão 002)
- [ ] Redator de segredos (`api_key`, `session_id`, `request_token`) aplicado no `report` dos handlers, que em release ainda precisa de um destino real (o `developer.log` não aparece)
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
- [ ] `data_extraction_rules.xml` (+ `fullBackupContent`) junto com o `flutter_secure_storage`, e a falha de leitura da sessão tratada como "deslogado"
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
- [ ] Build release ofuscado e assinado: pôr `--obfuscate --split-debug-info=build/symbols` no comando do `CLAUDE.md` e trocar a assinatura de debug

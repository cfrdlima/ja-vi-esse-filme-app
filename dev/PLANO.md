# Plano — Já Vi Esse Filme (Flutter)

> Fonte da verdade do que construir. Atualizado por `/fechar-sessao`.

## Última sessão
**007 — Antes da Fase 1: política de privacidade** (fechada em 2026-10-23) · [log](sessoes/007-politica-de-privacidade.md)
A política (LGPD) está em rascunho 0.2 em `docs/PRIVACIDADE.md`: controlador identificado, legítimo interesse no uso sem login, execução de contrato no login TMDB, contato por e-mail privado e por Issues, e público a partir de 13 anos. Ela vai ser publicada num repositório público separado, com GitHub Pages (decisão 006). Os 7 marcadores `A REVISAR` são resolvidos nas fases em que cada ponto entra.
**Próximo passo:** a Fase 1, a começar por Descobrir.

## Fase 0 — Fundação
- [x] Criar projeto (`io.github.cfrdlima.ja_vi_esse_filme`), `analysis_options.yaml`, `.gitignore` com `env/*.json` (exceto `example.json`)
- [x] `analysis_options.yaml` estrito (`strict-casts`, `strict-inference`, `strict-raw-types`, `avoid_dynamic_calls`, `unawaited_futures`, `avoid_print`…)
- [x] Manifest: permissão `INTERNET` no `main`, `android:allowBackup="false"` e `usesCleartextTraffic="false"` explícito (antes do `core/network`)
- [x] README do projeto e descrição real no `pubspec.yaml`
- [x] `.gitignore`: remover o bloco duplicado e acrescentar `.env*`
- [x] `setup-claude.sh` atualizado (citar a skill `ui-ux-pro-max`)
- [x] Registrar a justificativa do minSdk 24 (decisão curta ou `CLAUDE.md`)
- [x] Handlers globais de erro no `main.dart` (`FlutterError.onError` e `PlatformDispatcher.instance.onError`)
- [x] `core/config` lendo `--dart-define-from-file` + `env/example.json` (token v4 de leitura; atualizar o README junto)
- [x] Gerar design system com `ui-ux-pro-max` (stack Flutter) → `design-system/ja-vi-esse-filme/MASTER.md`
- [x] `core/theme` com tokens do `MASTER.md` (tema escuro, fontes empacotadas)
- [x] `core/network`: cliente TMDB com falhas tipadas (rede, 401, 404, 429, 5xx) — TDD com `MockClient`
- [x] `core/network`: autenticar com o token v4 em `Authorization: Bearer`, sem `api_key` na query (auditoria da sessão 002)
- [x] Redator de segredos (`api_key`, `session_id`, `request_token`) aplicado no `report` dos handlers, que em release ainda precisa de um destino real (o `developer.log` não aparece)
- [x] `go_router` com shell de navegação (Descobrir / Buscar / Estante / Perfil)
- [x] CI (GitHub Actions): format, analyze, test, gitleaks, com a versão do Flutter fixada (3.44.5)
- [x] Confirmar decisão 001 (chave TMDB e proxy)

## Antes da Fase 1
- [x] Decisão: strings de UI centralizadas (`flutter_localizations` + ARB) ou em constantes
- [x] Decisão: `intl` para datas e números em pt-BR (dependência nova)
- [x] Política de privacidade (o que o app coleta, LGPD), para a tela "Sobre"

## Fase 1 — Explorar (sem login)
- [ ] Descobrir: populares, em cartaz, melhor avaliados (paginação infinita)
- [ ] Declarar em `docs/PRIVACIDADE.md` o cache de imagens (`cached_network_image`): prazo e como apagar
- [ ] Busca com debounce e estados vazio/erro, com `include_adult=false` (público 13+, política de privacidade)
- [ ] Detalhes do filme: sinopse, gêneros, duração, nota, elenco
- [ ] Hero do pôster entre a grade/lista e os detalhes
- [ ] Trailers (abrir YouTube externo com host validado)
- [ ] Tela "Sobre" com atribuição ao TMDB, política de privacidade e licenças das fontes (`LicenseRegistry`). Antes dela, criar o repositório público de suporte e publicar a política seguindo o procedimento da decisão 006. O link vai só para o Pages e exige aprovar o `url_launcher`

## Fase 2 — Conta TMDB
- [ ] `TmdbClient` com POST/DELETE e tratamento do 204 com corpo vazio (pré-requisito do login)
- [ ] Login via sessão TMDB (request_token → navegador → session_id no secure storage), validando a origem do retorno do deep link. A aprovação abre no navegador externo ou em Custom Tabs, nunca em WebView. Decidir se o account id e o nome de usuário ficam no aparelho e atualizar a política
- [ ] Logout invalidando a sessão, e apagando o storage local mesmo se o `DELETE` falhar (sem rede, 429). Descrever esse comportamento na política
- [ ] `data_extraction_rules.xml` (+ `fullBackupContent`) junto com o `flutter_secure_storage`, e a falha de leitura da sessão tratada como "deslogado"
- [ ] Favoritos (`/account/{id}/favorite`)
- [ ] Watchlist ("quero ver")

## Fase 3 — "Já vi esse filme"
- [ ] Marcar como **já visto** (definir armazenamento — ver decisão a criar), e atualizar a seção 3.3 da política
- [ ] Nota pessoal / data em que assistiu
- [ ] Listas personalizadas (criar, renomear, adicionar/remover filme)

## Fase 4 — Polimento e release
- [ ] Acessibilidade e fonte grande
- [ ] Ícone, splash, nome do app
- [ ] Crash reporting (Crashlytics ou Sentry — exige decisão de dependência); ao entrar, tirar o `debugPrint` do reporter do release (`kDebugMode`) e atualizar a política
- [ ] Política de privacidade: nenhum marcador `A REVISAR`, vigência com data explícita, cópia publicada igual ao `docs/PRIVACIDADE.md` e permissões do manifest mesclado iguais às da política
- [ ] Rever a decisão 001 (proxy) antes da loja (se entrar, atualizar a política): host do proxy em `AppConfig.allowedHosts`, e atenção ao `replace(queryParameters:)`, que descarta a query da base URL
- [ ] Build release ofuscado e assinado: pôr `--obfuscate --split-debug-info=build/symbols` no comando do `CLAUDE.md` e trocar a assinatura de debug

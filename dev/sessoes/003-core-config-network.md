# Sessão 003 — Fase 0: core/config e core/network

**Data**: 2026-10-16 · **Branch**: `feature/003-core-config-network` · **Status**: fechada

## Objetivo
Criar a base de acesso ao TMDB:
- `AppConfig` lido de `--dart-define-from-file`;
- `TmdbClient` autenticado com o token v4 de leitura (`Authorization: Bearer`) que transforma todo erro HTTP ou de rede em falha tipada;
- redator que tira segredos do log de erros.

Confirmar a decisão 001 com essa forma de autenticação.

## Checklist
- [x] Dependência `http` no `pubspec.yaml` (já aprovada na stack do `CLAUDE.md`)
- [x] Confirmar no TMDB (Context7 ou docs): token v4 nos endpoints v3, formato do corpo de erro, `Retry-After` no 429
- [x] Config — RED: `AppConfig` rejeita token vazio e base URL que não seja HTTPS
- [x] Config — RED: `AppConfig.fromEnvironment()` sem os defines lança falha de configuração
- [x] Config — GREEN / REFACTOR (`lib/core/config/app_config.dart`)
- [x] Falhas: hierarquia `sealed` em Dart puro (`lib/core/error/failures.dart`): rede, não autorizado, não encontrado, rate limit, servidor e inesperada
- [x] Client — RED: o GET monta a URL com base, path, `language=pt-BR` e a query, e manda `Authorization: Bearer`
- [x] Client — GREEN
- [x] Client — RED: o 200 devolve o JSON decodificado
- [x] Client — GREEN
- [x] Client — RED: 401, 404, 429 (com `Retry-After`), 5xx e outros status viram as falhas certas
- [x] Client — GREEN
- [x] Client — RED: `ClientException`, `SocketException` e timeout viram falha de rede, sem a URI na mensagem
- [x] Client — GREEN
- [x] Client — RED: corpo que não é JSON vira falha inesperada
- [x] Client — GREEN / REFACTOR (`lib/core/network/tmdb_client.dart`)
- [x] Redator — RED: `redactSecrets` mascara `api_key`, `session_id`, `request_token` e `Bearer <token>`
- [x] Redator — GREEN / REFACTOR
- [x] Log padrão — RED: o reporter padrão dos handlers loga a mensagem já redigida e aparece em release
- [x] Log padrão — GREEN / REFACTOR
- [x] `env/example.json` com `TMDB_READ_ACCESS_TOKEN`, README atualizado e decisão 001 confirmada
- [x] Tríade: `flutter analyze` limpo, `flutter test` verde (sem UI nesta sessão)
- [x] `/revisar` com `code-reviewer` e `security-auditor` (a sessão mexe em rede e config)
- [x] Revisão A — RED/GREEN: o `language` passado na `query` prevalece sobre o `pt-BR` padrão
- [x] Revisão A — RED/GREEN: path montado por `pathSegments` (barra inicial, base com barra final) e recusa de `.`, `..`, `?` e `#`
- [x] Revisão A — RED/GREEN: corpo com charset inválido, `ArgumentError` e `FormatException` do client viram falha tipada
- [x] Revisão B — RED/GREEN: redator sem diferenciar maiúsculas (`bearer`, `BEARER`, `Session_Id`), com `guest_session_id` e `access_token`, `toString` de `Map`, `%3D`, JSON escapado e valor com aspas escapadas
- [x] Revisão C — RED/GREEN: `AppConfig` transforma URL malformada em `ConfigException`; recusa host vazio, userinfo, query, fragment e host fora da allowlist; faz `trim` no token
- [x] Revisão D: stack trace passa pelo redator; documentar que `UnexpectedFailure.reason` nunca recebe corpo nem URL; `await expectLater` nos testes do client; renomear o teste do `AppConfig` e comentar a dependência dos defines; usar `{}` em vez da fixture no teste de URL

## Decisões
- [001 — Chave do TMDB e sessão do usuário](../decisoes/001-chave-tmdb-e-sessao.md): confirmada como aceita, com o token v4 no header `Authorization: Bearer`

## Commits
- `33aacff` docs: abre sessão 003
- `93e319b` chore: adiciona a dependência http
- `250fca1` test: AppConfig valida token e base URL HTTPS
- `292982a` add: AppConfig lido de --dart-define-from-file
- `691034e` test: TmdbClient monta a URL com pt-BR e autentica com Bearer
- `856255d` add: TmdbClient monta a URL com pt-BR e autentica com Bearer
- `589a93e` test: TmdbClient devolve o JSON decodificado no 200
- `8058aa1` add: TmdbClient devolve o JSON decodificado no 200
- `7ec555e` test: TmdbClient decodifica acentos em UTF-8 sem charset no header
- `b62e50f` add: falhas tipadas de domínio em core/error
- `edf5831` test: TmdbClient mapeia 401, 404, 429, 5xx e outros status para falhas
- `07fc43e` add: TmdbClient mapeia status de erro para falhas tipadas
- `4798d5f` test: TmdbClient converte erro de rede e timeout em NetworkFailure sem URL
- `b0420b7` add: TmdbClient converte erro de rede e timeout em NetworkFailure
- `7b80111` test: TmdbClient trata corpo inválido e falha de TLS
- `407fa3e` add: TmdbClient trata corpo inválido e falha de TLS
- `0e81e20` test: redactSecrets mascara api_key, session_id, request_token e Bearer
- `f340b66` add: redactSecrets mascara segredos do TMDB
- `53731d2` test: redactSecrets mascara segredo em JSON
- `8846b57` add: redactSecrets mascara segredo em JSON
- `11b133d` test: reporter padrão imprime o erro com segredos mascarados
- `cd56cea` fix: reporter padrão imprime em release com segredos mascarados
- `18c8e92` docs: README e example.json com o token de leitura v4
- `f152851` docs: skill tmdb-endpoint usa o TmdbClient e as falhas de core/error
- `d82b6b5` docs: confirma a decisão 001 com o token v4 no header Bearer
- `d44bd9c` docs: registra o andamento da sessão 003
- `2bf67f1` docs: achados aceitos da revisão viram tarefas da sessão 003
- `87f57a3` test: TmdbClient respeita o language passado na query
- `86f4fd0` fix: language da query prevalece sobre o pt-BR padrão
- `5dca6bb` test: TmdbClient normaliza barras e recusa path inseguro
- `7af5fca` fix: TmdbClient normaliza barras e recusa path inseguro
- `73a8164` test: TmdbClient converte exceções inesperadas e deixa Error escapar
- `a047bc8` fix: TmdbClient converte exceções inesperadas em falha tipada
- `742d92b` test: redactSecrets cobre outras grafias, guest_session_id, access_token e JSON escapado
- `b7aebbf` fix: redactSecrets cobre outras grafias, guest_session_id, access_token e JSON escapado
- `5f71b65` test: AppConfig recusa host, userinfo, query e fragment indevidos e faz trim no token
- `7b2ac93` fix: AppConfig recusa host, userinfo, query e fragment indevidos e faz trim no token
- `dc46f7b` test: reporter padrão mascara segredos na stack trace
- `30d21ac` fix: reporter padrão mascara segredos na stack trace
- `ce7dfcb` refactor: testes do TmdbClient com await expectLater
- `da6e370` docs: UnexpectedFailure.reason nunca recebe corpo nem URL
- `3a479ca` docs: skill tmdb-endpoint e log da sessão 003 com o tratamento da revisão

## Notas
- Docs do TMDB (Context7):
  - O Read Access Token no header Bearer é o método recomendado e funciona nos endpoints v3.
  - O corpo de erro traz `status_code`, `status_message` e `success`; as fixtures `tmdb_error_401/404.json` copiam os exemplos.
  - O TMDB **não** documenta o header `Retry-After`. O client o lê só se vier (`RateLimitFailure.retryAfter` é opcional).
- As falhas ficam em `core/error/failures.dart`, em Dart puro, para o `domain` poder importá-las sem depender de `http`.
- O `TmdbClient` usa parâmetros nomeados privados (`required this._httpClient`), recurso do Dart 3.12 que o lint `prefer_initializing_formals` pediu.
- Testes que passaram de primeira, mantidos como guarda:
  - UTF-8 sem charset: o `http` 1.x já trata `application/json` como UTF-8.
  - "Mascarar antes de imprimir": no RED passava porque nada era impresso. A checagem de mutação (tirar o `redactSecrets`) confirma que ele pega a regressão.
- Diferente do planejado: o redator também mascara campos JSON (`"session_id": "..."`), que é o formato da resposta de criação de sessão. Também troquei `SocketException` por `IOException`, para cobrir falha de TLS (`HandshakeException`).
- `main.dart` não foi mexido, como combinado: o `TmdbClient` só é montado junto com a primeira feature.
- **Ação do usuário:** em `env/dev.json`, trocar `TMDB_API_KEY` por `TMDB_READ_ACCESS_TOKEN`, com o "API Read Access Token" do TMDB.
- Tríade: `dart format` sem mudanças, `flutter analyze` sem issues, `flutter test` com 163 testes passando e `gitleaks` sem vazamentos. Não há UI nesta sessão, então não houve verificação no emulador.
- Revisão (`code-reviewer` + `security-auditor`): nada bloqueante; os dois aprovaram. Itens que ficam para depois:
  - POST/DELETE e o 204 com corpo vazio no `TmdbClient`, na sessão de login (Fase 2).
  - A query da base URL é descartada pelo `replace`; rever junto com o proxy.
  - O `debugPrint` do reporter sai do release (`kDebugMode`) quando o crash reporter entrar (Fase 4).
  - Não haverá `==` nas falhas: a UI vai fazer `switch` por tipo.
- Tratamento da revisão:
  - A: o `language` da query prevalece (necessário para o fallback da sinopse) e o path é montado por `pathSegments`. Path com `.`, `..`, `?` ou `#` lança `ArgumentError`, por ser erro do programador. Qualquer `Exception` do envio vira `UnexpectedFailure`, sem a mensagem original; `Error` escapa de propósito. O corpo é decodificado de `bodyBytes`, dentro do mesmo `try` do JSON.
  - A, teste que passou de primeira: "deixar `Error` escapar", mantido como guarda do contrato.
  - B: o redator tem quatro regex (campo JSON, JSON escapado, chave=valor/`%3D`/`: ` e Bearer), todas sem diferenciar maiúsculas. Nomes: `(guest_)session_id`, `api_key`, `request_token`, `access_token`. Um nome logo depois de um escape `%XX` também é mascarado.
  - C: `AppConfig.parse` (token com `trim`, URL malformada vira `ConfigException`) e allowlist de host (`api.themoviedb.org`). Também recusa userinfo, query e fragment.
  - D: a stack trace passa pelo redator; testes do client com `await expectLater`; doc do `UnexpectedFailure.reason`. A skill `tmdb-endpoint` agora diz que entrada do usuário vai só na query.
  - Tríade depois da revisão: `dart format` sem mudanças, `flutter analyze` sem issues, `flutter test` com 191 testes passando e `gitleaks` sem vazamentos.
- Fechamento: `dart format` sem mudanças, `flutter analyze` sem issues, `flutter test` com 191 testes passando e `gitleaks` sem vazamentos. O `/revisar` rodou com `code-reviewer` e `security-auditor`.
- **Pendências** (levadas ao PLANO):
  - POST/DELETE e o 204 com corpo vazio no `TmdbClient`, na sessão de login (Fase 2).
  - O `debugPrint` do reporter sai do release (`kDebugMode`) quando o crash reporter entrar (Fase 4).
  - Proxy (antes da loja): incluir o host na `AppConfig.allowedHosts` e lembrar que o `replace(queryParameters:)` descarta a query da base URL.
  - **Ação do usuário:** em `env/dev.json`, trocar `TMDB_API_KEY` por `TMDB_READ_ACCESS_TOKEN`.

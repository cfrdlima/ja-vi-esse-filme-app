# Sessão 003 — Fase 0: core/config e core/network

**Data**: 2026-10-16 · **Branch**: `feature/003-core-config-network` · **Status**: aberta

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
- [ ] `/revisar` com `code-reviewer` e `security-auditor` (a sessão mexe em rede e config)

## Decisões
- [001 — Chave do TMDB e sessão do usuário](../decisoes/001-chave-tmdb-e-sessao.md): confirmada como aceita, com o token v4 no header `Authorization: Bearer`

## Commits

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

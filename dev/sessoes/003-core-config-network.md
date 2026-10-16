# Sessão 003 — Fase 0: core/config e core/network

**Data**: 2026-10-16 · **Branch**: `feature/003-core-config-network` · **Status**: aberta

## Objetivo
Criar a base de acesso ao TMDB:
- `AppConfig` lido de `--dart-define-from-file`;
- `TmdbClient` autenticado com o token v4 de leitura (`Authorization: Bearer`) que transforma todo erro HTTP ou de rede em falha tipada;
- redator que tira segredos do log de erros.

Confirmar a decisão 001 com essa forma de autenticação.

## Checklist
- [ ] Dependência `http` no `pubspec.yaml` (já aprovada na stack do `CLAUDE.md`)
- [ ] Confirmar no TMDB (Context7 ou docs): token v4 nos endpoints v3, formato do corpo de erro, `Retry-After` no 429
- [ ] Config — RED: `AppConfig` rejeita token vazio e base URL que não seja HTTPS
- [ ] Config — RED: `AppConfig.fromEnvironment()` sem os defines lança falha de configuração
- [ ] Config — GREEN / REFACTOR (`lib/core/config/app_config.dart`)
- [ ] Falhas: hierarquia `sealed` em Dart puro (`lib/core/error/failures.dart`): rede, não autorizado, não encontrado, rate limit, servidor e inesperada
- [ ] Client — RED: o GET monta a URL com base, path, `language=pt-BR` e a query, e manda `Authorization: Bearer`
- [ ] Client — GREEN
- [ ] Client — RED: o 200 devolve o JSON decodificado
- [ ] Client — GREEN
- [ ] Client — RED: 401, 404, 429 (com `Retry-After`), 5xx e outros status viram as falhas certas
- [ ] Client — GREEN
- [ ] Client — RED: `ClientException`, `SocketException` e timeout viram falha de rede, sem a URI na mensagem
- [ ] Client — GREEN
- [ ] Client — RED: corpo que não é JSON vira falha inesperada
- [ ] Client — GREEN / REFACTOR (`lib/core/network/tmdb_client.dart`)
- [ ] Redator — RED: `redactSecrets` mascara `api_key`, `session_id`, `request_token` e `Bearer <token>`
- [ ] Redator — GREEN / REFACTOR
- [ ] Log padrão — RED: o reporter padrão dos handlers loga a mensagem já redigida e aparece em release
- [ ] Log padrão — GREEN / REFACTOR
- [ ] `env/example.json` com `TMDB_READ_ACCESS_TOKEN`, README atualizado e decisão 001 confirmada
- [ ] Tríade: `flutter analyze` limpo, `flutter test` verde (sem UI nesta sessão)
- [ ] `/revisar` com `code-reviewer` e `security-auditor` (a sessão mexe em rede e config)

## Decisões

## Commits

## Notas

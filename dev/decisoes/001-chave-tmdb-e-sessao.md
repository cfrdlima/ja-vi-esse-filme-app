# 001 — Chave do TMDB e sessão do usuário

**Data**: 2026-10-16 · **Status**: aceita (confirmada na sessão 003, em 2026-10-16)

## Contexto
O app consome a API do TMDB, que exige uma credencial (v3 `api_key` ou token de leitura v4). Num app mobile, qualquer valor embutido no APK pode ser extraído por engenharia reversa — `--dart-define` e ofuscação só dificultam. As ações de conta (favoritos, watchlist, listas) usam um `session_id` por usuário.

## Opções consideradas
1. **Credencial no app via `--dart-define-from-file`** — simples, sem infraestrutura. Risco: credencial extraível; abuso pode levar à revogação dela.
2. **Proxy próprio** (Cloud Function / Cloudflare Worker) que guarda a credencial e repassa as chamadas — ela nunca sai do servidor; permite cache e rate limit. Custo: infraestrutura e latência.

Para a forma de autenticar dentro da opção 1:
- **`api_key` v3 na query** — a credencial vai em toda URL e aparece em qualquer exceção ou log que carregue a URI.
- **Token de leitura v4 no header `Authorization: Bearer`** — é o método recomendado pelo TMDB e funciona nos endpoints v3 e v4; a credencial fica fora da URL.

## Decisão
**Opção 1** no desenvolvimento, com o **token de leitura v4 no header `Authorization: Bearer`** (`TMDB_READ_ACCESS_TOKEN` em `env/*.json`).

Todo acesso ao TMDB passa pelo `TmdbClient` (`core/network`). Assim, trocar para a **opção 2** antes do release público é mudar só a base URL e os headers montados ali.

`session_id` sempre em `flutter_secure_storage`; nunca em log nem `shared_preferences`. Como os endpoints de conta v3 recebem o `session_id` na query, o `TmdbClient` converte exceções de rede em falhas sem a URI, e o reporter global de erros passa a mensagem por `redactSecrets`.

## Consequências
- `env/*.json` fora do git; só `env/example.json` versionado.
- `AppConfig` (`core/config`) é o único lugar que lê `String.fromEnvironment` e recusa token vazio ou base URL sem HTTPS.
- O token continua extraível do APK: o pior caso é abuso da cota e revogação, não acesso à conta de usuários (isso exige o `session_id`).
- Release com `--obfuscate --split-debug-info`.
- Rever a escolha do proxy antes de publicar na loja.

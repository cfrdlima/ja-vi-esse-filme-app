# 001 — Chave do TMDB e sessão do usuário

**Data**: 2026-10-16 · **Status**: proposta — confirmar na Fase 0

## Contexto
O app consome a API do TMDB, que exige uma chave (v3 `api_key` ou token de leitura v4). Num app mobile, qualquer valor embutido no APK pode ser extraído por engenharia reversa — `--dart-define` e ofuscação só dificultam. As ações de conta (favoritos, watchlist, listas) usam um `session_id` por usuário.

## Opções consideradas
1. **Chave no app via `--dart-define-from-file`** — simples, sem infraestrutura. Risco: chave extraível; abuso pode levar à revogação dela.
2. **Proxy próprio** (Cloud Function / Cloudflare Worker) que guarda a chave e repassa as chamadas — chave nunca sai do servidor; permite cache e rate limit. Custo: infraestrutura e latência.

## Decisão (proposta)
Começar com a **opção 1** no desenvolvimento, isolando todo acesso ao TMDB atrás de `TmdbClient` em `core/network`, de modo que trocar para a **opção 2** antes do release público seja mudar só a base URL e os headers.

`session_id` sempre em `flutter_secure_storage`; nunca em log nem `shared_preferences`.

## Consequências
- `env/*.json` fora do git; só `env/example.json` versionado.
- Release com `--obfuscate --split-debug-info`.
- Rever esta decisão antes de publicar na loja.

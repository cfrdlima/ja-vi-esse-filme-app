# 008 — Sinopse original via `append_to_response=translations`

**Data**: 2026-10-23 · **Status**: aceita

## Contexto
O app pede tudo em `language=pt-BR` (`TmdbClient`). Quando o filme não tem tradução para pt-BR, o `/movie/{id}` devolve `overview` vazio, e o `CLAUDE.md` pede o texto original nesse caso. Com o idioma fixo em pt-BR, a resposta não traz a sinopse original: ela só aparece num pedido em outro idioma ou na lista de traduções (`/movie/{id}/translations`), em que cada item tem `iso_639_1`, `iso_3166_1` e `data.overview`.

A tela de detalhes (sessão 011) já pede `/movie/{id}` com `append_to_response=credits` para trazer o elenco no mesmo pedido.

## Opções consideradas
1. **Anexar `translations` ao mesmo pedido** (`append_to_response=credits,translations`) e, se a sinopse pt-BR vier vazia, usar a da tradução cujo `iso_639_1` é o `original_language` do filme. É um pedido só, uma falha só para tratar e nenhum gasto a mais de rate limit. Em troca, a resposta cresce: um filme popular tem dezenas de traduções, na ordem de dezenas de KB a mais.
2. **Segundo pedido só quando a sinopse vier vazia**, com `language=<original_language>`. A resposta comum fica menor, mas o caso sem tradução vira dois pedidos em sequência, com dois pontos de falha, a espera de um 429 no meio e um estado a mais na tela.

## Decisão
Opção 1. A tela já depende de um pedido grande (o `credits` traz o elenco e a equipe inteiros), e manter um pedido por tela deixa o estado e o tratamento de falha iguais aos das outras telas.

## Consequências
- O datasource pede `append_to_response=credits,translations`. O model escolhe, entre as traduções no idioma original, a primeira com sinopse não vazia. Sem nenhuma, a tela mostra "sinopse não disponível".
- Nada das traduções além dessa sinopse chega ao domínio.
- Se o tamanho da resposta pesar (medido no aparelho ou em reclamação de dados móveis), a troca para a opção 2 fica só no datasource e no model, sem mexer no domínio nem na tela.

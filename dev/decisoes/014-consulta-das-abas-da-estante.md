# 014 — Consulta das abas da Estante: só `orderBy` e limite crescente com teto

**Data**: 2026-11-17 · **Status**: aceita

## Contexto
A decisão 013 previu que cada aba da Estante consultaria com `where('<marca>At', '!=', null)` e `orderBy('<marca>At')`. Na sessão 023 apareceram três pontos:
- **O `where` com `null` não funciona no `cloud_firestore` 7.1.0.** O `Query.where` só põe a condição `!=` quando `isNotEqualTo != null`. Passar `null` não filtra nada, e a consulta traria todos os documentos.
- **Paginação ao vivo.** A aba precisa mostrar as marcas novas, inclusive as feitas offline, e sumir com o filme desmarcado sem recarregar. Um cursor (`startAfterDocument`) com `get()` deixaria as páginas antigas paradas, e um cursor com listener por página repete ou pula filmes quando a ordem muda.
- **Cota do Spark (50 mil leituras por dia, para o projeto inteiro).** Cada vez que o limite muda, o Firestore abre um alvo novo e cobra de novo todos os documentos devolvidos. Mostrar N filmes com passos de 20 custa cerca de N²/40 leituras: 200 filmes custam 1.100, e 1.000 filmes custariam 25 mil (`security-auditor` da 023).

## Opções consideradas
1. **Só o `orderBy(<marca>At, descending: true)` com `limit` crescente e um teto.** O Firestore deixa fora do resultado o documento sem o campo ordenado (conferido no emulador). A lista inteira continua ao vivo, e o teto limita o custo.
2. **`where(<marca>At, isNull: false)` + `orderBy`.** Funciona, mas o `!=` não acrescenta nada ao `orderBy` e impede outras desigualdades na mesma consulta.
3. **Primeira página ao vivo e as seguintes por cursor com `get()`.** O custo de leitura é linear, mas as páginas seguintes não se atualizam, e a junção das duas listas precisa tirar filmes repetidos quando a ordem muda.

## Decisão
- Cada aba assina `orderBy('<marca>At', descending: true).limit(n)`, sem `where`.
- O limite começa em 20, cresce de 20 em 20 ao chegar perto do fim da grade e para em **200** (`ShelfTabNotifier.maxLimit`). Com mais filmes que isso, o rodapé avisa "Mostrando os 200 filmes mais recentes.".
- A marca feita offline entra no topo: o SDK ordena o `serverTimestamp()` pendente depois de todas as datas, e a posição se mantém quando o servidor confirma (conferido no emulador, sessão 023).

## Consequências
- O pior caso por aba é rolar até o teto: cerca de 1.100 leituras. Depois disso, cada mudança custa só os documentos que mudaram, enquanto o listener viver.
- Filmes além dos 200 mais recentes de uma marca não aparecem na Estante. Se isso virar problema, a opção 3 entra com cursor só depois do teto. Fica no backlog.
- Com um total múltiplo exato de 20, o `hasMore` pede mais um passo, que volta igual. Isso custa uma releitura da aba.
- A decisão 013 aponta para esta decisão no lugar do `where('<marca>At', '!=', null)`.

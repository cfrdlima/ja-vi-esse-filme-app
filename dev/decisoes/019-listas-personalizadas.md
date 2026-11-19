# 019 — Listas personalizadas: mapa de listas no documento do filme

**Data**: 2026-11-18 · **Status**: aceita

## Contexto
A Fase 3 pede listas próprias: criar, renomear, apagar, adicionar e remover filme, com o nome validado e o tamanho máximo no domínio. O `PLANO.md` imaginava uma subcoleção `users/{uid}/lists/{listId}/items/{movieId}`, com exclusão aninhada na exclusão da conta (decisão 015, `/revisar` da sessão 024).

O que pesou na sessão 029:
- **Cópia do TMDB:** um item precisa do título e do pôster para aparecer na grade, e o filme da lista pode não ter marca nenhuma. Na subcoleção, cada item teria a própria cópia, com `cachedAt`, renovação na tela e limpeza mensal (decisões 013 e 017). Um filme em 5 listas teria 6 cópias do mesmo dado.
- **O SDK do cliente não apaga em cascata** (decisão 010). Com os itens aninhados, apagar uma lista e excluir a conta precisam de laço por lista, e o `rules-file.test.js` e o `UserCollections` deixam de ser de um nível só.
- **Cota do Spark até o App Check:** as regras são a única barreira (decisão 010), e elas não contam documentos de uma coleção. Na subcoleção, nem o tamanho de uma lista nem o número de listas tem teto nas regras.
- **Ordem dentro da lista:** "quando adicionei", como nas abas (decisão 014). Um `orderBy` num campo de mapa (`lists.<id>`) usa o índice simples automático do Firestore, que cobre os subcampos de mapa.
- **UI:** o usuário escolheu as listas como a 4ª aba da Estante, ao lado de Assistidos, Quero assistir e Favoritos.

## Opções consideradas
1. **Subcoleção `items` por lista**, com a cópia do TMDB em cada item. É o desenho do `PLANO.md`: cópias repetidas, exclusão aninhada e nenhum teto nas regras.
2. **Mapa `lists: {<listId>: <quando adicionou>}` no documento do filme** (`users/{uid}/movies/{movieId}`), e uma coleção `users/{uid}/lists/{listId}` só com o nome. Uma cópia do TMDB por filme, que a renovação e a limpeza mensal já cobrem. A exclusão continua de um nível, e as regras limitam quantas listas cabem num filme. Em troca, o documento do filme passa a existir sem marca nenhuma.
3. **Array `listIds` no documento do filme.** As regras limitam o tamanho do mesmo jeito, mas o `array-contains` com `orderBy` em outro campo pede índice composto, e um array não guarda quando o filme entrou em cada lista.

## Decisão
Opção 2.

- **Lista:** `users/{uid}/lists/{listId}`, com só o campo `name`. O `listId` é o id automático do Firestore (`doc()`, 20 caracteres `[A-Za-z0-9]`), conferido nas regras. As listas aparecem em ordem alfabética, ordenadas no aparelho sem diferenciar maiúsculas e acentos, porque o `orderBy` do Firestore compara bytes. Com o teto de 50, a aba lê todas.
- **Nome:** o domínio tira os espaços das pontas e exige de 1 a 50 unidades UTF-16 (o `length` do Dart, que é como as regras contam o `size()`, conferido no emulador: um emoji fora do plano básico conta 2), sem caractere de controle (quebra de linha, tab). As regras repetem o tamanho, o "não só espaços" e o caractere de controle (`\p{Cc}`). Nomes repetidos são permitidos. O contador do campo segue a mesma conta, e não a de grafemas, que é o padrão do `maxLength` do Flutter.
- **Filme na lista:** o campo `lists` do documento do filme é um mapa de `listId` para a hora do servidor em que o filme entrou na lista. Ele é ausente quando o filme não está em lista nenhuma: as regras recusam o mapa vazio, e tirar o filme da última lista remove o campo. As regras exigem, a cada escrita:
  - no máximo 50 chaves (`lists.size() <= 50`), cada uma no formato do id da lista (`keys().join(',')` com regex; conferir no emulador no RED);
  - no máximo uma chave mudada por escrita (`diff().affectedKeys().size() <= 1`), sem mudar a hora de uma chave que já existe (`changedKeys()` vazio);
  - a chave nova com o valor `request.time`, pela diferença entre os valores novos e os antigos.
- **"Sem motivo, sem documento" (emenda na 013):** o documento do filme existe se tiver ao menos uma marca **ou** o campo `lists`. A nota e o dia (decisão 018) continuam só com o `watchedAt`. Desmarcar a última marca de um filme que está em alguma lista vira `update`, e não `delete`. Tirar o filme da última lista, sem marca nenhuma, apaga o documento. A corrida do desmarcar aceita na 013 vale igual aqui.
- **Conteúdo de uma lista:** `movies` com `orderBy('lists.<listId>', descending: true)` e o limite crescente com teto de **200** (decisão 014). Nenhum `firestore.indexes.json`.
- **Tetos:** 50 listas por conta e 200 filmes por lista ficam **só no domínio**. As regras não sabem contar, e um cliente adulterado passa deles até o App Check. Nas regras ficam o limite de 50 listas por filme e o tamanho do nome.
- **Apagar uma lista:** primeiro tirar a chave de cada filme, lendo do servidor (`Source.server`) em lotes de até 500, com o prazo de 15 s por passo (decisão 015); o filme que ficar sem motivo é apagado. A lista sai por último. Uma falha no meio deixa a lista com menos filmes, e tentar de novo termina. Sem rede, falha com `NetworkFailure`. Uma chave de lista que não existe mais (outro aparelho, falha no meio) é ignorada pelo app.
- **Exclusão da conta:** `UserCollections.all` ganha só `lists`. Continua tudo num nível, e o `rules-file.test.js` não muda de formato.
- **Código em `lib/features/shelf`:** o vínculo com a lista é um campo do documento do filme, que já é dessa feature. Uma feature `lists` separada teria de ler e escrever o modelo da Estante. A aba das listas é a 4ª da Estante.

Esta decisão complementa a 013, a 014 e a 015, e não substitui nenhuma.

## Consequências
- As regras do `movies` mudam: a chave `lists`, a validação do mapa e o `hasAny(marks)` passam a aceitar o documento sem marcas com o `lists` preenchido. Os testes das regras são estendidos (decisão 012). A coleção `lists` ganha `match` e testes próprios.
- A chave de uma lista inexistente não é negada pelas regras: o `exists()` pediria o `listId`, e as regras não tiram um elemento de um `Set`. O pior caso é um filme com até 50 chaves sem lista, de até 20 caracteres, ignoradas pelo app.
- O `ShelfMovie` ganha os ids das listas, e o `removeMark` passa a olhar para eles antes de escolher entre `delete` e `update`.
- A renovação da cópia vencida (`ExpiredCopyRenewer`) e a limpeza mensal já cobrem os filmes que só estão em listas, porque são documentos de `movies`. A limpeza mensal precisa de um teste no emulador provando isso. Se o filme sumir do TMDB, a limpeza apaga o documento, e ele sai de todas as listas.
- O nome da lista é texto livre do usuário: a política 2.0, a página de exclusão e o diálogo da exclusão da conta passam a citar as listas.
- O item do `PLANO.md` sobre a exclusão aninhada dos `items` e o comentário de `UserCollections` sobre "exclusão aninhada" deixam de valer: não existem `items`.
- Um filme em uma lista sem marca nenhuma não aparece nas outras três abas, porque elas ordenam por `<marca>At`, e o `orderBy` exclui quem não tem o campo.
- **Emenda (`/revisar` da sessão 029): chave órfã.** A chave de uma lista que não existe mais fica no filme quando outro aparelho, offline, põe o filme numa lista que foi apagada, ou quando o servidor recusa a criação de uma lista em que o filme já entrou. Com ela, o filme sem marca não aparece em lugar nenhum. O app tira o filme da lista cuja criação foi recusada, e a limpeza mensal (decisão 017) tira as chaves sem `lists/{id}` e apaga o filme que fica sem marca e sem lista. Até a limpeza, o botão dos Detalhes pode dizer "Nas suas listas" por causa dela.
- **Emenda (`/revisar` da sessão 029): recusa ao tirar da lista.** As regras recusam tirar a chave quando o aparelho via listas que o servidor já não tem (o mapa ficaria vazio, ou mudariam duas chaves). Nesse caso o repositório relê o filme do servidor e refaz a escrita com ele, e só apaga o documento se o servidor confirmar que a lista era o único motivo. Apagar direto levaria as marcas, a nota e o dia.


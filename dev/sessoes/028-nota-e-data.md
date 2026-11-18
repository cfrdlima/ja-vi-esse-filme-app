# Sessão 028 — Fase 3: nota pessoal e data em que assistiu

**Data**: 2026-11-18 · **Branch**: `feature/028-nota-e-data` (empilhada na `feature/027-limpeza-mensal`) · **Status**: aberta

## Objetivo
Permitir que o usuário dê a um filme assistido uma nota de 0,5 a 5 estrelas (`rating`, inteiro de 1 a 10 no Firestore) e escolha o dia em que assistiu (`watchedOn`, data civil `AAAA-MM-DD`, gravada só quando ele escolhe, nunca futura nem antes de 1888). Os dois campos só existem com a marca Assistido: desmarcar Assistido apaga os dois depois de um aviso. O `watchedAt` continua sendo a hora do servidor e ainda ordena a aba.

## Checklist
### Preparação
- [x] Decisão (`/decisao`): `rating` e `watchedOn` no documento do filme, a escala, o formato da data, o vínculo com o Assistido e a emenda na 013 (o cliente escolhe o `watchedOn`, mas nunca os `<marca>At`)
- [ ] Consultar a `ui-ux-pro-max` (stack Flutter) para o seletor de estrelas e o de data nos Detalhes; override em `pages/` se precisar
- [ ] Conferir o `firestore/cleanup` (a renovação usa `update` e preserva os campos novos) e a exclusão da conta (a subcoleção `movies` já está na lista)

### Regras do Firestore (RED/GREEN/REFACTOR, no emulador)
- [ ] Aceita `rating` inteiro de 1 a 10 e recusa 0, 11, fracionário e string
- [ ] Aceita `watchedOn` no formato `AAAA-MM-DD`, com dia válido, e recusa outros formatos
- [ ] Recusa `rating` ou `watchedOn` sem o `watchedAt`
- [ ] `rules-file.test.js` e os testes de chaves fixas cobrem os campos novos

### Domínio (RED/GREEN/REFACTOR)
- [ ] `Rating` (meia estrela de 0,5 a 5): recusa valores fora da escala, converte de e para o inteiro de 1 a 10
- [ ] `WatchedOn` (data civil): recusa data futura (pelo relógio injetado) e antes de 1888
- [ ] `ShelfMovie` com nota e data opcionais, só com a marca Assistido
- [ ] `ShelfRepository`: `rate`, `clearRating`, `setWatchedOn` (ou equivalente). Contrato decidido no ciclo

### Data (RED/GREEN/REFACTOR, com fakes do gateway)
- [ ] O model lê `rating` e `watchedOn` de forma defensiva: um valor inválido vira "sem nota" ou "sem data", sem derrubar o filme
- [ ] O repositório grava a nota e a data só com `update`, sem mexer nas marcas nem na cópia
- [ ] `removeMark(watched)` com outras marcas também apaga `rating` e `watchedOn`
- [ ] `addMark(watched)` não grava o `watchedOn` (decisão 018: só quando o usuário escolhe; a tela sugere o dia do `watchedAt`)

### Apresentação (RED/GREEN/REFACTOR, widget tests)
- [ ] Estado: dar e tirar a nota e trocar a data com atualização otimista, e erro com "tentar de novo"
- [ ] Detalhes: estrelas (alvos de 48dp, `Semantics` com "3,5 de 5 estrelas") e data, só com Assistido; os 4 estados
- [ ] Aviso antes de desmarcar Assistido quando há nota ou data
- [ ] Textos no ARB (PT-BR); fonte grande sem overflow
- [ ] Verificação no emulador (screenshot via MCP do Flutter)

### Entrega
- [ ] `docs/PRIVACIDADE.md`: tirar o `A REVISAR` da Fase 3 só para a nota e a data (as listas continuam marcadas)
- [ ] `PLANO.md`: item marcado
- [ ] Tríade (format, analyze, `flutter test`), `npm test` em `firestore/` (JDK 21) e `gitleaks`
- [ ] `/revisar` (regras do Firestore e dado pessoal novo)

## Decisões
- [018 — Nota pessoal e data em que assistiu](../decisoes/018-nota-e-data-em-que-assistiu.md) (emenda na 013)
- Escolhas do usuário na abertura: estrelas de 0,5 a 5; a data como campo novo, só o dia; nota e data só com Assistido.

## Commits

## Notas
- **Empilhada:** 025 (PR #21), 026 (PR #22) e 027 (PR #23) esperam o CI destravar (cobrança da conta no GitHub).
- **JDK:** os testes do `firestore/` rodam com `JAVA_HOME=/usr/lib/jvm/java-21-openjdk`.

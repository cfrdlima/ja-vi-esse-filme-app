# Sessão 028 — Fase 3: nota pessoal e data em que assistiu

**Data**: 2026-11-18 · **Branch**: `feature/028-nota-e-data` (empilhada na `feature/027-limpeza-mensal`) · **Status**: aberta

## Objetivo
Permitir que o usuário dê a um filme assistido uma nota de 0,5 a 5 estrelas (`rating`, inteiro de 1 a 10 no Firestore) e escolha o dia em que assistiu (`watchedOn`, data civil `AAAA-MM-DD`, gravada só quando ele escolhe, nunca futura nem antes de 1888). Os dois campos só existem com a marca Assistido: desmarcar Assistido apaga os dois depois de um aviso. O `watchedAt` continua sendo a hora do servidor e ainda ordena a aba.

## Checklist
### Preparação
- [x] Decisão (`/decisao`): `rating` e `watchedOn` no documento do filme, a escala, o formato da data, o vínculo com o Assistido e a emenda na 013 (o cliente escolhe o `watchedOn`, mas nunca os `<marca>At`)
- [ ] Consultar a `ui-ux-pro-max` (stack Flutter) para o seletor de estrelas e o de data nos Detalhes; override em `pages/` se precisar
- [x] Conferir o `firestore/cleanup` (a renovação usa `update` e preserva os campos novos) e a exclusão da conta (a subcoleção `movies` já está na lista). **Feito:** teste no emulador de que a renovação mantém `rating` e `watchedOn` (passou de primeira, porque o Admin SDK ignora as regras e o `update` só toca na cópia); a exclusão apaga o documento inteiro

### Regras do Firestore (RED/GREEN/REFACTOR, no emulador)
- [x] Aceita `rating` inteiro de 1 a 10 e recusa 0, 11, fracionário e string
- [x] Aceita `watchedOn` no formato `AAAA-MM-DD`, com mês de 01 a 12, dia de 01 a 31 e ano de 1888 em diante, e recusa outros formatos (o dia fora do calendário fica no domínio)
- [x] Recusa `rating` ou `watchedOn` sem o `watchedAt`; tirar o Assistido exige tirar os dois no mesmo `update`
- [x] `rules-file.test.js` e os testes de chaves fixas cobrem os campos novos. **Feito:** sem mudança no `rules-file.test.js` (nenhum `match` novo); `firestore/test/movie-rating.test.js` com 31 testes

### Domínio (RED/GREEN/REFACTOR)
- [x] `Rating` (meia estrela de 0,5 a 5): recusa valores fora da escala, converte de e para o inteiro de 1 a 10
- [x] `WatchedOn` (data civil): recusa dia fora do calendário e ano fora de 1888 a 9999. **Mudou:** o futuro fica no `ChooseWatchedOn` (relógio injetado), que também dá o "hoje" do seletor e a sugestão (dia escolhido ou dia local do `watchedAt`); o model aceita o dia futuro gravado por outro aparelho, porque o fuso dele pode estar à frente (emenda na 018)
- [x] `ShelfMovie` com nota e data opcionais, só com a marca Assistido, e `losesPersonalDataWithout(mark)` para o aviso
- [x] `ShelfRepository`: `rate`, `clearRating`, `setWatchedOn`, `clearWatchedOn`, com `ArgumentError` sem o Assistido e o documento que sumiu contando como sucesso

### Data (RED/GREEN/REFACTOR, com fakes do gateway)
- [x] O model lê `rating` e `watchedOn` de forma defensiva: um valor inválido vira "sem nota" ou "sem data", sem derrubar o filme
- [x] O repositório grava a nota e a data só com `update`, sem mexer nas marcas nem na cópia
- [x] `removeMark(watched)` com outras marcas também apaga `rating` e `watchedOn` (sempre, mesmo sem vê-los no aparelho)
- [x] `addMark(watched)` não grava o `watchedOn` (decisão 018: só quando o usuário escolhe; a tela sugere o dia do `watchedAt`). **Feito:** sem mudança no `markFields`

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
- **Suíte do `firestore/`:** 200 verdes (120 das regras, com 31 novos, e 80 da limpeza, com 1 novo).
- **JDK no PATH:** além do `JAVA_HOME`, o `firebase-tools` só achou o 21 com `PATH=/usr/lib/jvm/java-21-openjdk/bin:$PATH`.
- **Empilhada:** 025 (PR #21), 026 (PR #22) e 027 (PR #23) esperam o CI destravar (cobrança da conta no GitHub).
- **JDK:** os testes do `firestore/` rodam com `JAVA_HOME=/usr/lib/jvm/java-21-openjdk`.

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
- [x] Verificação no emulador (screenshot via MCP do Flutter). **Feito** por `adb` (sem MCP do Flutter nesta máquina), com a conta de teste descartável escolhida pelo usuário; ver "Notas"

### Entrega
- [ ] `docs/PRIVACIDADE.md`: tirar o `A REVISAR` da Fase 3 só para a nota e a data (as listas continuam marcadas)
- [ ] `PLANO.md`: item marcado
- [ ] Tríade (format, analyze, `flutter test`), `npm test` em `firestore/` (JDK 21) e `gitleaks`
- [x] `/revisar` (regras do Firestore e dado pessoal novo). **Feito:** `code-reviewer` (1 bloqueante, 4 importantes, 6 sugestões) e `security-auditor` (nenhum bloqueante, 2 importantes, 4 sugestões); o usuário aceitou todos

### Achados aceitos do `/revisar`
- [x] (B1) A recusa do servidor some quando o Firestore já mostrou o valor: id da última escrita por campo, separado do pendente, e o pendente descartado só pela confirmação da última escrita (junto a S11). **Feito:** o pendente fica até a escrita dele terminar, e o snapshot não o tira mais
- [x] (I2) Nada é gravado depois do dispose, e o seletor confere o `context.mounted`
- [x] (I3) Override `detalhes.md`: o bloco aparece só com o Assistido confirmado pela Estante
- [x] (I4) Estrelas com `slider: true`, sem `onIncrease` no máximo nem `onDecrease` sem nota; teste do `decrease` pelo leitor de tela
- [x] (I5) Depois do diálogo, tira o Assistido só se ele ainda estiver ligado
- [x] (I6) `PRIVACIDADE.md`: histórico da 2.0 e seção 7 com a nota e o dia
- [x] (S7) "Hoje" do seletor calculado na hora de abrir
- [x] (S8) `ArgumentError` síncrono no `_writePersonal`
- [x] (S9) Comentário da regex do `watchedOn` no model
- [x] (S10) Botão do dia com o rótulo "Escolher quando assistiu" para o leitor de tela
- [x] (S11) Fonte grande com a sugestão "(dia da marca)" e com o `UnwatchDialog`
- [x] (S12) Regras: `updateDoc` da nota sem o Assistido, `merge` da nota num documento inexistente e nota com `watchedAt` antigo, todos negados. **Feito:** passaram de primeira (as regras já negavam); conferido por mutação (sem o `watchedAt` na regra da nota, 3 falham)
- [x] (S13) Aviso do logout cita as notas e os dias
- [x] (S14) `EXCLUSAO-DA-CONTA.md` (cópia local nos outros aparelhos) e concordância na `PRIVACIDADE.md`

## Decisões
- [018 — Nota pessoal e data em que assistiu](../decisoes/018-nota-e-data-em-que-assistiu.md) (emenda na 013)
- Escolhas do usuário na abertura: estrelas de 0,5 a 5; a data como campo novo, só o dia; nota e data só com Assistido.

## Commits

## Notas
- **Emulador (`Pixel_9_Pro`, Android 16, projeto real, conta de teste descartável escolhida pelo usuário):**
  - Cancelar o seletor do Google deixa a folha de login aberta, sem erro. Depois do login, o Assistido entra sozinho e o painel aparece com 5 estrelas vazias e "18/11/2026 (dia da marca)".
  - **Regras desatualizadas no projeto real (como na 022):** a primeira nota deu `PERMISSION_DENIED`. A tela mostrou "Algo deu errado." com "Tentar de novo", e as estrelas voltaram ao vazio: o caminho do B1 com o Firestore real. Com a confirmação do usuário, as regras desta branch foram publicadas (`firebase deploy --only firestore:rules --project ja-vi-esse-filme --account` da conta dona do projeto; a conta padrão da CLI deu 403).
  - Depois do deploy: "Tentar de novo" grava 4 estrelas; tocar de novo na quarta dá 3,5 (meia estrela desenhada); o seletor abre no dia sugerido, com os dias depois de hoje desabilitados; escolher 12 mostra "12/11/2026" com "Tirar dia".
  - Tirar o Assistido com nota abre "Tirar dos assistidos?"; "Cancelar" mantém tudo; "Tirar" desmarca e some com o painel. Com o Favorito ligado, tirar o Assistido mantém o Favorito sem erro, e remarcar o Assistido mostra as estrelas vazias (a nota saiu no servidor).
  - A exclusão da conta pelo app terminou em "Sua conta foi excluída.". **Achado:** o diálogo da exclusão dizia "Vamos apagar seus assistidos, quero assistir e favoritos", sem a nota e o dia; corrigido a pedido do usuário (texto no ARB, o teste usa a chave).
- **Suíte do `firestore/` depois dos achados:** 203 verdes.
- **Suíte do `firestore/`:** 200 verdes (120 das regras, com 31 novos, e 80 da limpeza, com 1 novo).
- **JDK no PATH:** além do `JAVA_HOME`, o `firebase-tools` só achou o 21 com `PATH=/usr/lib/jvm/java-21-openjdk/bin:$PATH`.
- **Empilhada:** 025 (PR #21), 026 (PR #22) e 027 (PR #23) esperam o CI destravar (cobrança da conta no GitHub).
- **JDK:** os testes do `firestore/` rodam com `JAVA_HOME=/usr/lib/jvm/java-21-openjdk`.

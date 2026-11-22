# 020 — Piso de acessibilidade nos testes: escala 2.0 em 320dp e guidelines em toda tela

**Data**: 2026-11-22 · **Status**: aceita

## Contexto
O `MASTER.md` e a skill `tela-4-estados` pedem um teste com `textScaler` 1.5 sem overflow. Algumas sessões já testaram 2.0 por conta própria. As três guidelines do Flutter (`androidTapTargetGuideline`, `labeledTapTargetGuideline` e `textContrastGuideline`) só aparecem em cinco arquivos de teste.

A auditoria da sessão 030 rodou as três guidelines e a captura de overflow em todas as telas, nos estados principais, em 360dp e 320dp, com escala 1.0 e 2.0. **Não houve nenhuma falha.** O app já cumpre o checklist, mas nada impede uma regressão:
- 1.5 não é o máximo. As configurações de fonte do Android chegam a 2.0 (Android 14 em diante, com a escala não linear), e quem usa fonte grande costuma usar a maior.
- 320dp é a largura mínima de celular que o app aceita sem quebrar o layout. O teste padrão (800×600) esconde overflow horizontal.
- Cada arquivo de teste monta a checagem do seu jeito (`ensureSemantics`, `meetsGuideline`, `tester.view`), e uma tela nova pode esquecer uma delas.

## Opções consideradas
1. **Manter 1.5 e as guidelines onde já estão.** Não dá trabalho, mas deixa a maior parte das telas sem proteção e testa uma escala abaixo da que o usuário usa.
2. **Escala 2.0 em 320dp como piso, e as três guidelines em toda tela, por um ajudante comum em `test/helpers/`.** Um teste por tela e estado principal, com uma checagem só e o mesmo jeito de montar a tela.
3. **Teste de golden em escala 2.0.** Mostra o layout, mas é frágil (fonte e renderização mudam entre versões do Flutter) e não confere alvo de toque, rótulo nem contraste.

## Decisão
Opção 2.
- **Piso:** toda tela e todo estado com texto (sucesso, vazio e erro) têm um teste com `TextScaler.linear(2)` numa view de 320dp de largura, sem exceção de layout. O 1.5 deixa de ser o piso; os testes que já usam 1.5 continuam valendo, mas não bastam numa tela nova.
- **Guidelines:** as três guidelines rodam em toda tela, no estado de sucesso e no estado de erro, com a fonte normal e com a escala 2.0.
- **Ajudante comum** em `test/helpers/`, para a tela montar uma vez e chamar a checagem. Ele cuida do `ensureSemantics`, da view de 320dp e do `addTearDown` dela.
- **Testes de caracterização.** Como o código já passa, esses testes não têm a fase RED. Cada um é validado quebrando o widget de propósito (alvo menor, rótulo tirado, largura fixa), para ver o teste falhar, e desfazendo a quebra. O log da sessão registra que foram validados assim.
- O `MASTER.md` (seções 3 e 9) e a skill `tela-4-estados` passam a dizer 2.0 em 320dp.
- **Exceções**, sempre com o `except` do ajudante e um comentário no teste com o motivo:
  - **Calendário do Material** (`showDatePicker`, no diário): são 7 colunas num diálogo de largura fixa, e cada dia só chega a 48dp em telas a partir de cerca de 392dp (37,7dp em 320dp, 43,4dp em 360dp, 47,4dp em 388dp). É componente do sistema, igual ao do Android, e o TalkBack navega por ele com gestos, sem depender do tamanho do alvo. O teste dele dispensa só a `androidTapTargetGuideline`: rótulo, contraste e layout continuam valendo. Escolhido pelo usuário na sessão 030, em vez de abrir o seletor no modo de digitar.

## Consequências
- Uma tela nova precisa caber em 2.0 e 320dp desde o primeiro widget test. Layouts com linha fixa (cabeçalho com pôster ao lado do texto, barras de chips) precisam quebrar ou rolar.
- As guidelines não pegam tudo: a ordem de leitura, a leitura em dobro, o anúncio de estado e o movimento reduzido continuam dependendo de testes de semântica específicos e da verificação no emulador com o TalkBack.
- O ajudante precisa montar pôsteres sem rede. Com URL, o `cached_network_image` lança `MissingPluginException` (`path_provider`) nos testes. As fixtures do ajudante usam filme sem `posterPath` ou um cache fake.
- A `androidTapTargetGuideline` ignora o nó que encosta na borda da tela, porque ele pode estar cortado. Um widget testado sozinho, sem a margem da tela real, deixa passar alvo pequeno. Por isso o host do teste usa a margem da tela de verdade (`AppSpacing.standard.md` nos Detalhes).
- O `SnackBarAction` do Flutter 3.47 não cabe com a fonte 2x em 320dp (mede o rótulo sem a escala e põe a ação numa `Row` sem limite). Os avisos com ação usam o `showActionSnackBar` de `core/widgets`.
- O contraste da `textContrastGuideline` só vale para o texto sobre cor sólida. Texto sobre imagem (pôster, backdrop) não é medido e continua coberto pela revisão visual.

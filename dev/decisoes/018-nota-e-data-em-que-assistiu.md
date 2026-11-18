# 018 — Nota pessoal e data em que assistiu no documento do filme

**Data**: 2026-11-18 · **Status**: aceita

## Contexto
A Fase 3 pede uma "nota pessoal e data em que assistiu, no documento do filme". A decisão 010 só cita "data, nota" entre os dados do usuário. A decisão 013 deixou para esta fase rever a regra "sem marcas, sem documento" e fixou que toda data do documento é do servidor (`request.time`). Por isso o cliente nunca escolhe quando marcou.

O que pesou na sessão 028:
- **"Nota" não estava definida.** Pode ser uma avaliação em escala ou um comentário em texto. Um texto livre é mais dado pessoal para a política, mais validação e mais espaço por documento, que é a única barreira de cota do Spark até o App Check.
- **O `watchedAt` já tem dono.** Ele ordena a aba Assistidos (decisão 014), e as regras garantem que é a hora do servidor. Quem assistiu ontem e marca hoje quer ver ontem, mas trocar o `watchedAt` bagunça a ordem da aba e abre uma data escolhida pelo cliente num campo que hoje é confiável.
- **Fuso:** "o dia em que assisti" é uma data civil. Um `timestamp` à meia-noite muda de dia conforme o fuso de quem lê.
- **Documento sem marcas:** se a nota existisse sozinha, o documento sem nenhuma marca voltaria a existir, e as regras, o desmarcar e a limpeza das cópias teriam de mudar.

## Opções consideradas
Sobre a nota:
1. **Meia estrela de 0,5 a 5**, guardada como inteiro de 1 a 10.
2. **Inteiro de 1 a 10**, mostrado como número, na escala da nota do TMDB.
3. **Comentário em texto**, com tamanho máximo.
4. **Estrelas e comentário.**

Sobre a data:
1. **Campo novo `watchedOn`, só o dia**, escolhido pelo usuário. O `watchedAt` continua sendo do servidor.
2. **O usuário escolhe o `watchedAt`.**
3. **Campo novo como `timestamp`** à meia-noite.

Sobre o vínculo com a marca:
1. **Nota e data só com o Assistido.**
2. **Independentes**, e a nota sozinha mantém o documento.

## Decisão
- **`rating`: inteiro de 1 a 10**, em que cada unidade vale meia estrela (1 = 0,5 estrela; 10 = 5 estrelas). O inteiro evita o ponto flutuante nas regras e na comparação. Sem nota, o campo fica ausente: tirar a nota apaga o campo, e não existe nota 0.
- **`watchedOn`: string `AAAA-MM-DD`**, a data civil escolhida pelo usuário, sem hora e sem fuso.
  - **As regras** conferem o formato e o intervalo: ano de 1888 em diante, mês de 01 a 12 e dia de 01 a 31.
  - **O domínio** confere o resto: dia que existe no calendário e data que não está no futuro, pelo relógio injetado. As regras não sabem qual é "hoje" no fuso do usuário.
- **Só quem escolhe grava a data:** marcar o Assistido não grava o `watchedOn`. A tela mostra o dia local do `watchedAt` como sugestão, sem escrever nada.
- **Nota e data exigem o `watchedAt`.** As regras recusam `rating` ou `watchedOn` sem ele.
  - Desmarcar o Assistido de um filme com outras marcas apaga os três campos no mesmo `update`.
  - Desmarcar o Assistido quando ele é a única marca apaga o documento, como antes.
  - Nos dois casos, a UI avisa antes se há nota ou data.
  - A regra "sem marcas, sem documento" da 013 continua valendo.
- **Exceção à "data só do servidor" da 013, limitada ao `watchedOn`:** ele é um dado que o usuário declara, e não um registro de quando algo aconteceu no app. O `watchedAt`, o `watchlistAt`, o `favoriteAt` e o `cachedAt` seguem só com o `request.time` ou mantidos.
- **Gravar a nota ou a data é um `update` só daquele campo.** Ele não mexe nas marcas nem na cópia do TMDB, e por isso não renova o `cachedAt`. Num documento que já não existe, o `update` falha: o filme saiu da Estante e a nota não é recriada.

Esta decisão emenda a 013 e não substitui nenhuma.

## Consequências
- O `isValidMovie` das regras ganha as duas chaves na lista fixa, com tipo e formato fechados. Os testes no emulador cobrem os limites (0, 11, fracionário, string, formato e ano fora do intervalo, campo sem o `watchedAt`).
- **Dia inexistente passa nas regras.** Uma data como `2026-02-30` é aceita pelas regras e recusada pelo domínio. Se ela chegar ao servidor por outro cliente, o model do app a lê como "sem data", sem derrubar o filme. **Emenda (sessão 028):** o dia no futuro é recusado só na escolha (`ChooseWatchedOn`, pelo relógio do aparelho); o model aceita o futuro já gravado, porque outro aparelho com o fuso à frente pode ter gravado o "hoje" dele.
- A limpeza mensal (decisão 017) renova a cópia com `update` dos três campos da cópia e preserva a nota e a data. Um teste no emulador confirma. O filme que sumiu do TMDB é apagado com a nota junto, o que a política 2.0 precisa dizer.
- A exclusão da conta (decisão 015) já apaga o documento inteiro, sem mudança.
- **A corrida no desmarcar (013) fica maior:** um aparelho com dado velho que tira a única marca apaga também a nota e a data dadas no outro aparelho no mesmo intervalo de sincronização. Ela continua aceita, pelo mesmo motivo: a transação falha offline.
- A política de privacidade 2.0 declara a nota e o dia em que o filme foi assistido entre os dados guardados no Firestore, com a mesma região, o mesmo prazo e a mesma exclusão das marcas. O marcador `A REVISAR` da Fase 3 continua só para as listas.
- Um comentário em texto fica fora. Se entrar depois, vem com decisão própria, tamanho máximo no domínio e nas regras, e revisão da política.

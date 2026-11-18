# 013 — Documento do filme do usuário no Firestore

**Data**: 2026-11-17 · **Status**: aceita

## Contexto
A decisão 010 pôs as marcas do usuário em `users/{uid}/movies/{movieId}`, com o mínimo do filme, e deixou para a sessão do modelo de dados duas escolhas: se o documento guarda cópia do título e do `poster_path`, e quais datas ele tem. As regras da sessão 017 aceitam um formato provisório, com três bools (`watched`, `watchlist`, `favorite`).

O que pesou na sessão 021:
- **Termos do TMDB (§1.C):** é proibido guardar em cache, por mais de 6 meses, qualquer informação obtida do TMDB. Os termos não proíbem guardar texto nem o caminho da imagem. O Firestore nunca guarda a imagem (decisão 010).
- **Estante sem cópia:** as abas da Estante (Assistidos, Quero assistir, Favoritos) teriam de fazer um `GET /movie/{id}` por filme exibido. São muitas chamadas, e o risco de 429 aumenta.
- **Ordem nas abas:** cada aba precisa ordenar por "quando marquei". No Firestore, `where` em um campo e `orderBy` em outro exigem índice composto, que é mais configuração para manter.
- **Dado mínimo (LGPD):** um documento sem nenhuma marca não serve para nada e mantém uma cópia do TMDB sem motivo.
- **Testes da camada `data`:** o `fake_cloud_firestore` seria uma dependência nova. O auth já resolveu o mesmo problema com um gateway fino sobre o SDK (sessão 019).
- **`cloud_firestore` no pub.dev:** a 7.2.0 saiu em 2026-11-16, com menos de duas semanas. A 7.1.0 é de 2026-10-23 e pede `firebase_core` ^5.1.0, compatível com o ^5.2.0 do app.

## Opções consideradas
Sobre a cópia do TMDB:
1. **Copiar `title` e `posterPath`, com `cachedAt`.** A grade da Estante sai do Firestore, e uma cópia vencida é renovada com o TMDB.
2. **Só o id.** Não guarda nada do TMDB, mas faz uma chamada por filme a cada vez que a Estante abre.

Sobre as marcas:
1. **Só timestamps** (`watchedAt`, `watchlistAt`, `favoriteAt`). O campo presente quer dizer marcado, e o valor é a hora do servidor em que a marca entrou.
2. **Bools mais um `updatedAt`.** É o formato mais simples, mas as abas não conseguem ordenar por quando cada marca entrou.
3. **Bools mais uma data por marca.** É redundante, e as regras teriam de garantir que o bool e a data batem.

Sobre o documento sem marcas:
1. **Apagar o documento.**
2. **Manter o documento com tudo desligado.**

## Decisão
- **Cópia do TMDB:** o documento guarda `title` e `posterPath` (opcional, porque o TMDB pode mandar `null`), com `cachedAt` igual à hora do servidor (`request.time`) sempre que a cópia é escrita. Uma cópia com mais de 6 meses desde o `cachedAt` está vencida: a Estante a renova com o TMDB ao abrir e não exibe a cópia vencida como se estivesse atual. O tamanho máximo do `title` e o formato do `posterPath` ficam nas regras e no domínio.
- **Marcas como timestamps:** `watchedAt`, `watchlistAt` e `favoriteAt`. Cada campo pode estar ausente (desmarcado) ou ter um valor igual ao que já estava salvo, ou igual a `request.time` quando a marca entra. O cliente nunca escolhe a data.
- **Sem marcas, sem documento:** desmarcar a última marca apaga o documento. As regras recusam escrever um documento sem nenhuma marca. Na Fase 3, a nota pessoal passa a ser mais um motivo para o documento existir, e esta regra é revista junto. **Emenda (sessão 028):** a regra continua; a nota (`rating`) e o dia em que assistiu (`watchedOn`, escolhido pelo usuário, a única data que não é do servidor) só existem com o `watchedAt`; ver a [decisão 018](018-nota-e-data-em-que-assistiu.md).
- **Feature `lib/features/shelf`**, com o mesmo nome da aba Estante (`/estante`).
- **`cloud_firestore` 7.1.0.** A 7.2.0 pode entrar depois de duas semanas de publicação.
- **A camada `data` fica atrás de um gateway fino** sobre o `cloud_firestore`, como no auth, e os testes usam fakes do gateway. O `fake_cloud_firestore` não entra. As regras continuam testadas no emulador (decisão 012).

Esta decisão complementa a 010 e não substitui nenhuma.

## Consequências
- As regras provisórias da sessão 017 (três bools) e os testes delas são reescritos para o formato novo.
- Cada aba da Estante consulta com `where('<marca>At', '!=', null)` e `orderBy('<marca>At')` no mesmo campo, o que só precisa do índice simples criado pelo Firestore. Não há `firestore.indexes.json` por enquanto. **Emenda (sessão 023):** a consulta ficou só com o `orderBy` descendente, com limite crescente e teto; ver a [decisão 014](014-consulta-das-abas-da-estante.md).
- Escrita offline: o `serverTimestamp()` fica pendente até a sincronização, e a leitura local vê o campo como `null`. O `snapshots()` público do `cloud_firestore` 7.1.0 não aceita o `ServerTimestampBehavior.estimate`. Por isso o gateway troca o `null` pela hora local, e só quando o snapshot tem `hasPendingWrites`. O filme aparece como "marcado, com data estimada", e nunca como desmarcado.
- A política de privacidade 2.0 declara a cópia do título e do pôster (caminho, sem imagem) no Firestore. O texto do prazo segue o que o app garante: a cópia é renovada quando o filme é marcado ou a Estante abre, e uma cópia vencida não aparece como atual. As regras deixam manter o `cachedAt` sem limite (desmarcar não renova a cópia), e o documento de quem não abre mais a Estante nunca é renovado. Por isso, uma limpeza periódica com o Admin SDK, rodada pela conta do dono do projeto fora do app, remove o `title` e o `posterPath` das cópias com mais de 180 dias. O mecanismo e a frequência são decididos antes de a 2.0 ser publicada (`security-auditor` da 021).
- **Corrida no desmarcar, aceita:** o `removeMark` escolhe entre `delete` e `update` pelo `ShelfMovie` do aparelho, que pode estar velho. Uma transação resolveria, mas a transação do Firestore falha offline, e marcar offline é o caso comum. Se outro aparelho pôs uma marca que este ainda não viu, tirar a "única" marca apaga as duas. No caso contrário, a regra nega o documento sem marcas, e o repositório cai para o `delete`. A perda só acontece com dois aparelhos mexendo no mesmo filme no mesmo intervalo de sincronização.
- **Remarcar renova a data de propósito:** pôr de novo uma marca que já existe regrava o `<marca>At` com a hora do servidor, e o filme sobe na aba. A renovação da cópia vencida, na sessão da Estante, ganha um `renewCopy` próprio, que regrava só `title`, `posterPath` e `cachedAt`, sem mexer nas marcas.
- **Versões fixadas pelo lock:** a `cloud_firestore` é 7.1.0 exata no `pubspec.yaml`, e as transitivas (`cloud_firestore_platform_interface` 8.1.0 e `cloud_firestore_web` 5.8.0) ficam presas só pelo `pubspec.lock`, que o CI respeita (`--enforce-lockfile`). Um `flutter pub upgrade` local as sobe, e por isso a regra das duas semanas é conferida no diff do lock antes de cada commit que o mude.
- A exclusão da conta já cobre o documento (subcoleção `movies` na lista fixa da decisão 010).
- Se a licença do TMDB acabar (§1.D), as cópias precisam ser apagadas. Os campos `title`, `posterPath` e `cachedAt` são removidos de todos os documentos pelo console ou pelo Admin SDK, com a conta do dono do projeto, sem depender do app.

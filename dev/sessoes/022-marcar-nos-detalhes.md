# Sessão 022 — Fase 2: Marcar nos detalhes, login opcional e logout completo

**Data**: 2026-11-17 · **Branch**: `feature/022-marcar-nos-detalhes` · **Status**: aberta

## Objetivo
Pôr nos Detalhes as marcas **Assistido**, **Quero assistir** e **Favorito**, ligadas ao `ShelfRepository`, com a marca aparecendo na hora pelo `watchMovie` e erro com "tentar de novo". Marcar sem conta abre o login numa folha nos próprios Detalhes e aplica a marca depois. Na mesma entrega, o logout completo da decisão 010 (portão do `security-auditor` da 021), porque o "Marcar" liga o cache do Firestore no aparelho.

## Checklist
### Preparação
- [x] Conferir no Context7 o `terminate()`/`clearPersistence()` do `cloud_firestore` 7.1.0 e se o `FirebaseFirestore.instance` volta a funcionar depois do `terminate`. **Feito:** ver "Notas"
- [x] UX do login opcional. **Decidido com o usuário:** folha (bottom sheet) nos Detalhes com "Entrar com Google"; a marca pedida é aplicada depois do login
- [x] Marcas offline no logout. **Decidido com o usuário:** antes do `terminate`, esperar o `waitForPendingWrites()` por até 5 s; se estourar, perguntar "Há marcas ainda não sincronizadas. Sair mesmo assim?"
- [x] Consultar a `ui-ux-pro-max` (stack Flutter) para os botões de marca nos Detalhes. **Feito:** seção "Marcas" no override `detalhes.md`; a stack Flutter não tem nada de bottom sheet (fallback declarado)

### Fake (RED/GREEN/REFACTOR)
- [x] Fake do `ShelfRepository` em `test/helpers/`, no formato que os testes do estado pedirem. **Feito:** um stream por `watchMovie` e cada escrita pendente até o teste completá-la, como o Firestore offline

### Estado das marcas (RED/GREEN/REFACTOR)
- [x] Carregando até o primeiro evento do `watchMovie`; depois, as marcas do filme
- [x] Erro do stream com "tentar de novo", que reassina
- [x] Marcar e desmarcar otimistas, sem esperar o future
- [x] Falha da escrita volta ao que o stream diz e mostra o erro
- [x] Sem conta: pede login, e a marca pendente é aplicada ao logar. **Mudou:** o notifier não pede login; a fileira abre a folha e chama `queueMark` se a pessoa entrou. Uma marca que a conta já tinha não é desligada
- [x] Reassina quando a conta muda; cancela no logout e no dispose. **Também:** erro no stream da conta vira deslogado (o erro aparece no login)

### UI (RED/GREEN/REFACTOR, widget tests)
- [x] Widget das marcas nos Detalhes com os 4 estados (skeleton), `Semantics`, alvo ≥ 48dp, strings no ARB
- [x] Folha de login com o botão do Google, fechando e aplicando a marca no sucesso; cancelar não marca nada. **Atenção:** escrevi a folha além do que os testes da fileira pediam; os testes próprios dela passaram de primeira, e cada comportamento foi conferido por mutação (5 de 5 pegos)

### Logout completo (RED/GREEN/REFACTOR)
- [x] Gateway de limpeza do Firestore (`terminate`, `clearPersistence`) atrás de um contrato. **Feito:** `AccountCacheGateway` e `FirestoreAccountCache`, que recebe as chamadas do SDK prontas e tem a ordem testada
- [x] Ordem: cancelar os streams da Estante; `terminate()`; `clearPersistence()`; `signOut()` do Firebase e do Google; recriar a instância. **Feito:** `closeStreams()` entrou no contrato do `ShelfRepository`; recriar a instância acontece sozinho no Android (ver "Notas")
- [x] A falha ao limpar o cache não deixa a sessão aberta, e a falha sobe, só com o `plugin` e o `code`

### Marcas sem sincronizar no logout (RED/GREEN/REFACTOR)
- [x] `syncPendingChanges()` no contrato da conta: espera o `waitForPendingWrites()` por até 5 s (`fake_async`); prazo ou erro dão falso
- [x] `SessionNotifier`: `SessionSigningOut` enquanto espera, `SessionUnsyncedSignOut` quando sobra marca, `confirmSignOut` e `cancelSignOut`; depois de uma falha, tenta de novo sem esperar
- [x] Perfil: "Saindo" no botão e o aviso com "Ficar na conta" e "Sair mesmo assim" (override `perfil.md`)

### Composição
- [x] `main.dart`: `ShelfRepository` montado com o `currentUid` do Firebase Auth, e fallback sem Firebase (`UnavailableShelfRepository`, tudo `SignInRequiredFailure`). **Também:** `MovieCopy.canCopy`, e as marcas somem sem título

### Achados aceitos do `/revisar` (todos, com o usuário)
- [x] (1, bloqueante) "Sair mesmo assim" emite `SessionSigningOut`; "Ficar na conta" não faz nada durante a saída. **Feito:** `confirmSignOut` emite `SessionSigningOut`; `_runSignOut()` sem guard (achado 14 junto)
- [x] (2) Recusa do servidor depois da confirmação local aparece com "tentar de novo" (id por escrita). **Feito:** id por escrita (`_latestWrite`) no lugar do valor otimista
- [x] (3) Falha de escrita não apaga o erro de leitura nem cai na conta nova. **Feito:** só emite pronto com a tela pronta, e a geração da assinatura descarta falhas da conta anterior
- [x] (4) Fim do stream das marcas volta a carregar e para de aceitar toques; `FirestoreShelfRepository` recusa escritas e leituras depois do `closeStreams()` até a conta mudar. **Mudou:** o notifier volta a carregar no `onDone` e ignora toques; a guarda no repositório **não entrou**: ele não sabe quando a mesma conta entra de novo, e recusar o `uid` depois do `closeStreams()` travaria quem sai e entra com a mesma conta. Sem um sinal da conta, a guarda fica só no notifier, que é por onde a UI escreve
- [x] (5) Limpar o cache do Firestore no boot quando o primeiro estado da conta é deslogado. **Feito:** `clearStaleAccountCache` (só o `clearPersistence`, com o primeiro estado deslogado), montado no `main.dart`
- [x] (6) Evento da conta durante a espera do sync não é sobrescrito pela pergunta. **Feito:** depois da espera, segue só se o estado ainda for "saindo"; se a conta caiu por fora, limpa o aparelho mesmo assim
- [x] (7) Política 2.0 no `PLANO.md`: logout sem apagamento seguro, marcas offline apagadas com aviso, cache que fica se a limpeza falhar. **Feito:** no item da política 2.0
- [x] (8) Testes do `_OpenWatch` que falham se o código quebrar (watch sem `listen`, `onDone` da origem). **Feito:** `openStreamCount` (`@visibleForTesting`), stream sem ouvinte, cancelado, encerrado pelo Firestore e pausado
- [x] (9) Esperar o servidor de novo logo antes do `clear()`. **Feito:** duas conferências seguidas; a segunda pega as marcas feitas durante a primeira espera
- [x] (10) `_OpenWatch` registrado no `onListen` e sem esperar o `close()`. **Feito**
- [x] (11) `mounted` depois da folha de login e guard de `_disposed` no notifier. **Feito**
- [x] (12) Override `detalhes.md`: por que desmarcar logo depois de marcar é ignorado. **Feito:** e a recusa depois da confirmação local
- [x] (13) Doc comments do `composeShelfRepository` e do `composeAuthRepository`. **Feito**
- [x] (14) `_runSignOut()` sem guard no lugar do liga-desliga do `_signingOut`. **Feito:** junto com o 1
- [x] (15) Tamanhos do `SignOutButton` em `AppSizes`. **Feito:** `AppSizes.buttonProgress` e `buttonProgressStroke`

### Entrega
- [x] Tríade: format, analyze limpo, `flutter test` verde (e `npm test` das regras se mudarem). **Feito:** format sem mudança (202 arquivos), analyze limpo, 1167 testes verdes; as regras não mudaram
- [ ] Emulador: marcar, desmarcar, offline, login pela folha, logout
- [x] `PLANO.md` e `docs/PRIVACIDADE.md` se o texto mudar. **Feito:** só o item da política 2.0 no `PLANO.md`; o `docs/PRIVACIDADE.md` muda quando a 2.0 for escrita
- [x] `/revisar` (`code-reviewer` e `security-auditor`: auth, storage, rede). **Feito:** os achados estão em "Achados aceitos do `/revisar`"
- [ ] `/fechar-sessao`

## Decisões

## Commits
- `f4ac302` docs: abre a sessão 022
- `dc3bc84` add: ShelfMarksNotifier com marcas otimistas, reassinatura por conta e marca pedida no login
- `8b86910` add: marcas nos Detalhes em chips e folha de login do Google para quem está sem conta
- `71a4f71` add: MovieCopy.canCopy diz se o filme pode ir para a Estante
- `0aefec7` add: marcas nos Detalhes com a Estante montada no main.dart e a indisponível sem Firebase
- `cb5b66d` add: FirestoreShelfRepository.closeStreams encerra os streams abertos antes do logout
- `6413a43` add: FirestoreAccountCache fecha os streams, termina e limpa o cache, nessa ordem
- `c979526` add: logout limpa o cache do Firestore antes de sair, e syncPendingChanges espera 5 s as escritas
- `4a7aa00` add: Perfil pergunta antes de sair quando sobram marcas sem sincronizar (inclui o fluxo do `SessionNotifier`)
- `b7464e1` docs: progresso da sessão 022 e estados do logout no override do Perfil
- `08b3ab4` fix: logout confirmado mostra saindo, ignora o cancelar e não ressuscita a conta que caiu na espera
- `142aa1c` fix: marcas mostram a recusa depois da confirmação local, param no fim do stream e ignoram escritas antigas
- `1b2d543` fix: closeStreams conta só streams ouvidos e não trava com quem ouve pausado
- `9afa61f` fix: limpa no início do app o cache de uma conta que já saiu

## Notas
- **`terminate()` e `clearPersistence()` no `cloud_firestore` 7.1.0** (Context7 e código do pacote no pub-cache):
  - depois do `terminate()`, só o `clearPersistence()` pode ser chamado; outro método lança `FirebaseException`;
  - no Android, o `terminate` do plugin chama `firestore.terminate()` e tira a instância nativa do cache (`destroyCachedFirebaseFirestoreInstanceForKey`). A próxima chamada (`getFirestoreFromPigeon`) cria uma instância nativa nova, ainda não iniciada. O `clearPersistence()` roda nela, e as chamadas seguintes também. O objeto Dart `FirebaseFirestore.instance` continua o mesmo (cache do Dart por `app|databaseId`), então **"recriar a instância" acontece sozinho no Android**, e o `ShelfRepository` pode segurar o `FirebaseFirestore.instance`;
  - o `clearPersistence()` falha se a instância estiver rodando, por isso a ordem `terminate` → `clearPersistence` é obrigatória;
  - **as escritas pendentes se perdem:** o `terminate` não as cancela, e o `clearPersistence` apaga as escritas pendentes junto com o cache. Uma marca feita offline e ainda não sincronizada some no logout;
  - **o `clearPersistence` não apaga de forma segura** ("does not attempt to securely overwrite"). A política 2.0 não pode dizer que o cache é apagado de forma irrecuperável, só que é removido do app.
- **Política 2.0, do que esta sessão mudou:** sair da conta remove do app o cache do Firestore, mas o `clearPersistence` não sobrescreve os arquivos (não dizer "apagado de forma irrecuperável"); as marcas feitas offline que não chegaram ao servidor são apagadas no logout, e o app avisa antes.
- **Janela aceita no logout:** entre o `terminate()` e o `SignedOut` do Firebase, a conta ainda parece aberta. Um "tentar de novo" das marcas ou um toque numa marca nessa janela abre uma instância nova do Firestore com o mesmo `uid`, e o cache volta a ter dados. Dura o tempo de dois `signOut()`. **Depois do `/revisar`:** o notifier para de aceitar toques quando o stream acaba, e o início do app limpa o cache que sobrar.
- **Testes:** os notifiers dos widget tests nascem dentro do `testWidgets`; assinados no `setUp`, os streams entregam fora da zona do teste, e o `pump` não os vê. O skeleton das marcas pulsa sem parar, então os testes dos Detalhes começam deslogados.
- **`/revisar`:** o `code-reviewer` achou 1 bloqueante, 5 importantes e 6 sugestões; o `security-auditor`, 0 bloqueantes, 2 importantes e 4 sugestões (um sem ação). Consolidados em 15, todos aceitos pelo usuário.

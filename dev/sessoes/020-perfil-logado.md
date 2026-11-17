# Sessão 020 — Fase 2: Perfil logado e deslogado

**Data**: 2026-11-17 · **Branch**: `feature/020-perfil-logado` · **Status**: aberta

## Objetivo
Ligar a aba Perfil ao `SessionNotifier`: deslogado com o botão "Entrar com o Google" (diretrizes de marca do Google), entrando, logado com nome, foto e "Sair", e as falhas de login e de logout com "tentar de novo", seguindo os 4 estados e a `ui-ux-pro-max`. Na mesma entrega, as pendências da 019 que servem ao estado (S14, S15 e S11 do `BACKLOG.md`).

## Checklist
### Preparação
- [x] Consultar a `ui-ux-pro-max` (stack Flutter) para a tela de perfil e gerar o override `design-system/ja-vi-esse-filme/pages/perfil.md`
- [x] Conferir as diretrizes de marca do Google para o botão (logo "G" oficial, cores, texto "Entrar com o Google", margens). **Feito:** tema Dark (`#131314`, borda `#8E918F`, texto `#E3E3E3`), pílula, 12/10/12dp, "G" de 20dp, Google Sans Medium 14/20. Os PNGs prontos trazem o texto em inglês, então o botão é nosso com o `g-logo.png` oficial
- [x] Asset oficial do "G" em PNG (sem `flutter_svg`), declarado no `pubspec.yaml`. **Feito:** `google_g_logo.png` (200×204, original), `GoogleSans-Medium.ttf` (52 KB) e a OFL, com a licença no `LicenseRegistry` e teste

### Pendências da 019 (RED/GREEN/REFACTOR por comportamento)
- [x] `FakeAuthRepository` reemite o estado atual ao assinar (S14)
- [x] `deleteAccount` do fake como `async` (S15)
- [x] `SessionNotifier.signOut` ignora a chamada com login em andamento (S11)
- [x] `SessionNotifier.signOut` ignora a chamada dupla (S11)
- [x] `SessionNotifier.signOut` trata `Exception` não tipada como `UnexpectedFailure` (S11)

### Extras que surgiram
- [x] Foto da conta sai do cache no logout (`AccountPhotoCleaner`, `evictPhoto` injetado no `MainApp`)
- [x] Host da foto validado (`https` e `googleusercontent.com` ou subdomínio)
- [x] `SkeletonPulse` movido para `core/widgets`
- [x] Largura de leitura, divisor e transição entre estados (`AnimatedSwitcher`, instantânea com "reduzir movimento")

### UI (RED/GREEN/REFACTOR por estado)
- [x] Carregando: skeleton do cabeçalho, sem spinner solto
- [x] Deslogado: texto sobre o que a conta oferece e o botão "Entrar com o Google" (≥ 48dp, `Semantics`)
- [x] Entrando: botão desabilitado com indicador e rótulo acessível
- [x] Logado: avatar (`cached_network_image`) com placeholder desenhado sem foto ou com erro, nome com fallback e botão "Sair"
- [x] Falha no login: mensagem do `failureMessage` e "Tentar de novo" chamando o `signIn`
- [x] Falha no logout: mensagem e "Tentar de novo" chamando o `signOut`. **Mudou:** sem nome nem e-mail, porque o `SessionSignOutFailed` não traz o usuário e a sessão pode já ter fechado (`perfil.md` atualizado)
- [x] Entrada "Sobre" presente em todos os estados
- [x] Fonte 2x em 360x640 sem overflow, em cada estado
- [x] Strings novas no ARB (decisão 004)

### Achados aceitos do `/revisar`
- [x] (4) Fake só emite `SignedOut` se a conta não estiver deslogada, como o Firebase
- [x] (1) Bloqueante: "Tentar de novo" depois da falha no logout volta a deslogado
- [x] (2) `signIn` ignorado durante um logout em andamento. Com essa guarda, um login não começa no meio de um logout, e a segunda metade do item deixa de ser necessária. O retorno de "ocupado" no "Sair" foi para o backlog
- [x] (3a) A foto não fica no `imageCache` depois do logout. **Feito:** sem `cacheWidth`, a chave é a da URL, e o logout faz `NetworkImage(url).evict()`
- [x] (3b) Foto da conta sem disco. **Mudou, com o ok do usuário:** o `CacheManager` próprio exigiria o `flutter_cache_manager` como dependência direta. A foto passou a ficar só em memória (`Image.network`), e não sobra nada no disco quando a sessão fecha com o app fechado
- [x] (5) Teste do avatar com erro no download mostra o placeholder
- [x] (S1) Borda do botão do Google desbota quando desabilitado
- [x] (S2) `AppSizes.minTouchTarget` no lugar do `_minHeight`
- [x] (S3) Comentário do `SignedInPanel`. **Feito:** o painel recebe `onSignOut` e desenha o "Sair"; o `_SignOutButton` saiu
- [x] (S4) `signOutGate` completado no `tearDown`
- [x] (S5) `matchesSemantics` com papel de botão no teste do botão do Google
- [x] (S6) Prova por mutação dos testes de guarda do `AccountPhotoCleaner`. **Feito:** sem o `previous != current`, caem "sessão continua aberta" e "erro no stream"; sem a foto do usuário novo, cai "conta troca". O S7 também entrou: só apaga quando a conta sai ou troca
- [x] (6) Portão de release no `PLANO.md`: política 2.0 publicada antes de qualquer APK com login, com a lista do `security-auditor`
- [x] (S8, S9, S10) Backlog/log: host da foto `lh3`–`lh6` exato; reproduzir o voltar no seletor; `uid` no logcat como risco aceito

### Entrega
- [x] Verificação no emulador (Pixel_9_Pro) com conta real: entrar e sair, screenshot, log sem e-mail nem token. **Feito:** logado (foto do Google carregada), sair, deslogado, entrando, cancelar tocando fora (volta a deslogado sem erro), entrar de novo, e fonte 2x do sistema sem overflow. No `flutter run` e no logcat do processo do app: 0 e-mail, 0 JWT, 0 `ya29.`, 0 `idToken`, 0 URL de foto
- [ ] Tríade: format, analyze limpo, testes verdes
- [ ] `/revisar` (`code-reviewer` e `security-auditor`: auth e foto da conta)
- [ ] `/fechar-sessao`

## Decisões
- Com o usuário, na abertura: o botão usa a **Google Sans recortada** (Latin, `wght=500`, 52 KB, OFL sem Reserved Font Name), feita com o `fonttools` fora do app; a foto da conta **sai do cache no logout** nesta sessão; a foto só carrega de **`https` em `googleusercontent.com`**. São assets e regras de UI, sem dependência nova, então não viram arquivo em `dev/decisoes/`.

## Commits
- `ef3b3fb` docs: abre a sessão 020
- `a452108` docs: override de design do Perfil
- `c6264d3` test: FakeAuthRepository reemite o estado atual e falha o deleteAccount pelo future
- `61be28b` add: SessionNotifier ignora o logout durante um login
- `0ec4836` add: SessionNotifier ignora um segundo logout em andamento
- `01d2ba6` add: SessionNotifier mostra a falha do logout com exceção não tipada

## Notas
- Riscos levantados na abertura: a política 2.0 precisa estar publicada antes de uma versão com o botão chegar ao usuário; a foto da conta fica no cache de imagens (dado pessoal, entra na política 2.0, e a limpeza no logout é decidida nesta sessão ou no item do logout); validar ou não o host da foto (`lh3.googleusercontent.com`); o logo do Google tem de ser o arquivo oficial.
- Fora do escopo: "login leva para onde estava" e a limpeza do Firestore no logout (itens próprios do plano).
- No ciclo da S15, o GREEN foi aplicado no mesmo passo em que o teste foi reescrito. O RED foi confirmado depois, voltando a linha por um instante (`UnimplementedError` lançado na chamada).
- Um `signIn` durante um logout em andamento ainda não é barrado. Fica para avaliar no `/revisar`.
- **`Semantics` do botão entrando sem `container`:** o rótulo se fundia ao nó do painel (título e texto juntos), e o leitor de tela leria tudo como um bloco. O teste do Perfil pegou; corrigido com `container: true`.
- **Testes de guarda que passaram de primeira** (acessibilidade do botão, troca de conta e sessão aberta no `AccountPhotoCleaner`, guardas por estado do Perfil): não houve RED. A guarda de fonte 2x foi provada por mutação (sem o `Expanded` do painel logado, o teste falha).
- **Avatar:** os testes de placeholder, host e semântica foram escritos juntos, num RED só.
- **Emulador, voltar no seletor:** um `KEYCODE_BACK` no seletor de contas terminou **logado** (`GetCredentialResponse returned from framework` no log). O comportamento é do Credential Manager, e não do app, que só refletiu o Firebase. Tocar fora do seletor cancela certo. Fica para o `/revisar` avaliar.
- **`uid` no logcat:** 4 linhas `Notifying … listeners about user (<uid>)` vêm do SDK nativo do FirebaseAuth, só com o `uid`, sem dado pessoal na linha. Não são do app.
- **Cache da foto em memória:** o `evictFromCache` tira a entrada do disco e a do `imageCache` com a chave da URL. A cópia redimensionada (`memCacheWidth`) pode ficar na memória até o app fechar.
- **`/revisar`:** o `code-reviewer` achou 1 bloqueante, 4 importantes e 8 sugestões; o `security-auditor` não achou bloqueante e trouxe 3 importantes e 5 sugestões. Os aceitos estão no checklist; os adiados estão no `BACKLOG.md`.
- **Bloqueante do `/revisar` escondido pelo fake:** o fake emitia `SignedOut` a cada logout, e o Firebase não emite de novo com a conta já fora. Com o fake corrigido, o teste do "tentar de novo" ficou RED, e o `SessionNotifier` passou a emitir o deslogado quando o logout dá certo.
- **`uid` no logcat:** risco aceito (`security-auditor`, S4). Vem do SDK nativo, só com o `uid`, e nenhum log do app concatena o `uid` com dado pessoal.
- **Política 1.0 desatualizada:** ela diz "não tem login". Ficou registrado no `PLANO.md` como portão de release, com o conteúdo que a 2.0 precisa ter.
- **Commit com mensagem maior que o conteúdo:** o `761b8a5` cita o plano e o backlog, mas só tem o `perfil.md`; os dois entraram no `4959033`. Não reescrevi o histórico.
- **Emulador de novo, depois do `/revisar`:** o Pixel_9_Pro foi reiniciado (agora `emulator-5554`). O Perfil logado carrega a foto pelo `Image.network`, e o log do `flutter run` tem 0 e-mail, 0 JWT e 0 URL de foto.

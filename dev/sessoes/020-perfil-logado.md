# Sessão 020 — Fase 2: Perfil logado e deslogado

**Data**: 2026-11-17 · **Branch**: `feature/020-perfil-logado` · **Status**: aberta

## Objetivo
Ligar a aba Perfil ao `SessionNotifier`: deslogado com o botão "Entrar com o Google" (diretrizes de marca do Google), entrando, logado com nome, foto e "Sair", e as falhas de login e de logout com "tentar de novo", seguindo os 4 estados e a `ui-ux-pro-max`. Na mesma entrega, as pendências da 019 que servem ao estado (S14, S15 e S11 do `BACKLOG.md`).

## Checklist
### Preparação
- [x] Consultar a `ui-ux-pro-max` (stack Flutter) para a tela de perfil e gerar o override `design-system/ja-vi-esse-filme/pages/perfil.md`
- [x] Conferir as diretrizes de marca do Google para o botão (logo "G" oficial, cores, texto "Entrar com o Google", margens). **Feito:** tema Dark (`#131314`, borda `#8E918F`, texto `#E3E3E3`), pílula, 12/10/12dp, "G" de 20dp, Google Sans Medium 14/20. Os PNGs prontos trazem o texto em inglês, então o botão é nosso com o `g-logo.png` oficial
- [ ] Asset oficial do "G" em PNG (sem `flutter_svg`), declarado no `pubspec.yaml`. Copiados para `assets/` (`google_g_logo.png`, `GoogleSans-Medium.ttf` e `GoogleSans-OFL.txt`); o `pubspec.yaml` e o `LicenseRegistry` entram no ciclo do botão

### Pendências da 019 (RED/GREEN/REFACTOR por comportamento)
- [x] `FakeAuthRepository` reemite o estado atual ao assinar (S14)
- [x] `deleteAccount` do fake como `async` (S15)
- [x] `SessionNotifier.signOut` ignora a chamada com login em andamento (S11)
- [x] `SessionNotifier.signOut` ignora a chamada dupla (S11)
- [x] `SessionNotifier.signOut` trata `Exception` não tipada como `UnexpectedFailure` (S11)

### UI (RED/GREEN/REFACTOR por estado)
- [ ] Carregando: skeleton do cabeçalho, sem spinner solto
- [ ] Deslogado: texto sobre o que a conta oferece e o botão "Entrar com o Google" (≥ 48dp, `Semantics`)
- [ ] Entrando: botão desabilitado com indicador e rótulo acessível
- [ ] Logado: avatar (`cached_network_image`) com placeholder desenhado sem foto ou com erro, nome com fallback e botão "Sair"
- [ ] Falha no login: mensagem do `failureMessage` e "Tentar de novo" chamando o `signIn`
- [ ] Falha no logout: mensagem e "Tentar de novo" chamando o `signOut`
- [ ] Entrada "Sobre" presente em todos os estados
- [ ] Fonte 2x em 360x640 sem overflow, em cada estado
- [ ] Strings novas no ARB (decisão 004)

### Entrega
- [ ] Verificação no emulador (Pixel_9_Pro) com conta real: entrar e sair, screenshot, log sem e-mail nem token
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

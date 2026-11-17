# Sessão 022 — Fase 2: Marcar nos detalhes, login opcional e logout completo

**Data**: 2026-11-17 · **Branch**: `feature/022-marcar-nos-detalhes` · **Status**: aberta

## Objetivo
Pôr nos Detalhes as marcas **Assistido**, **Quero assistir** e **Favorito**, ligadas ao `ShelfRepository`, com a marca aparecendo na hora pelo `watchMovie` e erro com "tentar de novo". Marcar sem conta abre o login numa folha nos próprios Detalhes e aplica a marca depois. Na mesma entrega, o logout completo da decisão 010 (portão do `security-auditor` da 021), porque o "Marcar" liga o cache do Firestore no aparelho.

## Checklist
### Preparação
- [ ] Conferir no Context7 o `terminate()`/`clearPersistence()` do `cloud_firestore` 7.1.0 e se o `FirebaseFirestore.instance` volta a funcionar depois do `terminate`
- [x] UX do login opcional. **Decidido com o usuário:** folha (bottom sheet) nos Detalhes com "Entrar com Google"; a marca pedida é aplicada depois do login
- [ ] Consultar a `ui-ux-pro-max` (stack Flutter) para os botões de marca nos Detalhes

### Fake (RED/GREEN/REFACTOR)
- [ ] Fake do `ShelfRepository` em `test/helpers/`, no formato que os testes do estado pedirem

### Estado das marcas (RED/GREEN/REFACTOR)
- [ ] Carregando até o primeiro evento do `watchMovie`; depois, as marcas do filme
- [ ] Erro do stream com "tentar de novo", que reassina
- [ ] Marcar e desmarcar otimistas, sem esperar o future
- [ ] Falha da escrita volta ao que o stream diz e mostra o erro
- [ ] Sem conta (`SignInRequiredFailure` ou deslogado): pede login, e a marca pendente é aplicada ao logar
- [ ] Reassina quando a conta muda; cancela no logout e no dispose

### UI (RED/GREEN/REFACTOR, widget tests)
- [ ] Widget das marcas nos Detalhes com os 4 estados (skeleton), `Semantics`, alvo ≥ 48dp, strings no ARB
- [ ] Folha de login com o botão do Google, fechando e aplicando a marca no sucesso; cancelar não marca nada

### Logout completo (RED/GREEN/REFACTOR)
- [ ] Gateway de limpeza do Firestore (`terminate`, `clearPersistence`) atrás de um contrato
- [ ] Ordem: cancelar os streams da Estante; `terminate()`; `clearPersistence()`; `signOut()` do Firebase e do Google; recriar a instância
- [ ] A falha ao limpar o cache não deixa a sessão aberta, e a falha sobe

### Composição
- [ ] `main.dart`: `ShelfRepository` montado com o `currentUid` do Firebase Auth, e fallback sem Firebase

### Entrega
- [ ] Tríade: format, analyze limpo, `flutter test` verde (e `npm test` das regras se mudarem)
- [ ] Emulador: marcar, desmarcar, offline, login pela folha, logout
- [ ] `PLANO.md` e `docs/PRIVACIDADE.md` se o texto mudar
- [ ] `/revisar` (`code-reviewer` e `security-auditor`: auth, storage, rede)
- [ ] `/fechar-sessao`

## Decisões

## Commits

## Notas

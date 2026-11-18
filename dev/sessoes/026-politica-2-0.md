# Sessão 026 — Fase 2: política de privacidade 2.0

**Data**: 2026-11-18 · **Branch**: `feature/026-politica-2-0` (empilhada na `feature/025-excluir-conta-web`) · **Status**: aberta

## Objetivo
Escrever a versão 2.0 do `docs/PRIVACIDADE.md`, que cobre a conta Google (Firebase Auth), as marcas no Firestore, a exclusão da conta e tudo o que o item da política 2.0 do `PLANO.md` acumulou das sessões 020 a 025, e publicá-la no repositório de suporte (decisão 006). Esse é o portão de release: nenhum APK com login sai do ambiente de desenvolvimento antes da 2.0 publicada.

## Checklist
### Preparação
- [ ] Ler o item da 2.0 no `PLANO.md`, os blocos "A REVISAR" e "FASE 2 (fora da publicada)" do `docs/PRIVACIDADE.md` e as decisões 010, 013, 015 e 016; montar a lista de afirmações a cobrir
- [ ] Conferir na documentação oficial: região e operadores do Firebase Auth e do Firestore (transferência internacional), retenção (180 dias, IPs do login), requisitos de idade da conta Google, termos do Firebase sobre o papel de operador
- [ ] (S7 da 025) O usuário confere no console do Firebase se o Firestore tem backup agendado, PITR ou export; o resultado entra na seção de retenção
- [ ] Decidir com o usuário: bases legais por finalidade (contrato, inciso V; legítimo interesse; exercício regular de direitos, art. 7º, VI para a guarda do pedido de exclusão), a base da renovação automática das cópias do TMDB na Estante (sessão 023) e a data de vigência

### Conteúdo (sem TDD: texto, conferido contra o código)
- [ ] Seções 2, 3 (nova 3.2 "Conta e marcas"), 4, 6, 7, 8, 9 e 11 conforme o item do `PLANO.md`
- [ ] Afirmações sobre o comportamento do app conferidas no código (logout e `clearPersistence`, `clearStaleAccountCache`, foto só em memória, `data_extraction_rules.xml`, renovação das cópias, exclusão) e citadas no log
- [ ] Página de exclusão (`docs/EXCLUSAO-DA-CONTA.md`) e política sem divergência; GitHub Pages e cdnjs no site de suporte
- [ ] Versão 2.0, vigência com data, sem "A REVISAR" sobre a Fase 2 (os da Fase 3 e 4 ficam como comentários)

### No app (só se o texto do Sobre mudar; RED/GREEN/REFACTOR)
- [ ] Resumo da privacidade no Sobre (ARB) coerente com a 2.0, com widget test

### Publicação (ação pública, só com o ok do usuário)
- [ ] Cópia limpa no repositório de suporte (`index.md`), `gitleaks`, commit noreply, push e conferência da URL
- [ ] README do suporte atualizado se precisar

### Entrega
- [ ] `PLANO.md` (item da 2.0 marcado; portão de release)
- [ ] Tríade (format, analyze, `flutter test`) e `gitleaks`
- [ ] `/revisar` (publica conteúdo sobre auth e storage)
- [ ] `/fechar-sessao`: PR com base na `feature/025-excluir-conta-web`; merge só depois do CI destravar e da 025 integrada

## Decisões

## Commits

## Notas
- **Empilhada:** o CI da conta está travado por cobrança (sessão 025, decisão 016). Quando destravar, a 025 entra primeiro na `main` e o PR desta é reapontado para a `main`.
